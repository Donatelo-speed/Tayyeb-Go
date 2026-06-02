import 'geo_location.dart';

class Address {
  final String street;
  final String district;
  final String city;
  final String? additionalInfo;
  final GeoLocation? location;

  const Address({
    required this.street,
    required this.district,
    required this.city,
    this.additionalInfo,
    this.location,
  });

  String get fullAddress => '$street, $district, $city';

  Map<String, dynamic> toMap() => {
        'street': street,
        'district': district,
        'city': city,
        'additionalInfo': additionalInfo,
        if (location != null) ...location!.toMap(),
      };

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        street: m['street'] as String? ?? '',
        district: m['district'] as String? ?? '',
        city: m['city'] as String? ?? '',
        additionalInfo: m['additionalInfo'] as String?,
        location: m['latitude'] != null
            ? GeoLocation.fromMap(m)
            : null,
      );
}
