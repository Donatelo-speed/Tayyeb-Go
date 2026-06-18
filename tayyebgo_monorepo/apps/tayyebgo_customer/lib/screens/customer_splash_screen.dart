import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CustomerSplashScreen extends StatefulWidget {
  const CustomerSplashScreen({super.key});

  @override
  State<CustomerSplashScreen> createState() => _CustomerSplashScreenState();
}

class _CustomerSplashScreenState extends State<CustomerSplashScreen> {
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
      context.go('/home');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('customer_onboarding_seen') ?? false;
      if (!mounted) return;
      if (seenOnboarding) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const BrandedSplashView(
        label: 'Customer',
        tagline: 'Food, errands, and essentials delivered with care.',
        icon: Icons.delivery_dining_rounded,
        accentColor: AppColors.customerAccent,
      );
    }
    return AppLoadingScreen(onReady: _onReady);
  }
}
