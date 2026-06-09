import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerSplashScreen extends StatefulWidget {
  const PartnerSplashScreen({super.key});

  @override
  State<PartnerSplashScreen> createState() => _PartnerSplashScreenState();
}

class _PartnerSplashScreenState extends State<PartnerSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedSplashView(
      label: 'Partner',
      tagline: 'Kitchen, menu, marketing, and dispatch in one place.',
      icon: Icons.storefront_rounded,
      accentColor: AppColors.partnerAccent,
    );
  }
}
