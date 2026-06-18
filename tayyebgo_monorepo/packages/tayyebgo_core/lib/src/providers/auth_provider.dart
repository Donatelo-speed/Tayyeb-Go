import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/enums/user_role.dart';
import '../../infrastructure/services/push_notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_gate.dart';
import '../services/auth_listenable.dart';

String _friendlyAuthError(Object e) {
  final code = e is fb.FirebaseAuthException ? e.code : '';
  switch (code) {
    case 'invalid-email':
      return 'Invalid email address. Please check and try again.';
    case 'user-not-found':
      return 'Incorrect email or password.';
    case 'wrong-password':
      return 'Incorrect email or password.';
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

  /// Static role hint set before runApp() — used when no Firestore doc exists.
  /// Each app sets this in main() to the role(s) it serves.
  static UserRole? defaultExpectedRole;

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
  bool _disposed = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading || _isInitializing;
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

  /// Whether the current user has any of the given roles.
  bool hasAnyRole(List<UserRole> roles) =>
      _user != null && roles.contains(_user!.role);

  /// Whether the current user can access the given app.
  bool canAccessApp(String app) =>
      _user != null &&
      UserRole.allowedRolesForApp(app).contains(_user!.role);

  AuthProvider() {
    _instance = this;
    _isInitializing = true;
    _authSubscription = fb.FirebaseAuth.instance.authStateChanges().listen(
      _syncFirebaseUser,
      onError: (Object e) {
        _error = _friendlyAuthError(e);
        _isLoading = false;
        _isInitializing = false;
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
    notifyListeners();
    await resolveUser(firebaseUser);
    _isInitializing = false;
    notifyListeners();
    _notifyRouter();

    if (_user != null) {
      PushNotificationService().initializeAndRegister(_user!.id, _user!.role.name);
    }
  }

  void setOnboardingComplete() {
    _onboardingComplete = true;
    notifyListeners();
  }

  /// The role this app expects users to have. Set by the app at startup.
  /// When a new user signs in without a Firestore doc, this role is used
  /// to create their profile instead of defaulting to customer.
  UserRole? _expectedRole;

  /// Set the expected role for this app instance.
  /// Call this at app startup, e.g. AuthProvider.instance.setExpectedRole(UserRole.driver)
  void setExpectedRole(UserRole role) => _expectedRole = role;

  /// Clear the expected role (e.g. on logout).
  void clearExpectedRole() => _expectedRole = null;

  static const _testAccountRoles = <String, String>{
    'admin@test.com': 'superAdmin',
    'owner@test.com': 'restaurantOwner',
    'cashier@test.com': 'cashier',
    'driver@test.com': 'driver',
    'customer@test.com': 'customer',
  };

  Future<UserModel?> resolveUser(fb.User firebaseUser) async {
    try {
      if (kDebugMode) debugPrint('[AuthProvider] resolveUser: reading Firestore for uid=${firebaseUser.uid}');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
        if (kDebugMode) debugPrint('[AuthProvider] resolveUser: found doc, role=${_user!.role.value}');

        final now = DateTime.now();
        final email = (firebaseUser.email ?? '').toLowerCase();

        // TEST ACCOUNT AUTO-FIX: If this is a known test account and the
        // Firestore role is wrong, fix it automatically.
        final correctRole = _testAccountRoles[email];
        if (correctRole != null && _user!.role.value != correctRole) {
          if (kDebugMode) debugPrint('[AuthProvider] resolveUser: fixing test account $email role=${_user!.role.value} → $correctRole');
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .update({'role': correctRole});
            if (kDebugMode) debugPrint('[AuthProvider] resolveUser: Firestore role updated to $correctRole');
          } catch (updateError) {
            if (kDebugMode) debugPrint('[AuthProvider] resolveUser: Firestore update failed (non-blocking): $updateError');
          }
          _user = _user!.copyWith(role: UserRole.fromValue(correctRole));
        }

        _user = _user!.copyWith(lastSignInAt: now, updatedAt: now);
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .update({
            'lastSignInAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });
        } catch (e) {
          if (kDebugMode) debugPrint('[AuthProvider] resolveUser: could not update timestamps (non-critical): $e');
        }
      } else {
        // No Firestore doc — create one using the app's expected role.
        final email = (firebaseUser.email ?? '').toLowerCase();
        final roleValue = _testAccountRoles[email] ??
            (_expectedRole ?? defaultExpectedRole ?? UserRole.customer).value;
        final role = UserRole.fromValue(roleValue);
        if (kDebugMode) debugPrint('[AuthProvider] resolveUser: NO Firestore doc for uid=${firebaseUser.uid} — creating with role=${role.value}');
        final now = DateTime.now();
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          role: role,
          createdAt: now,
          updatedAt: now,
          lastSignInAt: now,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(_user!.toFirestore());
        if (kDebugMode) debugPrint('[AuthProvider] resolveUser: created Firestore doc with role=${role.value}');
      }
    } on TimeoutException {
      if (kDebugMode) debugPrint('[AuthProvider] resolveUser: TIMEOUT');
      _error = 'Connection timed out. Please check your network.';
      _user = null;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthProvider] resolveUser: ERROR $e');
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
    if (_disposed) return false;
    if (kDebugMode) debugPrint('[AuthProvider] login: email=$email');
    _isLoading = true;
    _loginInProgress = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      if (credential.user == null) {
        if (_disposed) return false;
        _error = 'Authentication returned empty user';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      if (kDebugMode) debugPrint('[AuthProvider] login: Firebase Auth success, uid=${credential.user!.uid}');
      await resolveUser(credential.user!);
      if (_disposed) return false;
      if (_user == null) {
        if (kDebugMode) debugPrint('[AuthProvider] login: resolveUser returned null');
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      if (kDebugMode) debugPrint('[AuthProvider] login: resolved user role=${_user!.role.value} isActive=${_user!.isActive}');
      if (!_user!.isActive) {
        _error =
            'Your account has been deactivated. Please contact your administrator.';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (_disposed) return false;
      if (kDebugMode) debugPrint('[AuthProvider] login: FirebaseAuthException ${e.code}');
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (_disposed) return false;
      if (kDebugMode) debugPrint('[AuthProvider] login: error $e');
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
    if (_disposed) return false;
    _isLoading = true;
    _loginInProgress = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      if (credential.user == null) {
        if (_disposed) return false;
        _error = 'Account creation returned empty user';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      await credential.user!.sendEmailVerification();
      await credential.user!.updateDisplayName(displayName);

      // Use resolveUser for consistent user creation flow
      // This handles Firestore write and timestamp updates
      _user = await resolveUser(credential.user!);

      if (_disposed) return false;
      if (_user == null) {
        _error = 'Failed to create user profile';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }

      // Update additional profile fields
      final updates = <String, dynamic>{
        'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (address != null) 'address': address,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .update(updates);

      _user = _user!.copyWith(
        displayName: displayName,
        phone: phone,
        photoUrl: photoUrl,
        address: address,
      );

      if (_disposed) return false;
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_disposed) return false;
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
        if (_disposed) return false;
        _error = 'Google sign-in returned no user';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      await resolveUser(result.user!);
      if (_disposed) return false;
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
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    if (_disposed) return false;
    _isLoading = true;
    _loginInProgress = true;
    _error = null;
    notifyListeners();
    try {
      final appleProvider = fb.AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      final fb.UserCredential result;
      if (kIsWeb) {
        result = await fb.FirebaseAuth.instance.signInWithPopup(appleProvider);
      } else {
        result = await fb.FirebaseAuth.instance.signInWithProvider(appleProvider);
      }
      if (result.user == null) {
        if (_disposed) return false;
        _error = 'Apple sign-in returned no user';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      await resolveUser(result.user!);
      if (_disposed) return false;
      if (_user == null) {
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      if (!_user!.isActive) {
        _error = 'Your account has been deactivated. Please contact your administrator.';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
    } catch (e) {
      // Always show success to prevent account enumeration.
      // Firebase already silently ignores non-existent emails.
      if (kDebugMode) debugPrint('[resetPassword] Error (suppressed): $e');
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
      }
      notifyListeners();
    });
  }

  String get otpCountdownText {
    final m = (_otpCountdown ~/ 60).toString().padLeft(2, '0');
    final s = (_otpCountdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> verifyOtpCode(String otp) async {
    if (_verificationId == null) return false;
    if (_disposed) return false;
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
      _otpCountdown = 0;
      if (result.user != null) {
        await resolveUser(result.user!);
      }
      if (_disposed) return false;
      if (_user == null) {
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      if (!_user!.isActive) {
        _error = 'Your account has been deactivated. Please contact your administrator.';
        _isLoading = false;
        _loginInProgress = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      _isInitializing = false;
      _loginInProgress = false;
      notifyListeners();
      _notifyRouter();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
    } catch (e) {
      if (_disposed) return false;
      _error = _friendlyAuthError(e);
    }
    _isLoading = false;
    _isInitializing = false;
    _loginInProgress = false;
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
    clearExpectedRole();
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
          .child('users')
          .child('${_user!.id}')
          .child('profile_picture.jpg');
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
    _disposed = true;
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
