class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String status;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.status,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['full_name'] ?? json['name'] ?? '',
      phone: json['phone'],
      role: json['role'],
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isDelivery => role == 'delivery';
  bool get isCustomer => role == 'customer';
  bool get isActive => status == 'active';
}