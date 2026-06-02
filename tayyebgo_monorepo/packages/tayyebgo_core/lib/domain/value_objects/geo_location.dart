import 'dart:math' as math;

class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation(this.latitude, this.longitude);

  double distanceTo(GeoLocation other) {
    const r = 6371e3;
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLon = (other.longitude - longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  Map<String, dynamic> toMap() => {'latitude': latitude, 'longitude': longitude};

  factory GeoLocation.fromMap(Map<String, dynamic> m) => GeoLocation(
        (m['latitude'] as num).toDouble(),
        (m['longitude'] as num).toDouble(),
      );
}
