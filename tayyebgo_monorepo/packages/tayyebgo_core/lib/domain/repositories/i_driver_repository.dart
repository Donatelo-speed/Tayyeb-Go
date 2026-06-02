import '../entities/driver.dart';

abstract class IDriverRepository {
  Stream<List<Driver>> watchAll();
  Stream<List<Driver>> watchOnline();
  Stream<List<Driver>> watchOnlineByStore(String storeId);
  Stream<List<Driver>> watchOnlinePlatformDrivers();
  Future<void> updateLocation(String driverId, double lat, double lng);
  Future<void> setOnlineStatus(String driverId, bool online);
}
