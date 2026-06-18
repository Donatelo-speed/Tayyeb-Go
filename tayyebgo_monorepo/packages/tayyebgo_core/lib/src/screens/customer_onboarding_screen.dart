import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final _pages = const [
    _OnboardingData(
      icon: Icons.delivery_dining_rounded,
      title: 'Anything\nDelivered',
      subtitle: 'Need medicine from the pharmacy?\nA package picked up? Anything you need,\ndelivered to your door.',
      color: Color(0xFF2EC4B6),
      gradient: [Color(0xFF0D1117), Color(0xFF0A1F1C)],
    ),
    _OnboardingData(
      icon: Icons.shopping_bag_rounded,
      title: 'Order From\nAnywhere',
      subtitle: 'Browse local stores, restaurants, and shops.\nOrder food, groceries, or anything else —\nall in one app.',
      color: Color(0xFFFF6B35),
      gradient: [Color(0xFF0D1117), Color(0xFF1A1208)],
    ),
    _OnboardingData(
      icon: Icons.gps_fixed_rounded,
      title: 'Track\nEverything',
      subtitle: 'Watch your delivery in real-time on the map.\nKnow exactly when it arrives\nwith accurate ETAs.',
      color: Color(0xFF9B5DE5),
      gradient: [Color(0xFF0D1117), Color(0xFF150D1F)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('customer_onboarding_seen', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 640;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.gradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: TextButton(
                    onPressed: _complete,
                    child: Text('Skip', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated icon
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0).animate(_fadeAnim),
                              child: Container(
                                width: isMobile ? 140 : 180,
                                height: isMobile ? 140 : 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      p.color.withValues(alpha: 0.2),
                                      p.color.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: p.color.withValues(alpha: 0.15), blurRadius: 60, spreadRadius: 10),
                                  ],
                                ),
                                child: Icon(p.icon, size: isMobile ? 64 : 80, color: p.color),
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 48 : 64),

                          // Title
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(_fadeAnim),
                              child: Text(
                                p.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: isMobile ? 32 : 42,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Subtitle
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Text(
                              p.subtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 15 : 17,
                                height: 1.7,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 24 : 40, 0, isMobile ? 24 : 40, isMobile ? 32 : 48),
                child: Row(
                  children: [
                    // Page indicators
                    Row(
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: isActive ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? _pages[_currentPage].color : AppColors.border,
                            borderRadius: AppRadius.brFull,
                            boxShadow: isActive
                                ? [BoxShadow(color: _pages[_currentPage].color.withValues(alpha: 0.3), blurRadius: 8)]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),

                    // Next / Get Started button
                    PressScale(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == _pages.length - 1 ? 160 : 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_pages[_currentPage].color, _pages[_currentPage].color.withValues(alpha: 0.7)],
                          ),
                          borderRadius: AppRadius.brButton,
                          boxShadow: [
                            BoxShadow(
                              color: _pages[_currentPage].color.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentPage == _pages.length - 1) ...[
                              Text('Get Started', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                              const SizedBox(width: 8),
                            ],
                            Icon(
                              _currentPage == _pages.length - 1 ? Icons.arrow_forward_rounded : Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
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
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Color> gradient;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
  });
}
