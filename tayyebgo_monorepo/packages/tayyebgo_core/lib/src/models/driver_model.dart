import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/driver_type.dart';

enum VehicleType {
  bicycle,
  motorcycle,
  car,
  van;

  static VehicleType fromString(String? v) => switch (v) {
        'bicycle' => VehicleType.bicycle,
        'motorcycle' => VehicleType.motorcycle,
        'car' => VehicleType.car,
        'van' => VehicleType.van,
        _ => VehicleType.motorcycle,
      };

  String get firestoreValue => name;

  String get displayName => switch (this) {
        VehicleType.bicycle => 'Bicycle',
        VehicleType.motorcycle => 'Motorcycle',
        VehicleType.car => 'Car',
        VehicleType.van => 'Van',
      };
}

class DriverModel {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final DriverType driverType;
  final String? storeId;
  final VehicleType vehicleType;
  final String? vehiclePlate;
  final bool isOnline;
  final bool isActive;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final String? currentOrderId;
  final int totalDeliveries;
  final double rating;
  final int ratingCount;
  final double pendingPayout;
  final double totalEarnings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverModel({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    this.driverType = DriverType.platform,
    this.storeId,
    this.vehicleType = VehicleType.motorcycle,
    this.vehiclePlate,
    this.isOnline = false,
    this.isActive = true,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.currentOrderId,
    this.totalDeliveries = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.pendingPayout = 0.0,
    this.totalEarnings = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasActiveOrder => currentOrderId != null;
  bool get hasLocation => currentLatitude != null && currentLongitude != null;

  bool get isLocationFresh {
    if (lastLocationUpdate == null) return false;
    return DateTime.now().difference(lastLocationUpdate!).inMinutes < 2;
  }

  String get displayRating =>
      ratingCount == 0 ? 'No ratings yet' : rating.toStringAsFixed(1);

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return DriverModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String?,
      photoUrl: d['photoUrl'] as String?,
      driverType: DriverType.fromString(d['driverType'] as String?),
      storeId: d['storeId'] as String?,
      vehicleType: VehicleType.fromString(d['vehicleType'] as String?),
      vehiclePlate: d['vehiclePlate'] as String?,
      isOnline: d['isOnline'] as bool? ?? false,
      isActive: d['isActive'] as bool? ?? true,
      currentLatitude: (d['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (d['currentLongitude'] as num?)?.toDouble(),
      lastLocationUpdate: (d['lastLocationUpdate'] as Timestamp?)?.toDate(),
      currentOrderId: d['currentOrderId'] as String?,
      totalDeliveries: (d['totalDeliveries'] as num?)?.toInt() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      pendingPayout: (d['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (d['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory DriverModel.fromLocationDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final gp = d['location'] as GeoPoint?;
    return DriverModel(
      id: doc.id,
      name: d['driverName'] as String? ?? '',
      driverType: DriverType.fromString(d['driverType'] as String?),
      storeId: d['storeId'] as String?,
      currentLatitude: gp?.latitude,
      currentLongitude: gp?.longitude,
      lastLocationUpdate: (d['updatedAt'] as Timestamp?)?.toDate(),
      isOnline: d['isOnline'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'driverType': driverType.value,
        if (storeId != null) 'storeId': storeId,
        'vehicleType': vehicleType.firestoreValue,
        if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
        'isOnline': isOnline,
        'isActive': isActive,
        if (currentLatitude != null) 'currentLatitude': currentLatitude,
        if (currentLongitude != null) 'currentLongitude': currentLongitude,
        if (lastLocationUpdate != null)
          'lastLocationUpdate': Timestamp.fromDate(lastLocationUpdate!),
        if (currentOrderId != null) 'currentOrderId': currentOrderId,
        'totalDeliveries': totalDeliveries,
        'rating': rating,
        'ratingCount': ratingCount,
        'pendingPayout': pendingPayout,
        'totalEarnings': totalEarnings,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    DriverType? driverType,
    String? storeId,
    VehicleType? vehicleType,
    String? vehiclePlate,
    bool? isOnline,
    bool? isActive,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    String? currentOrderId,
    int? totalDeliveries,
    double? rating,
    int? ratingCount,
    double? pendingPayout,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DriverModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        driverType: driverType ?? this.driverType,
        storeId: storeId ?? this.storeId,
        vehicleType: vehicleType ?? this.vehicleType,
        vehiclePlate: vehiclePlate ?? this.vehiclePlate,
        isOnline: isOnline ?? this.isOnline,
        isActive: isActive ?? this.isActive,
        currentLatitude: currentLatitude ?? this.currentLatitude,
        currentLongitude: currentLongitude ?? this.currentLongitude,
        lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
        currentOrderId: currentOrderId ?? this.currentOrderId,
        totalDeliveries: totalDeliveries ?? this.totalDeliveries,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        pendingPayout: pendingPayout ?? this.pendingPayout,
        totalEarnings: totalEarnings ?? this.totalEarnings,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
