import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.go('/home');
    } else {
      context.go('/login');
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
