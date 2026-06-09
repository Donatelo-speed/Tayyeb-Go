import 'package:cloud_firestore/cloud_firestore.dart';

class SmartAddress {
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
  final String? landmark;
  final String? buildingPhotoUrl;
  final String? voiceNoteUrl;
  final String? voiceDirections;
  final bool isDefault;
  final DateTime? createdAt;

  const SmartAddress({
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
    this.landmark,
    this.buildingPhotoUrl,
    this.voiceNoteUrl,
    this.voiceDirections,
    this.isDefault = false,
    this.createdAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get shortDescription {
    final parts = <String>[label];
    if (landmark != null) parts.add('near ${landmark!}');
    if (building != null) parts.add(building!);
    return parts.join(', ');
  }

  factory SmartAddress.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SmartAddress._fromMap(doc.id, d);
  }

  factory SmartAddress.fromMap(String id, Map<String, dynamic> d) =>
      SmartAddress._fromMap(id, d);

  factory SmartAddress._fromMap(String id, Map<String, dynamic> d) {
    return SmartAddress(
      id: id,
      label: d['label'] as String? ?? 'Address',
      fullAddress: d['fullAddress'] as String? ?? '',
      city: d['city'] as String?,
      street: d['street'] as String?,
      building: d['building'] as String?,
      floor: d['floor'] as String?,
      apartment: d['apartment'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      landmark: d['landmark'] as String?,
      buildingPhotoUrl: d['buildingPhotoUrl'] as String?,
      voiceNoteUrl: d['voiceNoteUrl'] as String?,
      voiceDirections: d['voiceDirections'] as String?,
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
        if (landmark != null) 'landmark': landmark,
        if (buildingPhotoUrl != null) 'buildingPhotoUrl': buildingPhotoUrl,
        if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
        if (voiceDirections != null) 'voiceDirections': voiceDirections,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

  SmartAddress copyWith({
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
    String? landmark,
    String? buildingPhotoUrl,
    String? voiceNoteUrl,
    String? voiceDirections,
    bool? isDefault,
    DateTime? createdAt,
  }) =>
      SmartAddress(
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
        landmark: landmark ?? this.landmark,
        buildingPhotoUrl: buildingPhotoUrl ?? this.buildingPhotoUrl,
        voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
        voiceDirections: voiceDirections ?? this.voiceDirections,
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
        if (landmark != null) 'landmark': landmark,
        if (buildingPhotoUrl != null) 'buildingPhotoUrl': buildingPhotoUrl,
        if (voiceDirections != null) 'voiceDirections': voiceDirections,
      };
}
