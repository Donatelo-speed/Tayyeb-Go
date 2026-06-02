import '../value_objects/address.dart';
import '../value_objects/geo_location.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisineType;
  final bool isActive;
  final String ownerId;
  final String phone;
  final Address address;
  final GeoLocation location;
  final String? imageUrl;
  final double commissionPercent;
  final DateTime createdAt;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisineType,
    this.isActive = true,
    required this.ownerId,
    this.phone = '',
    required this.address,
    required this.location,
    this.imageUrl,
    this.commissionPercent = 15.0,
    required this.createdAt,
  });

  Restaurant copyWith({
    String? name,
    String? cuisineType,
    bool? isActive,
    String? ownerId,
    String? phone,
    Address? address,
    GeoLocation? location,
    String? imageUrl,
    double? commissionPercent,
  }) =>
      Restaurant(
        id: id,
        name: name ?? this.name,
        cuisineType: cuisineType ?? this.cuisineType,
        isActive: isActive ?? this.isActive,
        ownerId: ownerId ?? this.ownerId,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        location: location ?? this.location,
        imageUrl: imageUrl ?? this.imageUrl,
        commissionPercent: commissionPercent ?? this.commissionPercent,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'cuisineType': cuisineType,
        'isActive': isActive,
        'ownerId': ownerId,
        'phone': phone,
        ...address.toMap(),
        ...location.toMap(),
        'imageUrl': imageUrl,
        'commissionPercent': commissionPercent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Restaurant.fromMap(Map<String, dynamic> m, String docId) =>
      Restaurant(
        id: docId,
        name: m['name'] as String? ?? '',
        cuisineType: m['cuisineType'] as String? ?? '',
        isActive: m['isActive'] as bool? ?? true,
        ownerId: m['ownerId'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        address: Address.fromMap(m),
        location: GeoLocation(
          (m['latitude'] as num?)?.toDouble() ?? 0.0,
          (m['longitude'] as num?)?.toDouble() ?? 0.0,
        ),
        imageUrl: m['imageUrl'] as String?,
        commissionPercent: (m['commissionPercent'] as num?)?.toDouble() ?? 15.0,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
