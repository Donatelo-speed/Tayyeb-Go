class Brand {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? coverImageUrl;
  final List<String> cuisineTypes;
  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final bool isActive;
  final DateTime createdAt;

  const Brand({
    required this.id,
    required this.name,
    this.description = '',
    this.logoUrl,
    this.coverImageUrl,
    this.cuisineTypes = const [],
    this.website,
    this.contactEmail,
    this.contactPhone,
    this.isActive = true,
    required this.createdAt,
  });

  Brand copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    List<String>? cuisineTypes,
    String? website,
    String? contactEmail,
    String? contactPhone,
    bool? isActive,
  }) =>
      Brand(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        logoUrl: logoUrl ?? this.logoUrl,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        cuisineTypes: cuisineTypes ?? this.cuisineTypes,
        website: website ?? this.website,
        contactEmail: contactEmail ?? this.contactEmail,
        contactPhone: contactPhone ?? this.contactPhone,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'logoUrl': logoUrl,
        'coverImageUrl': coverImageUrl,
        'cuisineTypes': cuisineTypes,
        'website': website,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Brand.fromMap(Map<String, dynamic> m, String docId) => Brand(
        id: docId,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        logoUrl: m['logoUrl'] as String?,
        coverImageUrl: m['coverImageUrl'] as String?,
        cuisineTypes: (m['cuisineTypes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        website: m['website'] as String?,
        contactEmail: m['contactEmail'] as String?,
        contactPhone: m['contactPhone'] as String?,
        isActive: m['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}