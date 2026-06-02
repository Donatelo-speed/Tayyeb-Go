import '../value_objects/geo_location.dart';
import '../value_objects/money.dart';

class DispatchZone {
  final String id;
  final String branchId;
  final String name;
  final double centerLat;
  final double centerLon;
  final double radiusKm;
  final Money? minimumOrder;
  final Money? deliveryFee;
  final int estimatedMinutes;
  final bool isActive;

  const DispatchZone({
    required this.id,
    required this.branchId,
    required this.name,
    required this.centerLat,
    required this.centerLon,
    this.radiusKm = 5.0,
    this.minimumOrder,
    this.deliveryFee,
    this.estimatedMinutes = 30,
    this.isActive = true,
  });

  bool contains(GeoLocation point) {
    final zone = GeoLocation(centerLat, centerLon);
    return zone.distanceTo(point) <= radiusKm * 1000;
  }

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'name': name,
        'centerLat': centerLat,
        'centerLon': centerLon,
        'radiusKm': radiusKm,
        if (minimumOrder != null) 'minimumOrder': minimumOrder!.amountInCents,
        if (deliveryFee != null) 'deliveryFee': deliveryFee!.amountInCents,
        'estimatedMinutes': estimatedMinutes,
        'isActive': isActive,
      };

  factory DispatchZone.fromMap(Map<String, dynamic> m, String docId) =>
      DispatchZone(
        id: docId,
        branchId: m['branchId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        centerLat: (m['centerLat'] as num?)?.toDouble() ?? 0.0,
        centerLon: (m['centerLon'] as num?)?.toDouble() ?? 0.0,
        radiusKm: (m['radiusKm'] as num?)?.toDouble() ?? 5.0,
        minimumOrder: m['minimumOrder'] != null
            ? Money((m['minimumOrder'] as num).toInt())
            : null,
        deliveryFee: m['deliveryFee'] != null
            ? Money((m['deliveryFee'] as num).toInt())
            : null,
        estimatedMinutes:
            (m['estimatedMinutes'] as num?)?.toInt() ?? 30,
        isActive: m['isActive'] as bool? ?? true,
      );
}