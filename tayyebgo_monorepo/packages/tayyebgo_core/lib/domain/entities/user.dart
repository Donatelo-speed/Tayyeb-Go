import '../enums/user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final String? restaurantId;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone = '',
    this.role = UserRole.customer,
    this.isActive = true,
    required this.createdAt,
    this.restaurantId,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    String? restaurantId,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        restaurantId: restaurantId ?? this.restaurantId,
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phone': phone,
        'role': role.value,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'restaurantId': restaurantId,
      };

  factory AppUser.fromMap(Map<String, dynamic> m, String docId) => AppUser(
        id: docId,
        email: m['email'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        photoUrl: m['photoUrl'] as String?,
        phone: m['phone'] as String? ?? '',
        role: UserRole.fromValue(m['role'] as String? ?? ''),
        isActive: m['isActive'] as bool? ?? true,
        createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        restaurantId: m['restaurantId'] as String?,
      );
}
