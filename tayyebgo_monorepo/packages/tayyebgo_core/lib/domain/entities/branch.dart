import '../value_objects/address.dart';
import '../value_objects/geo_location.dart';
import '../value_objects/geohash.dart';
import '../value_objects/operating_hours.dart';

class Branch {
  final String id;
  final String brandId;
  final String name;
  final String slug;
  final Address address;
  final GeoLocation location;
  final String geohash;
  final String phone;
  final String? imageUrl;
  final bool isActive;
  final List<OperatingHours> operatingHours;
  final String timezone;
  final DateTime createdAt;

  const Branch({
    required this.id,
    required this.brandId,
    required this.name,
    required this.slug,
    required this.address,
    required this.location,
    required this.geohash,
    this.phone = '',
    this.imageUrl,
    this.isActive = true,
    this.operatingHours = const [],
    this.timezone = 'UTC',
    required this.createdAt,
  });

  bool get isOpen {
    final now = DateTime.now();
    return operatingHours.any((h) => h.matchesDay(now) && h.isOpenNow);
  }

  Branch copyWith({
    String? name,
    String? slug,
    Address? address,
    GeoLocation? location,
    String? phone,
    String? imageUrl,
    bool? isActive,
    List<OperatingHours>? operatingHours,
    String? timezone,
  }) =>
      Branch(
        id: id,
        brandId: brandId,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        address: address ?? this.address,
        location: location ?? this.location,
        geohash: location != null
            ? Geohash.encode(location.latitude, location.longitude)
            : geohash,
        phone: phone ?? this.phone,
        imageUrl: imageUrl ?? this.imageUrl,
        isActive: isActive ?? this.isActive,
        operatingHours: operatingHours ?? this.operatingHours,
        timezone: timezone ?? this.timezone,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'brandId': brandId,
        'name': name,
        'slug': slug,
        ...address.toMap(),
        ...location.toMap(),
        'geohash': geohash,
        'phone': phone,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'operatingHours':
            operatingHours.map((h) => h.toMap()).toList(),
        'timezone': timezone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Branch.fromMap(Map<String, dynamic> m, String docId) {
    final lat = (m['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (m['longitude'] as num?)?.toDouble() ?? 0.0;
    final loc = GeoLocation(lat, lon);
    return Branch(
      id: docId,
      brandId: m['brandId'] as String? ?? '',
      name: m['name'] as String? ?? '',
      slug: m['slug'] as String? ?? '',
      address: Address.fromMap(m),
      location: loc,
      geohash: m['geohash'] as String? ??
          Geohash.encode(lat, lon),
      phone: m['phone'] as String? ?? '',
      imageUrl: m['imageUrl'] as String?,
      isActive: m['isActive'] as bool? ?? true,
      operatingHours: (m['operatingHours'] as List<dynamic>?)
              ?.map((e) =>
                  OperatingHours.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      timezone: m['timezone'] as String? ?? 'UTC',
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}