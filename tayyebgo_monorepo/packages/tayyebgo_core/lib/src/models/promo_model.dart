import 'package:cloud_firestore/cloud_firestore.dart';

enum PromoType {
  percentage,
  flat;

  static PromoType fromString(String? v) => switch (v) {
        'flat' => PromoType.flat,
        _ => PromoType.percentage,
      };

  String get firestoreValue => name;

  String get displayName => switch (this) {
        PromoType.percentage => 'Percentage Off',
        PromoType.flat => 'Flat Amount Off',
      };
}

class PromoModel {
  final String id;
  final String code;
  final String? description;
  final String? descriptionAr;
  final PromoType type;
  final double value;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final String? restaurantId;
  final List<String> applicableProductIds;
  final bool isActive;
  final int usageLimit;
  final int usageCount;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PromoModel({
    required this.id,
    required this.code,
    this.description,
    this.descriptionAr,
    this.type = PromoType.percentage,
    required this.value,
    this.minOrderAmount = 0.0,
    this.maxDiscountAmount = 0.0,
    this.restaurantId,
    this.applicableProductIds = const [],
    this.isActive = true,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get hasReachedUsageLimit {
    if (usageLimit == 0) return false;
    return usageCount >= usageLimit;
  }

  bool get isUsable => isActive && !isExpired && !hasReachedUsageLimit;

  int get remainingUses {
    if (usageLimit == 0) return -1;
    return (usageLimit - usageCount).clamp(0, usageLimit);
  }

  double computeDiscount(double subtotal) {
    if (!isUsable) return 0.0;
    if (subtotal < minOrderAmount) return 0.0;
    final double raw = switch (type) {
      PromoType.percentage => subtotal * (value / 100),
      PromoType.flat => value,
    };
    final double capped = (maxDiscountAmount > 0 && raw > maxDiscountAmount)
        ? maxDiscountAmount
        : raw;
    return capped.clamp(0.0, subtotal);
  }

  String get badgeLabel => switch (type) {
        PromoType.percentage => '${value.toStringAsFixed(0)}% OFF',
        PromoType.flat =>
          '\$${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)} OFF',
      };

  String? validate(double subtotal) {
    if (!isActive) return 'This promo code is no longer active.';
    if (isExpired) return 'This promo code has expired.';
    if (hasReachedUsageLimit) {
      return 'This promo code has reached its usage limit.';
    }
    if (subtotal < minOrderAmount) {
      return 'Minimum order of \$${minOrderAmount.toStringAsFixed(0)} '
          'required to use this code.';
    }
    return null;
  }

  factory PromoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PromoModel(
      id: doc.id,
      code: (d['code'] as String? ?? '').toUpperCase(),
      description: d['description'] as String?,
      descriptionAr: d['descriptionAr'] as String?,
      type: PromoType.fromString(d['type'] as String?),
      value: (d['value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (d['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (d['maxDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      restaurantId: d['restaurantId'] as String?,
      applicableProductIds: (d['applicableProductIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: d['isActive'] as bool? ?? true,
      usageLimit: (d['usageLimit'] as num?)?.toInt() ?? 0,
      usageCount: (d['usageCount'] as num?)?.toInt() ?? 0,
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'code': code.toUpperCase(),
        if (description != null) 'description': description,
        if (descriptionAr != null) 'descriptionAr': descriptionAr,
        'type': type.firestoreValue,
        'value': value,
        'minOrderAmount': minOrderAmount,
        'maxDiscountAmount': maxDiscountAmount,
        if (restaurantId != null) 'restaurantId': restaurantId,
        'applicableProductIds': applicableProductIds,
        'isActive': isActive,
        'usageLimit': usageLimit,
        'usageCount': usageCount,
        if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  PromoModel copyWith({
    String? id,
    String? code,
    String? description,
    String? descriptionAr,
    PromoType? type,
    double? value,
    double? minOrderAmount,
    double? maxDiscountAmount,
    String? restaurantId,
    List<String>? applicableProductIds,
    bool? isActive,
    int? usageLimit,
    int? usageCount,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PromoModel(
        id: id ?? this.id,
        code: code ?? this.code,
        description: description ?? this.description,
        descriptionAr: descriptionAr ?? this.descriptionAr,
        type: type ?? this.type,
        value: value ?? this.value,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
        restaurantId: restaurantId ?? this.restaurantId,
        applicableProductIds: applicableProductIds ?? this.applicableProductIds,
        isActive: isActive ?? this.isActive,
        usageLimit: usageLimit ?? this.usageLimit,
        usageCount: usageCount ?? this.usageCount,
        expiryDate: expiryDate ?? this.expiryDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
