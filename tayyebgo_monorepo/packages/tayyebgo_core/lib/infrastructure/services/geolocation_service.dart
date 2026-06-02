import '../../domain/value_objects/geo_location.dart';

class GeolocationService {
  static double calculateEtaInMinutes(
      GeoLocation origin, GeoLocation destination, double speedMps) {
    final distanceMeters = origin.distanceTo(destination);
    final seconds = distanceMeters / speedMps;
    return seconds / 60;
  }

  static double calculateDistanceKm(
          GeoLocation a, GeoLocation b) =>
      a.distanceTo(b) / 1000;
}
