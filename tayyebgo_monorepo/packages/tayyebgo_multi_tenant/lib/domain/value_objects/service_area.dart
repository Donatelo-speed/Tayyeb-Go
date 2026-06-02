class ServiceArea {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const ServiceArea({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  Map<String, dynamic> toMap() => {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
      };

  factory ServiceArea.fromMap(Map<String, dynamic> map) => ServiceArea(
        minLat: (map['minLat'] as num?)?.toDouble() ?? 0,
        maxLat: (map['maxLat'] as num?)?.toDouble() ?? 0,
        minLng: (map['minLng'] as num?)?.toDouble() ?? 0,
        maxLng: (map['maxLng'] as num?)?.toDouble() ?? 0,
      );
}
