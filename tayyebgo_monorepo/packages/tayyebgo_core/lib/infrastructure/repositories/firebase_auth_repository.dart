import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  static final FirebaseAuthRepository instance = FirebaseAuthRepository._();
  FirebaseAuthRepository._();
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return AppUser(
      id: u.uid,
      email: u.email ?? '',
      displayName: u.displayName ?? u.email ?? '',
      photoUrl: u.photoURL,
      phone: u.phoneNumber ?? '',
      role: UserRole.customer,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((fbUser) async {
        if (fbUser == null) return null;
        final doc = await _firestore.collection('Users').doc(fbUser.uid).get();
        if (doc.exists) {
          return AppUser.fromMap(doc.data()!, doc.id);
        }
        return AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: fbUser.displayName ?? '',
          photoUrl: fbUser.photoURL,
          phone: fbUser.phoneNumber ?? '',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );
      });

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    return _resolveOrCreate(cred.user!);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleProvider = fb.GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    final result = await _auth.signInWithPopup(googleProvider);
    return _resolveOrCreate(result.user!);
  }

  @override
  Future<AppUser> signInWithPhone(String phoneNumber) async {
    final completer = Completer<fb.User>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (cred) async {
        final result = await _auth.signInWithCredential(cred);
        completer.complete(result.user);
      },
      verificationFailed: (e) => completer.completeError(e),
      codeSent: (verificationId, _) {},
      codeAutoRetrievalTimeout: (_) {},
    );
    final user = await completer.future;
    return _resolveOrCreate(user);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<AppUser> resolveUser(String firebaseUid) async {
    final doc = await _firestore.collection('Users').doc(firebaseUid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    final fbUser = _auth.currentUser;
    return AppUser(
      id: firebaseUid,
      email: fbUser?.email ?? '',
      displayName: fbUser?.displayName ?? '',
      photoUrl: fbUser?.photoURL,
      phone: fbUser?.phoneNumber ?? '',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateProfile(AppUser user) async {
    await _firestore.collection('Users').doc(user.id).set(user.toMap());
  }

  AppUser _resolveOrCreate(fb.User fbUser) {
    return AppUser(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? '',
      photoUrl: fbUser.photoURL,
      phone: fbUser.phoneNumber ?? '',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
  }
}
