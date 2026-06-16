class ZoneModel {
  final String id;
  final String name;
  final String city;
  final String country;
  final double deliveryFee;
  final double? perKmFee;
  final double? minOrderAmount;
  final double? maxDeliveryDistance;
  final int? estimatedDeliveryMinutes;
  final bool isActive;
  final List<List<double>>? boundary; // polygon coordinates [[lat,lng], ...]
  final double? centerLat;
  final double? centerLng;
  final double? radiusKm; // simple circle boundary
  final DateTime createdAt;

  const ZoneModel({
    required this.id,
    required this.name,
    this.city = 'Homs',
    this.country = 'Syria',
    required this.deliveryFee,
    this.perKmFee,
    this.minOrderAmount,
    this.maxDeliveryDistance,
    this.estimatedDeliveryMinutes,
    this.isActive = true,
    this.boundary,
    this.centerLat,
    this.centerLng,
    this.radiusKm,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'country': country,
        'deliveryFee': deliveryFee,
        if (perKmFee != null) 'perKmFee': perKmFee,
        if (minOrderAmount != null) 'minOrderAmount': minOrderAmount,
        if (maxDeliveryDistance != null) 'maxDeliveryDistance': maxDeliveryDistance,
        if (estimatedDeliveryMinutes != null) 'estimatedDeliveryMinutes': estimatedDeliveryMinutes,
        'isActive': isActive,
        if (boundary != null) 'boundary': boundary,
        if (centerLat != null) 'centerLat': centerLat,
        if (centerLng != null) 'centerLng': centerLng,
        if (radiusKm != null) 'radiusKm': radiusKm,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ZoneModel.fromMap(Map<String, dynamic> m, String docId) => ZoneModel(
        id: docId,
        name: m['name'] as String? ?? '',
        city: m['city'] as String? ?? 'Homs',
        country: m['country'] as String? ?? 'Syria',
        deliveryFee: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
        perKmFee: (m['perKmFee'] as num?)?.toDouble(),
        minOrderAmount: (m['minOrderAmount'] as num?)?.toDouble(),
        maxDeliveryDistance: (m['maxDeliveryDistance'] as num?)?.toDouble(),
        estimatedDeliveryMinutes: (m['estimatedDeliveryMinutes'] as num?)?.toInt(),
        isActive: m['isActive'] as bool? ?? true,
        boundary: (m['boundary'] as List<dynamic>?)
            ?.map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
        centerLat: (m['centerLat'] as num?)?.toDouble(),
        centerLng: (m['centerLng'] as num?)?.toDouble(),
        radiusKm: (m['radiusKm'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  ZoneModel copyWith({
    String? name,
    String? city,
    String? country,
    double? deliveryFee,
    double? perKmFee,
    double? minOrderAmount,
    double? maxDeliveryDistance,
    int? estimatedDeliveryMinutes,
    bool? isActive,
    List<List<double>>? boundary,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
  }) =>
      ZoneModel(
        id: id,
        name: name ?? this.name,
        city: city ?? this.city,
        country: country ?? this.country,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        perKmFee: perKmFee ?? this.perKmFee,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        maxDeliveryDistance: maxDeliveryDistance ?? this.maxDeliveryDistance,
        estimatedDeliveryMinutes: estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
        isActive: isActive ?? this.isActive,
        boundary: boundary ?? this.boundary,
        centerLat: centerLat ?? this.centerLat,
        centerLng: centerLng ?? this.centerLng,
        radiusKm: radiusKm ?? this.radiusKm,
        createdAt: createdAt,
      );
}
