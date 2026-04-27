class User {
  final int id;
  final String? email;
  final String? name;
  final String? phone;
  final String? role;
  final String? status;
  final DateTime? createdAt;

  User({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.role,
    this.status,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email']?.toString(),
      name: json['full_name']?.toString() ?? json['name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isDelivery => role == 'delivery';
  bool get isCustomer => role == 'customer';
  bool get isActive => status == 'active';
  String get displayName => name ?? 'User';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
    };
  }
}