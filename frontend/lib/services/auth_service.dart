import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../screens/splash_screen.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserModel? _cachedUser;

  static Future<UserModel?> fetchUserByEmail(String email) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return UserModel.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  UserModel? get currentUser => _cachedUser;
  Stream<UserModel?> get authStateChanges => _getAuthStateChanges();

  Stream<UserModel?> _getAuthStateChanges() async* {
    yield null;
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = await fetchUserByEmail(email);
    if (user == null) {
      throw AuthException(
        code: 'user-not-found',
        message: 'No profile found for this account.',
      );
    }
    _cachedUser = user;
    return user;
  }

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    UserRole role = UserRole.customer,
  }) async {
    final model = UserModel(
      id: email.hashCode.toString(),
      email: email.trim(),
      displayName: displayName,
      phone: phone,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await _db.collection('users').doc(model.id).set(model.toFirestore());
      _cachedUser = model;
      return model;
    } catch (e) {
      throw AuthException(code: 'register_failed', message: 'Failed to register user: $e');
    }
  }

  Future<void> logout(BuildContext context) async {
    _cachedUser = null;
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {}

  Future<UserModel> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
    String? photoUrl,
    Map<String, String>? address,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'displayName': ?displayName,
      'phone': ?phone,
      'photoUrl': ?photoUrl,
      'address': ?address,
    };
    try {
      await _db.collection('users').doc(uid).update(updates);
      final snap = await _db.collection('users').doc(uid).get();
      final updated = UserModel.fromFirestore(snap);
      _cachedUser = updated;
      return updated;
    } catch (e) {
      throw AuthException(code: 'update_failed', message: 'Failed to update profile: $e');
    }
  }
}

class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}
