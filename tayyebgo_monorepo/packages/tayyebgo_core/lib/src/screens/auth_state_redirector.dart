import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthStateRedirector extends StatefulWidget {
  final Widget child;
  const AuthStateRedirector({super.key, required this.child});

  @override
  State<AuthStateRedirector> createState() => _AuthStateRedirectorState();
}

class _AuthStateRedirectorState extends State<AuthStateRedirector> {
  StreamSubscription<fb.User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = fb.FirebaseAuth.instance.idTokenChanges().listen(
      _onAuthChanged,
    );
  }

  void _onAuthChanged(fb.User? firebaseUser) {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (firebaseUser == null && auth.isAuthenticated) {
      auth.logout();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated && !auth.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final authNow = context.read<AuthProvider>();
        if (!authNow.isAuthenticated && !authNow.isLoading) {
          context.go('/login');
        }
      });
    }
    return widget.child;
  }
}
