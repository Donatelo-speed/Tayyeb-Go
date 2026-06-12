import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/enums/user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final String? vendorId;
  final bool isActive;
  final int loyaltyPoints;
  final String? address;
  final String preferredLocale;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSignInAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.photoUrl,
    this.role = UserRole.customer,
    this.vendorId,
    this.isActive = true,
    this.loyaltyPoints = 0,
    this.address,
    this.preferredLocale = 'en',
    this.createdAt,
    this.updatedAt,
    this.lastSignInAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      phone: d['phone'] as String?,
      photoUrl: d['photoUrl'] as String?,
      role: UserRole.fromString(d['role'] as String?),
      vendorId: d['restaurantId'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      loyaltyPoints: (d['loyaltyPoints'] as num?)?.toInt() ?? 0,
      address: d['address'] as String?,
      preferredLocale: d['preferredLocale'] as String? ?? 'en',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      lastSignInAt: (d['lastSignInAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'role': role.value,
        if (vendorId != null) 'restaurantId': vendorId,
        'isActive': isActive,
        'loyaltyPoints': loyaltyPoints,
        if (address != null) 'address': address,
        'preferredLocale': preferredLocale,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (lastSignInAt != null) 'lastSignInAt': Timestamp.fromDate(lastSignInAt!),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? photoUrl,
    UserRole? role,
    String? vendorId,
    bool? isActive,
    int? loyaltyPoints,
    String? address,
    String? preferredLocale,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSignInAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      vendorId: vendorId ?? this.vendorId,
      isActive: isActive ?? this.isActive,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      address: address ?? this.address,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }
}
