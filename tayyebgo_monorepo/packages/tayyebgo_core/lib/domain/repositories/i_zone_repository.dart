import '../entities/zone.dart';

abstract class IZoneRepository {
  Stream<List<ZoneModel>> watchActiveZones();
  Future<List<ZoneModel>> getActiveZones();
  Future<List<ZoneModel>> getAllZones();
  Future<ZoneModel?> getZone(String zoneId);
  Future<ZoneModel?> getZoneForLocation(double lat, double lng);
  Future<void> createZone(ZoneModel zone);
  Future<void> updateZone(String zoneId, Map<String, dynamic> updates);
  Future<void> deleteZone(String zoneId);
  Future<void> toggleActive(String zoneId, bool isActive);
}
