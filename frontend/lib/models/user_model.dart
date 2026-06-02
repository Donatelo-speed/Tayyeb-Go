// =====================================================
// TAYYEB-GO — lib/models/user_model.dart
//
// Typed Dart model for the /users/{uid} Firestore collection.
//
// Replaces the thin `User` class that had no Firestore serialisation.
// The old `User` class and `DemoUsers` helper are preserved at the
// bottom of this file so existing code that imports `UserRole` or
// `DemoUsers` still compiles without changes.
// =====================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// UserRole enum
// =============================================================================

/// Canonical roles across the platform.
/// Must stay in sync with the `role` string values written to Firestore.
enum UserRole {
  superAdmin,
  restaurantOwner,
  cashier,
  driver,
  customer;

  // ── Firestore string ↔ enum helpers ───────────────────────────────────────

  /// Converts a Firestore `role` string to the enum value.
  /// Falls back to [UserRole.customer] for unknown values.
  static UserRole fromString(String? value) {
    return switch (value) {
      'superAdmin'      => UserRole.superAdmin,
      'restaurantOwner' => UserRole.restaurantOwner,
      'cashier'         => UserRole.cashier,
      'driver'          => UserRole.driver,
      _                 => UserRole.customer,
    };
  }

  /// The string stored in Firestore (camelCase).
  String get firestoreValue => switch (this) {
    UserRole.superAdmin      => 'superAdmin',
    UserRole.restaurantOwner => 'restaurantOwner',
    UserRole.cashier         => 'cashier',
    UserRole.driver          => 'driver',
    UserRole.customer        => 'customer',
  };

  /// Human-readable display label (English).
  String get displayName => switch (this) {
    UserRole.superAdmin      => 'Super Admin',
    UserRole.restaurantOwner => 'Restaurant Owner',
    UserRole.cashier         => 'Cashier',
    UserRole.driver          => 'Driver',
    UserRole.customer        => 'Customer',
  };
}

// =============================================================================
// UserModel
// =============================================================================

/// Immutable representation of a Tayyeb-Go user stored in Firestore.
///
/// Firestore schema  (/users/{uid}):
/// ```
/// {
///   "uid":             "firebase-uid",          // document ID
///   "email":           "user@example.com",
///   "displayName":     "Ahmed Ali",
///   "phone":           "+966501234567",          // nullable
///   "photoUrl":        "https://...",            // nullable
///   "role":            "customer",               // UserRole.firestoreValue
///   "vendorId":        "vendor-doc-id",          // nullable (owner / cashier)
///   "isActive":        true,
///   "loyaltyPoints":   0,
///   "address": {                                 // nullable last-used address
///     "street":   "...",
///     "city":     "...",
///     "district": "...",
///     "notes":    "..."
///   },
///   "preferredLocale": "en",                     // "en" | "ar"
///   "createdAt":       Timestamp,
///   "updatedAt":       Timestamp
/// }
/// ```
class UserModel {
  final String    id;
  final String    email;
  final String    displayName;
  final String?   phone;
  final String?   photoUrl;
  final UserRole  role;
  final String?   vendorId;       // non-null for restaurantOwner / cashier
  final bool      isActive;
  final int       loyaltyPoints;
  final Map<String, String>? address;
  final String    preferredLocale;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.photoUrl,
    required this.role,
    this.vendorId,
    this.isActive        = true,
    this.loyaltyPoints   = 0,
    this.address,
    this.preferredLocale = 'en',
    this.createdAt,
    this.updatedAt,
  });

  // ── Role convenience getters ──────────────────────────────────────────────

  bool get isSuperAdmin      => role == UserRole.superAdmin;
  bool get isRestaurantOwner => role == UserRole.restaurantOwner;
  bool get isCashier         => role == UserRole.cashier;
  bool get isDriver          => role == UserRole.driver;
  bool get isCustomer        => role == UserRole.customer;

  // ── Firestore deserialization ─────────────────────────────────────────────

  /// Constructs a [UserModel] from a Firestore [DocumentSnapshot].
  ///
  /// The document ID is used as the canonical [id]; no separate `uid` field
  /// is required in the document body (though one may be present).
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Helper: safely coerce Timestamp / String / null → DateTime?
    DateTime? _toDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String)    return DateTime.tryParse(value);
      return null;
    }

    // Helper: safely coerce a nested map to Map<String, String>
    Map<String, String>? _toStringMap(dynamic value) {
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return null;
    }

    return UserModel(
      id:              doc.id,
      email:           (data['email']           as String?)  ?? '',
      displayName:     (data['displayName']      as String?)  ?? '',
      phone:            data['phone']            as String?,
      photoUrl:         data['photoUrl']         as String?,
      role:            UserRole.fromString(data['role'] as String?),
      vendorId:         data['vendorId']         as String?,
      isActive:        (data['isActive']         as bool?)    ?? true,
      loyaltyPoints:   (data['loyaltyPoints']    as int?)     ?? 0,
      address:         _toStringMap(data['address']),
      preferredLocale: (data['preferredLocale']  as String?)  ?? 'en',
      createdAt:       _toDateTime(data['createdAt']),
      updatedAt:       _toDateTime(data['updatedAt']),
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  /// Returns a [Map] suitable for writing to Firestore via `set()` or
  /// `update()`.  The document ID ([id]) is intentionally excluded so that
  /// the map can be passed directly to `.doc(uid).set(...)`.
  Map<String, dynamic> toFirestore() {
    return {
      'email':           email,
      'displayName':     displayName,
      if (phone    != null) 'phone':    phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role':            role.firestoreValue,
      if (vendorId != null) 'vendorId': vendorId,
      'isActive':        isActive,
      'loyaltyPoints':   loyaltyPoints,
      if (address  != null) 'address':  address,
      'preferredLocale': preferredLocale,
      // Use FieldValue.serverTimestamp() for new documents; DateTime for
      // reads that we round-trip back.  callers should override createdAt
      // with FieldValue.serverTimestamp() on first write.
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  UserModel copyWith({
    String?             id,
    String?             email,
    String?             displayName,
    String?             phone,
    String?             photoUrl,
    UserRole?           role,
    String?             vendorId,
    bool?               isActive,
    int?                loyaltyPoints,
    Map<String, String>? address,
    String?             preferredLocale,
    DateTime?           createdAt,
    DateTime?           updatedAt,
  }) {
    return UserModel(
      id:              id              ?? this.id,
      email:           email           ?? this.email,
      displayName:     displayName     ?? this.displayName,
      phone:           phone           ?? this.phone,
      photoUrl:        photoUrl        ?? this.photoUrl,
      role:            role            ?? this.role,
      vendorId:        vendorId        ?? this.vendorId,
      isActive:        isActive        ?? this.isActive,
      loyaltyPoints:   loyaltyPoints   ?? this.loyaltyPoints,
      address:         address         ?? this.address,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      createdAt:       createdAt       ?? this.createdAt,
      updatedAt:       updatedAt       ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, role: ${role.firestoreValue})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// Backward-compat shim — keeps existing code that imports `User` compiling
// =============================================================================

/// @deprecated  Use [UserModel] for all new code.
typedef User = UserModel;

// =============================================================================
// DemoUsers — local mock data for development / staging builds
// =============================================================================

/// Static demo credentials used when Firebase is not configured.
/// In production these are never used; the real data comes from Firestore.
class DemoUsers {
  static final List<UserModel> all = [
    UserModel(
      id:          'demo-super-admin',
      email:       'admin@tayyeb.com',
      displayName: 'System Admin',
      role:        UserRole.superAdmin,
      createdAt:   DateTime(2024, 1, 1),
      updatedAt:   DateTime(2024, 1, 1),
    ),
    UserModel(
      id:          'demo-owner',
      email:       'owner@almandi.com',
      displayName: 'Al Mandi Owner',
      role:        UserRole.restaurantOwner,
      vendorId:    'vendor-almandi',
      createdAt:   DateTime(2024, 1, 1),
      updatedAt:   DateTime(2024, 1, 1),
    ),
    UserModel(
      id:          'demo-cashier',
      email:       'cashier@almandi.com',
      displayName: 'Ahmed Cashier',
      role:        UserRole.cashier,
      vendorId:    'vendor-almandi',
      createdAt:   DateTime(2024, 1, 1),
      updatedAt:   DateTime(2024, 1, 1),
    ),
    UserModel(
      id:          'demo-driver',
      email:       'driver@company.com',
      displayName: 'Khaled Driver',
      role:        UserRole.driver,
      createdAt:   DateTime(2024, 1, 1),
      updatedAt:   DateTime(2024, 1, 1),
    ),
    UserModel(
      id:          'demo-customer',
      email:       'user@test.com',
      displayName: 'John Customer',
      role:        UserRole.customer,
      createdAt:   DateTime(2024, 1, 1),
      updatedAt:   DateTime(2024, 1, 1),
    ),
  ];

  static UserModel? findByEmail(String email) {
    try {
      return all.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  /// Password is not validated in demo mode — any non-empty string works.
  static UserModel? findByEmailAndPassword(String email, String password) {
    if (password.isEmpty) return null;
    return findByEmail(email);
  }
}
