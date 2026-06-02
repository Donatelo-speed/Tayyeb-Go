class Vendor {
  final String id;
  final String name;
  final String typeDisplay;
  final String address;
  final double rating;
  final bool isOpen;
  final String? phone;
  final String? email;

  const Vendor({
    required this.id,
    required this.name,
    this.typeDisplay = 'Restaurant',
    this.address = '',
    this.rating = 0.0,
    this.isOpen = true,
    this.phone,
    this.email,
  });

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      typeDisplay: map['typeDisplay'] as String? ?? 'Restaurant',
      address: map['address'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: map['isOpen'] as bool? ?? true,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'typeDisplay': typeDisplay,
    'address': address,
    'rating': rating,
    'isOpen': isOpen,
    'phone': phone,
    'email': email,
  };
}
