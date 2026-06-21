import 'dart:async';
import 'package:flutter/material.dart';
import '../../infrastructure/services/connectivity_service.dart';
import '../../presentation/shared_widgets/brand_logo.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_gradients.dart';
import '../../presentation/theme/app_typography.dart';
import '../../presentation/theme/app_radius.dart';

class AppLoadingScreen extends StatefulWidget {
  final VoidCallback? onReady;
  const AppLoadingScreen({super.key, this.onReady});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _progressFade;
  late final Animation<Offset> _logoSlide;
  bool _isOnline = true;
  bool _checking = true;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _progressFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _animCtrl.forward();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final svc = ConnectivityService.instance;
    svc.init();
    _isOnline = svc.isOnline;

    _connectivitySub = svc.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _checking = false);
      if (_isOnline) {
        widget.onReady?.call();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
              // Animated logo with glow
              SlideTransition(
                position: _logoSlide,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow orb
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        TayyebGoBrandMark(size: 72, showShadow: true),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Staggered progress indicator + text
              FadeTransition(
                opacity: _progressFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.primaryGradientHorizontal.createShader(bounds),
                      child: Text(
                        'TayyebGo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparing your experience...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
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
                        borderRadius: AppRadius.brMd,
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
