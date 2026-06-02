import 'dart:math' as math;

class Geohash {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double lat, double lon, {int precision = 6}) {
    final latRange = [-90.0, 90.0];
    final lonRange = [-180.0, 180.0];
    final bits = StringBuffer();
    for (var i = 0; i < precision * 5; i++) {
      if (i.isEven) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (lon >= mid) {
          bits.write('1');
          lonRange[0] = mid;
        } else {
          bits.write('0');
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (lat >= mid) {
          bits.write('1');
          latRange[0] = mid;
        } else {
          bits.write('0');
          latRange[1] = mid;
        }
      }
    }
    final hash = StringBuffer();
    for (var i = 0; i < bits.length; i += 5) {
      final chunk = bits.toString().substring(i, math.min(i + 5, bits.length));
      hash.write(_base32[int.parse(chunk, radix: 2)]);
    }
    return hash.toString();
  }

  static const _precisionRadii = <int, double>{
    1: 5003.0,
    2: 1251.0,
    3: 156.0,
    4: 39.1,
    5: 4.89,
    6: 1.22,
    7: 0.153,
    8: 0.0382,
    9: 0.00478,
    10: 0.00119,
    12: 0.000149,
  };

  static double radiusInKm(int precision) =>
      _precisionRadii[precision] ?? 1.22;

  static int precisionForRadius(double radiusKm) =>
      _precisionRadii.entries
          .firstWhere((e) => e.value <= radiusKm * 1.5,
              orElse: () => const MapEntry(5, 4.89))
          .key;

  static String encodeFromLocation(double lat, double lon,
          {int precision = 6}) =>
      encode(lat, lon, precision: precision);
}