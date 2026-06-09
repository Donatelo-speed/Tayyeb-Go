import 'dart:async';
import 'package:flutter/material.dart';
import '../../infrastructure/services/connectivity_service.dart';
import '../../presentation/shared_widgets/brand_logo.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_typography.dart';

class AppLoadingScreen extends StatefulWidget {
  final VoidCallback? onReady;
  const AppLoadingScreen({super.key, this.onReady});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  bool _isOnline = true;
  bool _checking = true;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final svc = ConnectivityService.instance;
    svc.init();
    _isOnline = svc.isOnline;

    _connectivitySub = svc.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _checking = false);
      if (_isOnline) {
        widget.onReady?.call();
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return _buildLoadingView();
    }
    if (!_isOnline) {
      return _buildNoInternetView();
    }
    return _buildLoadingView();
  }

  Widget _buildLoadingView() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF0F1713), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(markSize: 72, fontSize: 24),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _pulse,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoInternetView() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF0F1713), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Internet Connection',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your network settings and try again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _checking = true);
                      await Future.delayed(const Duration(milliseconds: 500));
                      final online = ConnectivityService.instance.isOnline;
                      if (mounted) {
                        setState(() {
                          _isOnline = online;
                          _checking = false;
                        });
                        if (online) widget.onReady?.call();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
