import 'package:flutter/material.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/shared_widgets/animated_button.dart';
import '../../presentation/shared_widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _bgCtrl;
  late final List<AnimationController> _floatCtrls;
  int _page = 0;

  final _slides = const [
    _OnboardingData(
      emoji: '🍽️',
      title: 'Discover\nEndless Flavors',
      subtitle: 'From local gems to global cuisines —\nevery craving, one tap away.',
      gradientColors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    ),
    _OnboardingData(
      emoji: '🚀',
      title: 'Real-Time\nOrder Alchemy',
      subtitle: 'Live tracking, instant updates,\nand precision timing from kitchen to doorstep.',
      gradientColors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    ),
    _OnboardingData(
      emoji: '🎯',
      title: 'Smart Rewards\nThat Stack',
      subtitle: 'Cashback, loyalty tiers, and\npersonalized offers that actually save.',
      gradientColors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
    ),
    _OnboardingData(
      emoji: '✨',
      title: 'Multi-Vertical\nMarketplace',
      subtitle: 'Food, groceries, pharmacies, retail —\none ecosystem, infinite possibilities.',
      gradientColors: [Color(0xFFE65100), Color(0xFFBF360C)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _bgCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _floatCtrls = List.generate(
      _slides.length,
      (i) => AnimationController(
        duration: Duration(milliseconds: 2000 + (i * 400)),
        vsync: this,
      )..repeat(reverse: true),
    );
    _bgCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgCtrl.dispose();
    for (final c in _floatCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _slides[_page].gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildSlides()),
                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_page + 1} / ${_slides.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_page < _slides.length - 1)
            GestureDetector(
              onTap: widget.onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildSlides() {
    return PageView.builder(
      controller: _pageCtrl,
      onPageChanged: (i) => setState(() => _page = i),
      itemCount: _slides.length,
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _floatCtrls[i],
        builder: (_, __) {
          final floatOffset = _floatCtrls[i].value * 8 - 4;
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: _buildSlideCard(i),
          );
        },
      ),
    );
  }

  Widget _buildSlideCard(int i) {
    final data = _slides[i];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
      child: GlassCard(
        tint: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    data.gradientColors.first.withValues(alpha: 0.2),
                    data.gradientColors.last.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(data.emoji, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = _page == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 8,
                        )]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          AnimatedButton(
            height: 54,
            borderRadius: 27,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            onPressed: () {
              if (_page < _slides.length - 1) {
                _pageCtrl.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              } else {
                widget.onComplete();
              }
            },
            child: Text(
              _page < _slides.length - 1 ? 'Continue' : 'Start Your Journey',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  const _OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });
}
