import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> {
  bool _ready = false;

  void _onReady() {
    if (_ready || !mounted) return;
    setState(() => _ready = true);
    _waitForAuth();
  }

  Future<void> _waitForAuth() async {
    final auth = context.read<AuthProvider>();
    var waited = 0;
    while (auth.isInitializing && mounted && waited < 15000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    if (!mounted) return;
    _navigate(auth);
  }

  Future<void> _navigate(AuthProvider auth) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (auth.user != null) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const BrandedSplashView(
        label: 'Admin',
        tagline: 'Live operations, approvals, finance, and platform health.',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: AppColors.adminAccent,
      );
    }
    return AppLoadingScreen(onReady: _onReady);
  }
}
