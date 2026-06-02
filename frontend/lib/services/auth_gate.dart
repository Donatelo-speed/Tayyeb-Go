import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../screens/splash_screen.dart';

/// Global navigator key so [AuthProvider.logout] can force-navigate to
/// [LoginScreen] from any widget without a mounted BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Singleton that listens to [FirebaseAuth.authStateChanges] and holds a
/// list of callbacks that fire on logout so providers can flush in-memory
/// caches before the session is torn down.
class AuthGateService {
  AuthGateService._();
  static final AuthGateService instance = AuthGateService._();

  fb.User? _currentUser;
  fb.User? get currentUser => _currentUser;

  final List<VoidCallback> _logoutListeners = [];

  void addLogoutListener(VoidCallback cb) => _logoutListeners.add(cb);

  /// Start listening to Firebase auth state.  Returns the stream for
  /// optional use by _SessionGate.
  Stream<fb.User?> init() {
    final stream = fb.FirebaseAuth.instance.authStateChanges();
    stream.listen((user) {
      _currentUser = user;
    });
    return stream;
  }

  /// Fire all cache-flush callbacks and sign out of Firebase.
  Future<void> fireLogoutCallbacks() async {
    for (final cb in _logoutListeners) {
      cb();
    }
    _logoutListeners.clear();
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    _currentUser = null;
  }
}
