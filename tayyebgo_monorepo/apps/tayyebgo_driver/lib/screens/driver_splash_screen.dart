import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverSplashScreen extends StatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen> {
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
        label: 'Driver',
        tagline: 'Live routes, clear earnings, and safer deliveries.',
        icon: Icons.route_rounded,
        accentColor: AppColors.driverAccent,
      );
    }
    return AppLoadingScreen(onReady: _onReady);
  }
}
