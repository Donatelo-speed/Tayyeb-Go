import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverData {
  final String driverId;
  final String name;
  final double rating;
  final bool isOnline;
  final int todayDeliveries;
  final double todayEarnings;
  final String onlineTime;
  final List<DeliveryOrder> activeDeliveries;

  DriverData({
    required this.driverId,
    required this.name,
    required this.rating,
    required this.isOnline,
    required this.todayDeliveries,
    required this.todayEarnings,
    required this.onlineTime,
    required this.activeDeliveries,
  });
}

class DeliveryOrder {
  final String orderId;
  final String address;
  final String customer;
  final double amount;
  final double distance;
  final String status;
  final double? destLat;
  final double? destLng;

  DeliveryOrder({
    required this.orderId,
    required this.address,
    required this.customer,
    required this.amount,
    required this.distance,
    required this.status,
    this.destLat,
    this.destLng,
  });
}

class DriverProvider extends ChangeNotifier {
  DriverData? _data;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _profileSubscription;
  String? _currentDriverId;

  DriverData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  void loadDriverData(String driverId) {
    _currentDriverId = driverId;
    _isLoading = true;
    notifyListeners();

    _profileSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        _data = _getMockData();
        _isLoading = false;
        notifyListeners();
        return;
      }
      final d = doc.data()!;
      _data = DriverData(
        driverId: driverId,
        name: d['name'] as String? ?? 'Driver',
        rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
        isOnline: d['isOnline'] as bool? ?? false,
        todayDeliveries: d['todayDeliveries'] as int? ?? 0,
        todayEarnings: (d['todayEarnings'] as num?)?.toDouble() ?? 0.0,
        onlineTime: d['onlineTime'] as String? ?? '0h',
        activeDeliveries: _data?.activeDeliveries ?? [],
      );
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _data = _getMockData();
      _isLoading = false;
      notifyListeners();
    });

    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['picked_up', 'ready_for_driver', 'en_route'])
        .snapshots()
        .listen((snapshot) {
      final deliveries = snapshot.docs.map((doc) {
        final d = doc.data();
        final addr = d['deliveryAddress'] as Map<String, dynamic>? ?? {};
        return DeliveryOrder(
          orderId: doc.id,
          address: '${addr['street'] ?? ''}, ${addr['city'] ?? ''}',
          customer: d['customerName'] as String? ?? 'Guest',
          amount: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
          distance: _calcDistance(
            d['driverLat'] as double?,
            d['driverLng'] as double?,
            addr['latitude'] as double?,
            addr['longitude'] as double?,
          ),
          status: d['status'] as String? ?? 'pending',
          destLat: addr['latitude'] as double?,
          destLng: addr['longitude'] as double?,
        );
      }).toList();

      if (_data != null) {
        _data = DriverData(
          driverId: _data!.driverId,
          name: _data!.name,
          rating: _data!.rating,
          isOnline: _data!.isOnline,
          todayDeliveries: _data!.todayDeliveries,
          todayEarnings: _data!.todayEarnings,
          onlineTime: _data!.onlineTime,
          activeDeliveries: deliveries,
        );
        notifyListeners();
      }
    }, onError: (_) {});
  }

  Future<void> toggleAvailability(String driverId, bool isOnline) async {
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({'isOnline': isOnline});
      if (_data != null) {
        _data = DriverData(
          driverId: _data!.driverId,
          name: _data!.name,
          rating: _data!.rating,
          isOnline: isOnline,
          todayDeliveries: _data!.todayDeliveries,
          todayEarnings: _data!.todayEarnings,
          onlineTime: _data!.onlineTime,
          activeDeliveries: _data!.activeDeliveries,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to toggle: $e');
    }
  }

  Future<void> claimDeliveryJob(String orderId) async {
    if (_currentDriverId == null) return;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'driverId': _currentDriverId,
        'driverName': _data?.name ?? 'Driver',
        'status': 'picked_up',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to claim job: $e');
    }
  }

  Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_currentDriverId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentDriverId)
          .update({
        'lastLatitude': latitude,
        'lastLongitude': longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      for (final delivery in _data?.activeDeliveries ?? []) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(delivery.orderId)
            .update({
          'driverLat': latitude,
          'driverLng': longitude,
        });
      }
    } catch (e) {
      debugPrint('Location update failed: $e');
    }
  }

  double _calcDistance(double? lat1, double? lng1, double? lat2, double? lng2) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return 0.0;
    }
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin(dLng / 2) * _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) => x < 0 ? 0 : x > 1 ? 1 : x * x * x * x * x;
  double _atan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5707963267948966 : -1.5707963267948966;
    final result = y / x;
    return result - (result * result * result) / 3;
  }

  Future<void> completeDelivery(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Complete delivery failed: $e');
    }
  }

  DriverData _getMockData() {
    return DriverData(
      driverId: 'DRV-1234',
      name: 'Ahmed Hassan',
      rating: 4.9,
      isOnline: true,
      todayDeliveries: 12,
      todayEarnings: 85.0,
      onlineTime: '4.5h',
      activeDeliveries: [
        DeliveryOrder(orderId: 'ord-4521', address: 'Al-Mansour, Street 12', customer: 'Mohammad', amount: 8.50, distance: 2.3, status: 'picked_up'),
        DeliveryOrder(orderId: 'ord-4522', address: 'Al-Mazza, Building 5', customer: 'Sara', amount: 12.00, distance: 1.8, status: 'en_route'),
      ],
    );
  }
}
