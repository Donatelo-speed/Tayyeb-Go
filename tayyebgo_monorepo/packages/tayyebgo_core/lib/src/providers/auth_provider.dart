import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/enums/user_role.dart';
import '../models/user_model.dart';
import '../services/auth_gate.dart';
import '../services/auth_listenable.dart';

String _friendlyAuthError(Object e) {
  final code = e is fb.FirebaseAuthException ? e.code : '';
  switch (code) {
    case 'invalid-email':
      return 'Invalid email address. Please check and try again.';
    case 'user-not-found':
      return 'No account found with this email address.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'email-already-in-use':
      return 'An account already exists with this email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'Unable to connect. Please check your network.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'operation-not-allowed':
      return 'This sign-in method is not currently enabled.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with a different sign-in method.';
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'invalid-verification-code':
      return 'Invalid verification code. Please try again.';
    case 'captcha-check-failed':
      return 'Captcha verification failed. Please try again.';
    case 'quota-exceeded':
      return 'SMS quota exceeded. Please try again later.';
    default:
      return e.toString().contains('failed-precondition')
          ? 'Unable to load data right now. Please try again.'
          : 'Something went wrong. Please try again.';
  }
}

class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider? get instance => _instance;

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  String? _verificationId;
  int _otpCountdown = 0;
  Timer? _otpTimer;
  StreamSubscription<fb.User?>? _authSubscription;
  bool _onboardingComplete = false;
  bool _loginInProgress = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  int get otpCountdown => _otpCountdown;
  bool get isOtpActive => _otpCountdown > 0;
  bool get onboardingComplete => _onboardingComplete;

  set error(String? v) {
    _error = v;
    notifyListeners();
  }

  bool get isSuperAdmin => _user?.role == UserRole.superAdmin;
  bool get isRestaurantOwner => _user?.role == UserRole.restaurantOwner;
  bool get isCashier => _user?.role == UserRole.cashier;
  bool get isDriver => _user?.role == UserRole.driver;
  bool get isCustomer => _user?.role == UserRole.customer;
  String get userRole => _user?.role.value ?? 'customer';

  AuthProvider() {
    _instance = this;
    _isInitializing = true;
    _authSubscription = fb.FirebaseAuth.instance.authStateChanges().listen(
      _syncFirebaseUser,
      onError: (Object e) {
        _error = _friendlyAuthError(e);
        _isLoading = false;
        notifyListeners();
        _notifyRouter();
      },
    );
  }

  void _notifyRouter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthListenable.instance?.forceNotify();
    });
  }

  Future<void> _syncFirebaseUser(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      final hadState = _user != null || _isInitializing || _error != null;
      _user = null;
      _isInitializing = false;
      if (hadState) {
        notifyListeners();
        _notifyRouter();
      }
      return;
    }

    if (_user?.id == firebaseUser.uid && !_isInitializing) {
      return;
    }

    if (_loginInProgress) {
      return;
    }

    _isInitializing = true;
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    await resolveUser(firebaseUser);
    _isInitializing = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      _notifyRouter();
    });
  }

  void setOnboardingComplete() {
    _onboardingComplete = true;
    notifyListeners();
  }

  Future<UserModel?> resolveUser(fb.User firebaseUser) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      } else {
        final now = DateTime.now();
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.customer,
          createdAt: now,
          updatedAt: now,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(_user!.toFirestore());
      }
    } on TimeoutException {
      _error = 'Connection timed out. Please check your network.';
      _user = null;
    } catch (e) {
      _error = _friendlyAuthError(e);
      _user = null;
    }
    return _user;
  }

  Future<bool> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    _isLoading = true;
    _loginInProgress = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      if (credential.user == null) {
        _error = 'Authentication returned empty user';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      await resolveUser(credential.user!);
      if (_user == null) {
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      if (!_user!.isActive) {
        _error =
            'Your account has been deactivated. Please contact your administrator.';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    String? photoUrl,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      if (credential.user == null) {
        _error = 'Account creation returned empty user';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await credential.user!.sendEmailVerification();
      await credential.user!.updateDisplayName(displayName);
      final now = DateTime.now();
      _user = UserModel(
        id: credential.user!.uid,
        email: email.trim(),
        displayName: displayName,
        phone: phone,
        photoUrl: photoUrl,
        role: UserRole.customer,
        address: address,
        createdAt: now,
        updatedAt: now,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(_user!.toFirestore());
      _isLoading = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _loginInProgress = true;
    _error = null;
    notifyListeners();
    try {
      final googleProvider = fb.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      final fb.UserCredential result;
      if (kIsWeb) {
        result = await fb.FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        result = await fb.FirebaseAuth.instance.signInWithProvider(
          googleProvider,
        );
      }
      if (result.user == null) {
        _error = 'Google sign-in returned no user';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      await resolveUser(result.user!);
      if (_user == null) {
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      if (!_user!.isActive) {
        _error =
            'Your account has been deactivated. Please contact your administrator.';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    _error = 'Apple sign-in coming soon';
    notifyListeners();
    return false;
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on fb.FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e);
    } catch (e) {
      _error = _friendlyAuthError(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final completer = Completer<bool>();
    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete(true);
        },
        verificationFailed: (e) {
          _error = _friendlyAuthError(e);
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (verificationId, forceResendingToken) {
          _verificationId = verificationId;
          _isLoading = false;
          _startOtpCountdown();
          notifyListeners();
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _error = _friendlyAuthError(e);
      _isLoading = false;
      notifyListeners();
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  void _startOtpCountdown() {
    _otpCountdown = 60;
    _otpTimer?.cancel();
    notifyListeners();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _otpCountdown--;
      if (_otpCountdown <= 0) {
        t.cancel();
        notifyListeners();
      } else if (_otpCountdown % 5 == 0) {
        notifyListeners();
      }
    });
  }

  String get otpCountdownText {
    final m = (_otpCountdown ~/ 60).toString().padLeft(2, '0');
    final s = (_otpCountdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> verifyOtpCode(String otp) async {
    if (_verificationId == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final result = await fb.FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      _verificationId = null;
      _otpTimer?.cancel();
      if (result.user != null) {
        await resolveUser(result.user!);
      }
      _isLoading = false;
      notifyListeners();
      _notifyRouter();
      return _user != null;
    } on fb.FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e);
    } catch (e) {
      _error = _friendlyAuthError(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Widget getDashboardForRole() {
    if (_user == null) {
      return const _LoginRedirect();
    }
    switch (_user!.role) {
      case UserRole.superAdmin:
        return const _AppRedirect('admin');
      case UserRole.restaurantOwner:
      case UserRole.cashier:
        return const _AppRedirect('partner');
      case UserRole.driver:
        return const _AppRedirect('driver');
      case UserRole.customer:
        return const _AppRedirect('customer');
    }
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    _otpTimer?.cancel();
    _otpCountdown = 0;
    _isLoading = false;
    notifyListeners();
    _notifyRouter();
    await AuthGateService.instance.fireLogoutCallbacks();
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updates = <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update(updates);
      _user = _user!.copyWith(
        displayName: displayName,
        phone: phone,
        address: address,
        photoUrl: photoUrl,
      );
    } catch (e) {
      _error = _friendlyAuthError(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> pickAndUploadProfileImage() async {
    if (_user == null) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_user!.id}.jpg');
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();
      _user = _user!.copyWith(photoUrl: url);
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _error = 'Failed to upload profile image.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _authSubscription?.cancel();
    if (_instance == this) {
      _instance = null;
    }
    super.dispose();
  }
}

class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Please log in')));
  }
}

class _AppRedirect extends StatelessWidget {
  final String app;
  const _AppRedirect(this.app);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Redirecting to $app app...'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
