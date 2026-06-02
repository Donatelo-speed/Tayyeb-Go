import '../enums/vertical_type.dart';
import '../value_objects/service_area.dart';

class Tenant {
  final String id;
  final String name;
  final VerticalType verticalType;
  final bool isActive;
  final double commissionPercent;
  final ServiceArea? serviceArea;
  final String? ownerId;
  final String? logoUrl;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.name,
    required this.verticalType,
    this.isActive = true,
    this.commissionPercent = 15.0,
    this.serviceArea,
    this.ownerId,
    this.logoUrl,
    this.contactEmail,
    this.contactPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  Tenant copyWith({
    String? id,
    String? name,
    VerticalType? verticalType,
    bool? isActive,
    double? commissionPercent,
    ServiceArea? serviceArea,
    String? ownerId,
    String? logoUrl,
    String? contactEmail,
    String? contactPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      verticalType: verticalType ?? this.verticalType,
      isActive: isActive ?? this.isActive,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      serviceArea: serviceArea ?? this.serviceArea,
      ownerId: ownerId ?? this.ownerId,
      logoUrl: logoUrl ?? this.logoUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'verticalType': verticalType.value,
        'isActive': isActive,
        'commissionPercent': commissionPercent,
        if (serviceArea != null) 'serviceArea': serviceArea!.toMap(),
        'ownerId': ownerId,
        'logoUrl': logoUrl,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Tenant.fromMap(String id, Map<String, dynamic> map) => Tenant(
        id: id,
        name: map['name'] as String? ?? '',
        verticalType: VerticalType.fromValue(map['verticalType'] as String? ?? ''),
        isActive: map['isActive'] as bool? ?? true,
        commissionPercent: (map['commissionPercent'] as num?)?.toDouble() ?? 15.0,
        serviceArea: map['serviceArea'] != null
            ? ServiceArea.fromMap(map['serviceArea'] as Map<String, dynamic>)
            : null,
        ownerId: map['ownerId'] as String?,
        logoUrl: map['logoUrl'] as String?,
        contactEmail: map['contactEmail'] as String?,
        contactPhone: map['contactPhone'] as String?,
        createdAt: _parseDate(map['createdAt']),
        updatedAt: _parseDate(map['updatedAt']),
      );

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
