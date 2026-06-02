import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthGateService {
  AuthGateService._();
  static final AuthGateService instance = AuthGateService._();

  fb.User? _currentUser;
  fb.User? get currentUser => _currentUser;

  final List<VoidCallback> _logoutListeners = [];

  void addLogoutListener(VoidCallback cb) => _logoutListeners.add(cb);

  Stream<fb.User?> init() {
    final stream = fb.FirebaseAuth.instance.authStateChanges();
    stream.listen((user) {
      _currentUser = user;
    });
    return stream;
  }

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
