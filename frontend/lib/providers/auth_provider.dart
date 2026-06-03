import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb hide AuthProvider;
import '../models/user_model.dart';
import 'locale_provider.dart';
import '../services/auth_gate.dart';
import '../screens/home_screen.dart';
import '../admin/admin_app.dart';
import '../screens/cashier/cashier_dashboard_screen.dart';
import '../screens/delivery/delivery_dashboard_screen.dart';
import '../screens/vendor/vendor_dashboard_screen.dart';
import '../screens/splash_screen.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  /// Called by _SessionGate after Firebase Auth restores the persisted session.
  /// Fetches the Firestore user doc and sets [_user] so the rest of the app
  /// can read role metadata for routing.
  Future<UserModel?> resolveUser(fb.User firebaseUser) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      } else {
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.customer,
        );
      }
    } catch (_) {
      _user = null;
    }
    notifyListeners();
    return _user;
  }

  bool get isSuperAdmin => _user?.role == UserRole.superAdmin;
  bool get isRestaurantOwner => _user?.role == UserRole.restaurantOwner;
  bool get isCashier => _user?.role == UserRole.cashier;
  bool get isDriver => _user?.role == UserRole.driver;
  bool get isCustomer => _user?.role == UserRole.customer;

  String get userRole => _user?.role.name ?? 'customer';

  Future<bool> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try Firebase Auth first (session persisted to IndexedDB on web)
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      if (credential.user == null) {
        _error = 'Authentication returned empty user';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      // Firebase Auth succeeded — resolve the Firestore profile immediately
      await resolveUser(credential.user!);
      _isLoading = false;
      notifyListeners();
      // Navigate immediately to dashboard without page refresh
      if (context.mounted) {
        _routeToRoleDashboard(context, _user!.role);
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      // Demo mode fallback: hardcoded DemoUsers (no Firebase Auth).
      // Navigate immediately to dashboard.
      final demoUser = DemoUsers.findByEmailAndPassword(email.trim(), password);
      if (demoUser != null) {
        _user = demoUser;
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          _routeToRoleDashboard(context, _user!.role);
        }
        return true;
      }
      _error = e.message ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _routeToRoleDashboard(BuildContext context, UserRole role) {
    Widget targetScreen;
    String? vendorId;

    if (_user != null) {
      vendorId = _user!.vendorId;
    }

    switch (role) {
      case UserRole.superAdmin:
        targetScreen = const AdminApp();
        break;
      case UserRole.restaurantOwner:
        targetScreen = VendorDashboardScreen(
          vendorId: vendorId ?? 'vendor-1',
          vendorName: _user?.displayName ?? 'Restaurant',
        );
        break;
      case UserRole.cashier:
        targetScreen = const CashierDashboardScreen();
        break;
      case UserRole.driver:
        targetScreen = const DeliveryDashboardScreen();
        break;
      case UserRole.customer:
        targetScreen = CustomerHome(locale: context.read<LocaleProvider>());
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
  }

  void routeToDashboardByRole(BuildContext context) {
    if (_user == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    _routeToRoleDashboard(context, _user!.role);
  }

  /// Full session teardown:
  /// 1. Flush in-memory caches via [AuthGateService] logout listeners.
  /// 2. Sign out of Firebase Auth.
  /// 3. Null local user and notify.
  /// 4. Force-navigate to [LoginScreen] via root navigator key.
  Future<void> logout(BuildContext context) async {
    try {
      await AuthGateService.instance.fireLogoutCallbacks();
    } catch (_) {}
    _user = null;
    notifyListeners();
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Lightweight sign-out (no Firebase, no routing — used internally).
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update({
            'displayName': ?displayName,
            'email': ?email,
            'phone': ?phone,
            'photoUrl': ?photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _user = _user!.copyWith(
        displayName: displayName,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
    }
  }
}
