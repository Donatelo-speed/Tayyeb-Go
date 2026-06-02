import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/enums/user_role.dart';
import '../models/user_model.dart';
import '../utils/result.dart';

class AuthRepository {
  AuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  String? _verificationId;

  Stream<UserModel?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        return _fetchOrCreateUserDoc(firebaseUser);
      });

  Future<UserModel?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchOrCreateUserDoc(firebaseUser);
  }

  Future<Result<UserModel>> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _fetchOrCreateUserDoc(credential.user!);
      if (!user.isActive) {
        await _auth.signOut();
        return Failure('Your account has been deactivated. Contact support for assistance.');
      }
      return Success(user);
    } on fb.FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('An unexpected error occurred. Please try again.', error: e);
    }
  }

  Future<Result<UserModel>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(displayName.trim());

      final userModel = UserModel(
        id: firebaseUser.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        phone: phone?.trim(),
        role: role,
        isActive: true,
        loyaltyPoints: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('Users').doc(firebaseUser.uid).set({
        ...userModel.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Success(userModel);
    } on fb.FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('Registration failed. Please try again.', error: e);
    }
  }

  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return const Failure('Sign-in cancelled.');
      }
      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;
      final user = await _fetchOrCreateUserDoc(firebaseUser);
      if (!user.isActive) {
        await signOut();
        return const Failure('Your account has been deactivated. Contact support.');
      }
      return Success(user);
    } on fb.FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('Google Sign-In failed. Please try again.', error: e);
    }
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
    void Function(UserModel user)? onAutoVerified,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          final user = await _fetchOrCreateUserDoc(userCredential.user!);
          onAutoVerified?.call(user);
        } catch (_) {}
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId, resendToken);
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        onFailed(_mapAuthError(e.code));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<Result<UserModel>> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      return const Failure('No OTP session active. Please request a new code.');
    }
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      _verificationId = null;
      final user = await _fetchOrCreateUserDoc(userCredential.user!);
      if (!user.isActive) {
        await signOut();
        return const Failure('Your account has been deactivated. Contact support.');
      }
      return Success(user);
    } on fb.FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('OTP verification failed. Please try again.', error: e);
    }
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('Could not send reset email. Please try again.', error: e);
    }
  }

  Future<void> signOut() async {
    _verificationId = null;
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<Result<UserModel>> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) {
        updates['displayName'] = displayName.trim();
        await _auth.currentUser?.updateDisplayName(displayName.trim());
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }
      if (phone != null) updates['phone'] = phone.trim();
      await _firestore.collection('Users').doc(uid).update(updates);
      final doc = await _firestore.collection('Users').doc(uid).get();
      return Success(UserModel.fromFirestore(doc));
    } catch (e) {
      return Failure('Profile update failed. Please try again.', error: e);
    }
  }

  Future<UserModel> _fetchOrCreateUserDoc(fb.User firebaseUser) async {
    final docRef = _firestore.collection('Users').doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    final newUser = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? firebaseUser.phoneNumber ?? 'New User',
      phone: firebaseUser.phoneNumber,
      photoUrl: firebaseUser.photoURL,
      role: UserRole.customer,
      isActive: true,
      loyaltyPoints: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set({
      ...newUser.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return newUser;
  }

  static String _mapAuthError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email address.',
        'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
        'invalid-email' => 'Please enter a valid email address.',
        'user-disabled' => 'This account has been disabled. Contact support.',
        'email-already-in-use' => 'An account already exists with this email.',
        'weak-password' => 'Password must be at least 6 characters.',
        'operation-not-allowed' => 'This sign-in method is not enabled. Contact support.',
        'invalid-phone-number' => 'Please enter a valid phone number with country code.',
        'invalid-verification-code' => 'Incorrect code. Please check and try again.',
        'session-expired' => 'Your OTP has expired. Please request a new one.',
        'quota-exceeded' => 'Too many SMS requests. Please try again later.',
        'missing-phone-number' => 'Please enter a phone number.',
        'network-request-failed' => 'No internet connection. Please check your network.',
        'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
        'sign_in_canceled' => 'Sign-in cancelled.',
        'sign_in_failed' => 'Google Sign-In failed. Please try again.',
        'captcha-check-failed' => 'Captcha verification failed. Please try again.',
        _ => 'Something went wrong. Please try again.',
      };
}
