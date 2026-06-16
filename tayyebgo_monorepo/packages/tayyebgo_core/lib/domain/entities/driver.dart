import '../enums/driver_type.dart';
import '../value_objects/geo_location.dart';

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicle;
  final DriverType driverType;
  final String? storeId;
  final bool isOnline;
  final bool isActive;
  final GeoLocation? currentLocation;
  final double rating;
  final int activeDeliveries;
  final int completedDeliveries;
  final bool isSubscribed;
  final DateTime createdAt;

  const Driver({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.vehicle = '',
    this.driverType = DriverType.platform,
    this.storeId,
    this.isOnline = false,
    this.isActive = true,
    this.currentLocation,
    this.rating = 5.0,
    this.activeDeliveries = 0,
    this.completedDeliveries = 0,
    this.isSubscribed = false,
    required this.createdAt,
  });

  bool get isStoreDriver => driverType == DriverType.store;
  bool get isPlatformDriver => driverType == DriverType.platform;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'vehicle': vehicle,
        'driverType': driverType.value,
        if (storeId != null) 'storeId': storeId,
        'isOnline': isOnline,
        'isActive': isActive,
        if (currentLocation != null) ...currentLocation!.toMap(),
        'rating': rating,
        'activeDeliveries': activeDeliveries,
        'completedDeliveries': completedDeliveries,
        'isSubscribed': isSubscribed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Driver.fromMap(Map<String, dynamic> m, String docId) => Driver(
        id: docId,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        vehicle: m['vehicle'] as String? ?? '',
        driverType: DriverType.fromString(m['driverType'] as String?),
        storeId: m['storeId'] as String?,
        isOnline: m['isOnline'] == true,
        isActive: m['isActive'] as bool? ?? true,
        currentLocation: m['latitude'] != null
            ? GeoLocation.fromMap(m)
            : null,
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        activeDeliveries: (m['activeDeliveries'] as num?)?.toInt() ?? 0,
        completedDeliveries: (m['completedDeliveries'] as num?)?.toInt() ?? 0,
        isSubscribed: m['isSubscribed'] == true,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}