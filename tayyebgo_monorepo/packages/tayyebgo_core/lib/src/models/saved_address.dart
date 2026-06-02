import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label;
  final String fullAddress;
  final String? city;
  final String? street;
  final String? building;
  final String? floor;
  final String? apartment;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.city,
    this.street,
    this.building,
    this.floor,
    this.apartment,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory SavedAddress.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SavedAddress(
      id: doc.id,
      label: d['label'] as String? ?? 'Address',
      fullAddress: d['fullAddress'] as String? ?? '',
      city: d['city'] as String?,
      street: d['street'] as String?,
      building: d['building'] as String?,
      floor: d['floor'] as String?,
      apartment: d['apartment'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      isDefault: d['isDefault'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'label': label,
        'fullAddress': fullAddress,
        if (city != null) 'city': city,
        if (street != null) 'street': street,
        if (building != null) 'building': building,
        if (floor != null) 'floor': floor,
        if (apartment != null) 'apartment': apartment,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

  SavedAddress copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? city,
    String? street,
    String? building,
    String? floor,
    String? apartment,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) =>
      SavedAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        fullAddress: fullAddress ?? this.fullAddress,
        city: city ?? this.city,
        street: street ?? this.street,
        building: building ?? this.building,
        floor: floor ?? this.floor,
        apartment: apartment ?? this.apartment,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toOrderAddressMap() => {
        'fullAddress': fullAddress,
        if (city != null) 'city': city,
        if (street != null) 'street': street,
        if (building != null) 'building': building,
        if (floor != null) 'floor': floor,
        if (apartment != null) 'apartment': apartment,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
