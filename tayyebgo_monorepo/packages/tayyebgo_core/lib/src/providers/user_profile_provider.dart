import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProfileProvider extends ChangeNotifier {
  UserModel? _user;
  String? _profileImageUrl;
  bool _isUpdating = false;
  String? _error;

  UserModel? get user => _user;
  String? get profileImageUrl => _profileImageUrl;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  void initWithUser(UserModel user) {
    _user = user;
    _profileImageUrl = user.photoUrl;
  }

  void setUser(UserModel user) {
    _user = user;
    _profileImageUrl = user.photoUrl;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _profileImageUrl = null;
    _isUpdating = false;
    _error = null;
  }

  Future<String?> pickAndUploadProfileImage(String userId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return null;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();
      _profileImageUrl = url;
      notifyListeners();
      return url;
    } catch (e) {
      _error = 'Failed to upload profile image. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<List<String>> addAddress(String userId, String address) async {
    if (_user == null) return [];
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final doc = await docRef.get();
      final existing = List<String>.from(
        (doc.data()?['addresses'] as List<dynamic>?) ?? [],
      );
      existing.add(address);
      await docRef.update({
        'addresses': existing,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _user = _user!.copyWith(address: address);
      notifyListeners();
      return existing;
    } catch (e) {
      _error = 'Failed to save address. Please try again.';
      notifyListeners();
      return [];
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? phone,
    String? address,
    String? photoUrl,
    String? preferredLocale,
  }) async {
    if (_user == null) return;
    _isUpdating = true;
    _error = null;
    notifyListeners();

    final updates = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (preferredLocale != null) 'preferredLocale': preferredLocale,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);
      _user = _user!.copyWith(
        displayName: displayName,
        phone: phone,
        address: address,
        photoUrl: photoUrl,
        preferredLocale: preferredLocale,
      );
      if (photoUrl != null) _profileImageUrl = photoUrl;
      _isUpdating = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile. Please try again.';
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> loadNotificationPrefs(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();
      return {
        'push': (data?['notifications'] is Map)
            ? (data!['notifications'] as Map)['push'] as bool? ?? true
            : true,
        'sms': (data?['notifications'] is Map)
            ? (data!['notifications'] as Map)['sms'] as bool? ?? true
            : true,
        'email': (data?['notifications'] is Map)
            ? (data!['notifications'] as Map)['email'] as bool? ?? true
            : true,
        'auditLogEnabled': data?['auditLogEnabled'] as bool? ?? true,
      };
    } catch (_) {
      return {'push': true, 'sms': true, 'email': true, 'auditLogEnabled': true};
    }
  }

  Future<bool> saveNotificationPrefs({
    required String userId,
    bool? push,
    bool? sms,
    bool? email,
    bool? auditLogEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (push != null) 'notifications.push': push,
        if (sms != null) 'notifications.sms': sms,
        if (email != null) 'notifications.email': email,
        if (auditLogEnabled != null) 'auditLogEnabled': auditLogEnabled,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearActivityLog() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snap = await FirebaseFirestore.instance.collection('activity_log').limit(500).get();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
