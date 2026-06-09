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
  @override
  void initState() {
    super.initState();
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
