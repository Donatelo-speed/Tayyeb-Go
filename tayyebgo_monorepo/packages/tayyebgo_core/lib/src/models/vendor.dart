import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryMode {
  storeOnly('store_only', 'Store Only'),
  platformOnly('platform_only', 'Platform Only'),
  hybrid('hybrid', 'Hybrid');

  final String value;
  final String displayName;
  const DeliveryMode(this.value, this.displayName);

  static DeliveryMode fromString(String? v) => switch (v) {
        'store_only' => DeliveryMode.storeOnly,
        'platform_only' => DeliveryMode.platformOnly,
        'hybrid' => DeliveryMode.hybrid,
        _ => DeliveryMode.platformOnly,
      };

  bool get usesStoreDrivers => this == DeliveryMode.storeOnly || this == DeliveryMode.hybrid;
  bool get usesPlatformDrivers => this == DeliveryMode.platformOnly || this == DeliveryMode.hybrid;
}

class DayHours {
  final String open;
  final String close;
  final bool isClosed;

  const DayHours({
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  factory DayHours.fromMap(Map<String, dynamic> m) => DayHours(
        open: m['open'] as String? ?? '00:00',
        close: m['close'] as String? ?? '00:00',
        isClosed: m['isClosed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'open': open,
        'close': close,
        'isClosed': isClosed,
      };

  bool isOpenAt(DateTime now) {
    if (isClosed) return false;
    final openParts = open.split(':');
    final closeParts = close.split(':');
    final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;
    if (closeMinutes < openMinutes) {
      return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
    }
    return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
  }

  @override
  String toString() => isClosed ? 'Closed' : '$open – $close';
}

class Vendor {
  final String id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final String? phone;
  final String? email;
  final String? address;
  final String? imageUrl;
  final String? coverUrl;
  final String cuisineType;
  final List<String> cuisineTags;
  final double rating;
  final int reviewCount;
  final double deliveryFee;
  final double minOrder;
  final int estimatedDeliveryTime;
  final bool isActive;
  final bool acceptsOnlinePayment;
  final bool acceptsCash;
  final GeoPoint? location;
  final Map<String, DayHours> operatingHours;
  final String? ownerId;
  final double commissionRate;
  final DeliveryMode deliveryMode;
  final bool allowPlatformFallback;
  final int fallbackDelaySeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Vendor({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.phone,
    this.email,
    this.address,
    this.imageUrl,
    this.coverUrl,
    this.cuisineType = '',
    this.cuisineTags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.deliveryFee = 0.0,
    this.minOrder = 0.0,
    this.estimatedDeliveryTime = 30,
    this.isActive = true,
    this.acceptsOnlinePayment = false,
    this.acceptsCash = true,
    this.location,
    this.operatingHours = const {},
    this.ownerId,
    this.commissionRate = 0.15,
    this.deliveryMode = DeliveryMode.platformOnly,
    this.allowPlatformFallback = true,
    this.fallbackDelaySeconds = 30,
    this.createdAt,
    this.updatedAt,
  });

  static const List<String> _dayKeys = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  bool get isOpen {
    if (!isActive) return false;
    if (operatingHours.isEmpty) return true;
    final now = DateTime.now();
    final dayKey = _dayKeys[now.weekday - 1];
    final hours = operatingHours[dayKey];
    if (hours == null) return false;
    return hours.isOpenAt(now);
  }

  String? get hoursHint {
    final now = DateTime.now();
    final dayKey = _dayKeys[now.weekday - 1];
    final hours = operatingHours[dayKey];
    if (hours == null || hours.isClosed) return 'Closed today';
    if (isOpen) return 'Closes at ${hours.close}';
    return 'Opens at ${hours.open}';
  }

  bool get hasLocation => location != null;

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    final rawHours = d['operatingHours'] as Map<String, dynamic>?;
    final Map<String, DayHours> hours = {};
    if (rawHours != null) {
      for (final entry in rawHours.entries) {
        final val = entry.value;
        if (val is Map<String, dynamic>) {
          hours[entry.key] = DayHours.fromMap(val);
        }
      }
    }

    return Vendor(
      id: doc.id,
      name: d['name'] as String? ?? '',
      nameAr: d['nameAr'] as String?,
      description: d['description'] as String?,
      descriptionAr: d['descriptionAr'] as String?,
      phone: d['phone'] as String?,
      email: d['email'] as String?,
      address: d['address'] as String?,
      imageUrl: d['imageUrl'] as String?,
      coverUrl: d['coverUrl'] as String?,
      cuisineType: d['cuisineType'] as String? ?? '',
      cuisineTags: (d['cuisineTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      minOrder: (d['minOrder'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryTime: (d['estimatedDeliveryTime'] as num?)?.toInt() ?? 30,
      isActive: d['isActive'] as bool? ?? true,
      acceptsOnlinePayment: d['acceptsOnlinePayment'] as bool? ?? false,
      acceptsCash: d['acceptsCash'] as bool? ?? true,
      location: d['location'] as GeoPoint?,
      operatingHours: hours,
      ownerId: d['ownerId'] as String?,
      commissionRate: (d['commissionRate'] as num?)?.toDouble() ?? 0.15,
      deliveryMode: DeliveryMode.fromString(d['deliveryMode'] as String?),
      allowPlatformFallback: d['allowPlatformFallback'] as bool? ?? true,
      fallbackDelaySeconds: (d['fallbackDelaySeconds'] as num?)?.toInt() ?? 30,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
        if (description != null) 'description': description,
        if (descriptionAr != null) 'descriptionAr': descriptionAr,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'cuisineType': cuisineType,
        'cuisineTags': cuisineTags,
        'rating': rating,
        'reviewCount': reviewCount,
        'deliveryFee': deliveryFee,
        'minOrder': minOrder,
        'estimatedDeliveryTime': estimatedDeliveryTime,
        'isActive': isActive,
        'acceptsOnlinePayment': acceptsOnlinePayment,
        'acceptsCash': acceptsCash,
        if (location != null) 'location': location,
        'operatingHours': operatingHours.map((k, v) => MapEntry(k, v.toMap())),
        if (ownerId != null) 'ownerId': ownerId,
        'commissionRate': commissionRate,
        'deliveryMode': deliveryMode.value,
        'allowPlatformFallback': allowPlatformFallback,
        'fallbackDelaySeconds': fallbackDelaySeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Vendor copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? phone,
    String? email,
    String? address,
    String? imageUrl,
    String? coverUrl,
    String? cuisineType,
    List<String>? cuisineTags,
    double? rating,
    int? reviewCount,
    double? deliveryFee,
    double? minOrder,
    int? estimatedDeliveryTime,
    bool? isActive,
    bool? acceptsOnlinePayment,
    bool? acceptsCash,
    GeoPoint? location,
    Map<String, DayHours>? operatingHours,
    String? ownerId,
    double? commissionRate,
    DeliveryMode? deliveryMode,
    bool? allowPlatformFallback,
    int? fallbackDelaySeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Vendor(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        description: description ?? this.description,
        descriptionAr: descriptionAr ?? this.descriptionAr,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        imageUrl: imageUrl ?? this.imageUrl,
        coverUrl: coverUrl ?? this.coverUrl,
        cuisineType: cuisineType ?? this.cuisineType,
        cuisineTags: cuisineTags ?? this.cuisineTags,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        minOrder: minOrder ?? this.minOrder,
        estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
        isActive: isActive ?? this.isActive,
        acceptsOnlinePayment: acceptsOnlinePayment ?? this.acceptsOnlinePayment,
        acceptsCash: acceptsCash ?? this.acceptsCash,
        location: location ?? this.location,
        operatingHours: operatingHours ?? this.operatingHours,
        ownerId: ownerId ?? this.ownerId,
        commissionRate: commissionRate ?? this.commissionRate,
        deliveryMode: deliveryMode ?? this.deliveryMode,
        allowPlatformFallback: allowPlatformFallback ?? this.allowPlatformFallback,
        fallbackDelaySeconds: fallbackDelaySeconds ?? this.fallbackDelaySeconds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
