import 'package:cloud_firestore/cloud_firestore.dart';

class CityZone {
  final String id;
  final String name;
  final String country;
  final String city;
  final bool isActive;
  final double? centerLat;
  final double? centerLng;
  final double? radiusKm;
  final int activeDrivers;
  final int activeStores;
  final double avgDeliveryFee;
  final int avgETAMinutes;
  final DateTime createdAt;

  const CityZone({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    this.isActive = true,
    this.centerLat,
    this.centerLng,
    this.radiusKm,
    this.activeDrivers = 0,
    this.activeStores = 0,
    this.avgDeliveryFee = 0,
    this.avgETAMinutes = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'country': country,
        'city': city,
        'isActive': isActive,
        if (centerLat != null) 'centerLat': centerLat,
        if (centerLng != null) 'centerLng': centerLng,
        if (radiusKm != null) 'radiusKm': radiusKm,
        'activeDrivers': activeDrivers,
        'activeStores': activeStores,
        'avgDeliveryFee': avgDeliveryFee,
        'avgETAMinutes': avgETAMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CityZone.fromMap(Map<String, dynamic> m, String docId) => CityZone(
        id: docId,
        name: m['name'] as String? ?? '',
        country: m['country'] as String? ?? 'Syria',
        city: m['city'] as String? ?? '',
        isActive: m['isActive'] as bool? ?? true,
        centerLat: (m['centerLat'] as num?)?.toDouble(),
        centerLng: (m['centerLng'] as num?)?.toDouble(),
        radiusKm: (m['radiusKm'] as num?)?.toDouble(),
        activeDrivers: (m['activeDrivers'] as num?)?.toInt() ?? 0,
        activeStores: (m['activeStores'] as num?)?.toInt() ?? 0,
        avgDeliveryFee: (m['avgDeliveryFee'] as num?)?.toDouble() ?? 0,
        avgETAMinutes: (m['avgETAMinutes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class CityExpansionService {
  static final CityExpansionService instance = CityExpansionService._();
  CityExpansionService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CityZone>> getZonesForCity(String city) async {
    final snap = await _db
        .collection('zones')
        .where('city', isEqualTo: city)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => CityZone.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<CityZone>> getAllActiveZones() async {
    final snap = await _db
        .collection('zones')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => CityZone.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> createZone({
    required String name,
    required String country,
    required String city,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    double deliveryFee = 5000,
  }) async {
    await _db.collection('zones').add({
      'name': name,
      'country': country,
      'city': city,
      'isActive': true,
      if (centerLat != null) 'centerLat': centerLat,
      if (centerLng != null) 'centerLng': centerLng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      'deliveryFee': deliveryFee,
      'activeDrivers': 0,
      'activeStores': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateZoneStats(String zoneId) async {
    final zoneDoc = await _db.collection('zones').doc(zoneId).get();
    if (!zoneDoc.exists) return;

    final driversSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('isOnline', isEqualTo: true)
        .get();
    final activeDrivers = driversSnap.docs.length;

    final storesSnap = await _db
        .collection('restaurants')
        .where('isActive', isEqualTo: true)
        .get();
    final activeStores = storesSnap.docs.length;

    await _db.collection('zones').doc(zoneId).update({
      'activeDrivers': activeDrivers,
      'activeStores': activeStores,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getExpansionReadiness(String city) async {
    final zones = await getZonesForCity(city);
    final totalDrivers =
        zones.fold<int>(0, (sum, z) => sum + z.activeDrivers);
    final totalStores =
        zones.fold<int>(0, (sum, z) => sum + z.activeStores);

    return {
      'city': city,
      'zones': zones.length,
      'totalDrivers': totalDrivers,
      'totalStores': totalStores,
      'isReady': totalDrivers >= 5 && totalStores >= 3,
      'recommendations': _getRecommendations(totalDrivers, totalStores),
    };
  }

  List<String> _getRecommendations(int drivers, int stores) {
    final recs = <String>[];
    if (drivers < 5) recs.add('Need at least 5 active drivers (have $drivers)');
    if (stores < 3) recs.add('Need at least 3 active stores (have $stores)');
    if (drivers > 0 && stores > 0 && drivers < stores * 2) {
      recs.add('Driver-to-store ratio is low — recruit more drivers');
    }
    if (recs.isEmpty) recs.add('City is ready for expansion');
    return recs;
  }
}
