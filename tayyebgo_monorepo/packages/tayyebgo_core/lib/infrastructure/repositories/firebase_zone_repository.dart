import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/i_zone_repository.dart';

class FirebaseZoneRepository implements IZoneRepository {
  static final FirebaseZoneRepository instance = FirebaseZoneRepository._();
  FirebaseZoneRepository._();

  final _col = FirebaseFirestore.instance.collection('zones');

  @override
  Stream<List<ZoneModel>> watchActiveZones() {
    return _col.where('isActive', isEqualTo: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => ZoneModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  @override
  Future<List<ZoneModel>> getActiveZones() async {
    final snap = await _col.where('isActive', isEqualTo: true).get();
    return snap.docs.map((d) => ZoneModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<List<ZoneModel>> getAllZones() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map((d) => ZoneModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<ZoneModel?> getZone(String zoneId) async {
    final doc = await _col.doc(zoneId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ZoneModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<ZoneModel?> getZoneForLocation(double lat, double lng) async {
    final snap = await _col.where('isActive', isEqualTo: true).get();
    for (final doc in snap.docs) {
      final zone = ZoneModel.fromMap(doc.data(), doc.id);
      if (_isPointInZone(lat, lng, zone)) return zone;
    }
    return null;
  }

  bool _isPointInZone(double lat, double lng, ZoneModel zone) {
    // Simple circle check
    if (zone.centerLat != null && zone.centerLng != null && zone.radiusKm != null) {
      final distance = _haversineKm(lat, lng, zone.centerLat!, zone.centerLng!);
      return distance <= zone.radiusKm!;
    }
    // Polygon check
    if (zone.boundary != null && zone.boundary!.isNotEmpty) {
      return _pointInPolygon(lat, lng, zone.boundary!);
    }
    // Fallback: zone is active and has no boundary = covers all
    return true;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool _pointInPolygon(double lat, double lng, List<List<double>> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i][0], xi = polygon[i][1];
      final yj = polygon[j][0], xj = polygon[j][1];
      if (((yi > lat) != (yj > lat)) && (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  @override
  Future<void> createZone(ZoneModel zone) async {
    await _col.add(zone.toMap()..remove('id'));
  }

  @override
  Future<void> updateZone(String zoneId, Map<String, dynamic> updates) async {
    await _col.doc(zoneId).update(updates);
  }

  @override
  Future<void> deleteZone(String zoneId) async {
    await _col.doc(zoneId).delete();
  }

  @override
  Future<void> toggleActive(String zoneId, bool isActive) async {
    await _col.doc(zoneId).update({'isActive': isActive});
  }
}
