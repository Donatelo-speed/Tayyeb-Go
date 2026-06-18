import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 640;
    final isTablet = w >= 640 && w < 1024;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), AppColors.background],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavBar(context: context, isMobile: isMobile),
              _HeroSection(isMobile: isMobile, isTablet: isTablet),
              _StatsBar(isMobile: isMobile),
              _HowItWorks(isMobile: isMobile),
              _FeaturesSection(isMobile: isMobile),
              _TestimonialsSection(isMobile: isMobile),
              _JoinSection(isMobile: isMobile),
              _DownloadCTA(context: context, isMobile: isMobile),
              _Footer(context: context, isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NAV BAR ───────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final BuildContext context;
  final bool isMobile;
  const _NavBar({required this.context, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 56, vertical: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink('Features', () => _scrollToKey('features')),
              _NavLink('How It Works', () => _scrollToKey('how-it-works')),
              _NavLink('Driver App', () => context.go('/driver-application')),
              _NavLink('Partner App', () => context.go('/partner-application')),
              _NavLink('About', () => context.go('/about')),
              _NavLink('Download', () => context.go('/download')),
              const SizedBox(width: 12),
            ],
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                onPressed: () => _showMobileMenu(context),
              )
            else
              PressScale(
                onTap: () => context.push('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                    borderRadius: AppRadius.brButton,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 2))],
                  ),
                  child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scrollToKey(String key) {
    // Smooth scroll not easily available in pure Flutter web, placeholder
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.brFull)),
            const SizedBox(height: 24),
            _MobileMenuItem('Features', Icons.star_rounded, () { Navigator.pop(ctx); _scrollToKey('features'); }),
            _MobileMenuItem('How It Works', Icons.settings_rounded, () { Navigator.pop(ctx); _scrollToKey('how-it-works'); }),
            _MobileMenuItem('Driver App', Icons.delivery_dining_rounded, () { Navigator.pop(ctx); context.go('/driver-application'); }),
            _MobileMenuItem('Partner App', Icons.store_rounded, () { Navigator.pop(ctx); context.go('/partner-application'); }),
            _MobileMenuItem('About Us', Icons.info_outline_rounded, () { Navigator.pop(ctx); context.go('/about'); }),
            _MobileMenuItem('Download App', Icons.download_rounded, () { Navigator.pop(ctx); context.go('/download'); }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PressScale(
                onTap: () { Navigator.pop(ctx); context.push('/login'); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                    borderRadius: AppRadius.brButton,
                  ),
                  child: Center(child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MobileMenuItem(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── HERO ──────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  const _HeroSection({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final titleSize = isMobile ? 38.0 : isTablet ? 52.0 : 68.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 100),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.brFull,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Now live in Syria', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFB8C0CC), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Deliver Anything.\nFrom Anywhere.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: titleSize, color: Colors.white, height: 1.08),
            ),
          ),
          const SizedBox(height: 28),

          // Subtitle
          Text(
            'Food, groceries, pharmacy, retail — one platform for every delivery vertical.\nBuilt for Syria. Designed for the world.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: isMobile ? 16 : 19, height: 1.7, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 44),

          // CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              PressScale(
                onTap: () => context.push('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                    borderRadius: AppRadius.brButton,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Get Started Free', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              PressScale(
                onTap: () => context.push('/customer/home'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brButton,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text('View Demo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),

          // App mockup placeholder — gradient card showing app UI
          _AppMockupCard(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _AppMockupCard extends StatelessWidget {
  final bool isMobile;
  const _AppMockupCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 720,
      height: isMobile ? 220 : 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceAlt,
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 60, offset: const Offset(0, 20)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Fake app bars
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]), borderRadius: AppRadius.brSm), child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 16)),
                  const SizedBox(width: 10),
                  Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                  const Spacer(),
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: AppRadius.brFull), child: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 16)),
                ],
              ),
            ),
          ),

          // Fake content cards
          Positioned(
            top: 70, left: 20, right: 20,
            child: Column(
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryHover.withValues(alpha: 0.08)]),
                    borderRadius: AppRadius.brCard,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.primary, size: isMobile ? 18 : 22),
                        const SizedBox(width: 10),
                        Text('Search restaurants, groceries, pharmacy...',
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: isMobile ? 13 : 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FakeCategoryChip(icon: Icons.restaurant_rounded, label: 'Food', color: AppColors.primary),
                    const SizedBox(width: 8),
                    _FakeCategoryChip(icon: Icons.local_grocery_store_rounded, label: 'Grocery', color: AppColors.driverAccent),
                    const SizedBox(width: 8),
                    _FakeCategoryChip(icon: Icons.local_pharmacy_rounded, label: 'Pharmacy', color: AppColors.error),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      _FakeCategoryChip(icon: Icons.store_rounded, label: 'Retail', color: AppColors.adminAccent),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Fake restaurant cards
                Row(
                  children: [
                    Expanded(child: _FakeRestaurantCard(name: 'Al-Sham Kitchen', rating: '4.8', time: '25 min', color: AppColors.primary)),
                    const SizedBox(width: 12),
                    if (!isMobile) Expanded(child: _FakeRestaurantCard(name: 'Damascus Sweets', rating: '4.9', time: '15 min', color: AppColors.driverAccent)),
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      Expanded(child: _FakeRestaurantCard(name: 'Fresh Market', rating: '4.7', time: '20 min', color: AppColors.adminAccent)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeCategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FakeCategoryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brFull,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FakeRestaurantCard extends StatelessWidget {
  final String name;
  final String rating;
  final String time;
  final Color color;
  const _FakeRestaurantCard({required this.name, required this.rating, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 28, width: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.brSm), child: Icon(Icons.restaurant_rounded, color: color, size: 14)),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.warning, size: 12),
              const SizedBox(width: 2),
              Text(rating, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
              const SizedBox(width: 2),
              Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── STATS BAR ─────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final bool isMobile;
  const _StatsBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat('10K+', 'Active Users', Icons.people_rounded, AppColors.primary),
      _Stat('500+', 'Restaurants', Icons.restaurant_rounded, AppColors.driverAccent),
      _Stat('200+', 'Delivery Drivers', Icons.delivery_dining_rounded, AppColors.adminAccent),
      _Stat('50K+', 'Orders Delivered', Icons.check_circle_rounded, AppColors.success),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 56),
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: isMobile
          ? Column(children: stats.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _StatItem(stat: s))).toList())
          : Row(children: stats.map((s) => Expanded(child: _StatItem(stat: s))).toList()),
    );
  }
}

class _Stat {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat(this.value, this.label, this.icon, this.color);
}

class _StatItem extends StatelessWidget {
  final _Stat stat;
  const _StatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: stat.color.withValues(alpha: 0.1), borderRadius: AppRadius.brSm),
          child: Icon(stat.icon, color: stat.color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(stat.value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white)),
        const SizedBox(height: 4),
        Text(stat.label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }
}

// ─── HOW IT WORKS ──────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isMobile;
  const _HowItWorks({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('1', 'Browse & Order', 'Choose from hundreds of restaurants, grocery stores, and pharmacies.', Icons.search_rounded, AppColors.primary),
      _Step('2', 'Track Live', 'Watch your order in real-time with GPS tracking and live updates.', Icons.location_on_rounded, AppColors.driverAccent),
      _Step('3', 'Fast Delivery', 'Get it delivered to your door in minutes, not hours.', Icons.bolt_rounded, AppColors.warning),
    ];

    return Container(
      key: const Key('how-it-works'),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      child: Column(
        children: [
          Text('How It Works', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('Three steps to anything you need', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          isMobile
              ? Column(children: steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 32), child: _StepCard(step: s, index: steps.indexOf(s)))).toList())
              : Row(children: steps.map((s) => Expanded(child: _StepCard(step: s, index: steps.indexOf(s)))).toList()),
        ],
      ),
    );
  }
}

class _Step {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _Step(this.number, this.title, this.description, this.icon, this.color);
}

class _StepCard extends StatelessWidget {
  final _Step step;
  final int index;
  const _StepCard({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [step.color, step.color.withValues(alpha: 0.7)]),
                  borderRadius: AppRadius.brSm,
                ),
                child: Center(child: Text(step.number, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white))),
              ),
              const Spacer(),
              Icon(step.icon, color: step.color.withValues(alpha: 0.3), size: 32),
            ],
          ),
          const SizedBox(height: 20),
          Text(step.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 10),
          Text(step.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

// ─── FEATURES ──────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isMobile;
  const _FeaturesSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(Icons.restaurant_rounded, 'Food Delivery', 'Restaurant-quality meals from local favorites, delivered hot and fast.', AppColors.primary),
      _FeatureData(Icons.local_grocery_store_rounded, 'Grocery', 'Fresh produce, dairy, and pantry staples delivered to your door.', AppColors.driverAccent),
      _FeatureData(Icons.local_pharmacy_rounded, 'Pharmacy', 'Medicines and health essentials delivered with care and privacy.', AppColors.error),
      _FeatureData(Icons.store_rounded, 'Retail', 'Any product from local stores, delivered same-day.', AppColors.adminAccent),
      _FeatureData(Icons.delivery_dining_rounded, 'Anything', 'Need something特殊? Send anything, anywhere in the city.', AppColors.warning),
      _FeatureData(Icons.shield_rounded, 'Safe & Secure', 'Verified drivers, real-time tracking, and secure payments.', AppColors.success),
    ];

    return Container(
      key: const Key('features'),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15)), bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
      ),
      child: Column(
        children: [
          Text('Everything You Need', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('One platform for every delivery vertical', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          isMobile
              ? Column(children: features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _FeatureCard(data: f))).toList())
              : GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: features.map((f) => _FeatureCard(data: f)).toList(),
                ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _FeatureData(this.icon, this.title, this.description, this.color);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return HoverElevation(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [data.color.withValues(alpha: 0.15), data.color.withValues(alpha: 0.05)]),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(data.icon, color: data.color, size: 24),
            ),
            const SizedBox(height: 18),
            Text(data.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(data.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TESTIMONIALS ──────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  final bool isMobile;
  const _TestimonialsSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      _Testimonial('TayyebGo changed how I order food. Fast, reliable, and the tracking is amazing!', 'Ahmad K.', 'Damascus', Icons.star_rounded),
      _Testimonial('As a restaurant owner, this platform doubled my delivery orders in the first month.', 'Fatima H.', 'Aleppo', Icons.star_rounded),
      _Testimonial('Best delivery app in Syria. The driver app makes my routes so much more efficient.', 'Omar S.', 'Homs', Icons.star_rounded),
    ];

    return Container(
      key: const Key('testimonials'),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      child: Column(
        children: [
          Text('Loved by Thousands', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('What our users say about TayyebGo', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          isMobile
              ? Column(children: testimonials.map((t) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _TestimonialCard(data: t))).toList())
              : Row(children: testimonials.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _TestimonialCard(data: t)))).toList()),
        ],
      ),
    );
  }
}

class _Testimonial {
  final String quote;
  final String name;
  final String city;
  final IconData icon;
  const _Testimonial(this.quote, this.name, this.city, this.icon);
}

class _TestimonialCard extends StatelessWidget {
  final _Testimonial data;
  const _TestimonialCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (_) => Icon(Icons.star_rounded, color: AppColors.warning, size: 16)),
          ),
          const SizedBox(height: 16),
          Text(data.quote, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.6, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primaryHover.withValues(alpha: 0.15)]),
                  borderRadius: AppRadius.brFull,
                ),
                child: Center(
                  child: Text(data.name[0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                  Text(data.city, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── DOWNLOAD CTA ──────────────────────────────────────

class _JoinSection extends StatelessWidget {
  final bool isMobile;
  const _JoinSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final roles = [
      _JoinRole(
        icon: Icons.shopping_bag_rounded,
        title: 'Order Food',
        subtitle: 'Browse restaurants, track orders, and get delivery in minutes.',
        color: AppColors.primary,
        cta: 'Start Ordering',
        onTap: () => context.push('/login'),
      ),
      _JoinRole(
        icon: Icons.delivery_dining_rounded,
        title: 'Deliver',
        subtitle: 'Flexible hours, competitive earnings. Join as a driver today.',
        color: AppColors.driverAccent,
        cta: 'Become a Driver',
        onTap: () => context.go('/driver-application'),
      ),
      _JoinRole(
        icon: Icons.store_rounded,
        title: 'Partner Your Restaurant',
        subtitle: 'Reach thousands of new customers and grow your business.',
        color: AppColors.warning,
        cta: 'Partner With Us',
        onTap: () => context.go('/partner-application'),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      child: Column(
        children: [
          Text('Join TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('Three ways to be part of the future of delivery', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          isMobile
              ? Column(children: roles.map((r) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _JoinRoleCard(data: r))).toList())
              : Row(children: roles.map((r) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _JoinRoleCard(data: r)))).toList()),
        ],
      ),
    );
  }
}

class _JoinRole {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String cta;
  final VoidCallback onTap;
  const _JoinRole({required this.icon, required this.title, required this.subtitle, required this.color, required this.cta, required this.onTap});
}

class _JoinRoleCard extends StatelessWidget {
  final _JoinRole data;
  const _JoinRoleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return HoverElevation(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [data.color.withValues(alpha: 0.15), data.color.withValues(alpha: 0.05)]),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(data.icon, color: data.color, size: 26),
            ),
            const SizedBox(height: 20),
            Text(data.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),
            Text(data.subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, height: 1.6)),
            const SizedBox(height: 24),
            PressScale(
              onTap: data.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brButton,
                  border: Border.all(color: data.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(data.cta, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: data.color)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: data.color, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DOWNLOAD CTA ──────────────────────────────────────

class _DownloadCTA extends StatelessWidget {
  final BuildContext context;
  final bool isMobile;
  const _DownloadCTA({required this.context, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 80),
      padding: EdgeInsets.all(isMobile ? 36 : 72),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primaryHover.withValues(alpha: 0.06),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text('Ready to Get Started?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: isMobile ? 26 : 38, color: Colors.white)),
          const SizedBox(height: 16),
          Text('Join thousands of users and businesses across Syria', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: isMobile ? 15 : 18)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              PressScale(
                onTap: () => context.push('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                    borderRadius: AppRadius.brButton,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Text('Create Free Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                ),
              ),
              PressScale(
                onTap: () => context.go('/driver-application'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
                    borderRadius: AppRadius.brButton,
                    boxShadow: [BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Text('Become a Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                ),
              ),
              PressScale(
                onTap: () => context.go('/partner-application'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.warning, Color(0xFFE8960C)]),
                    borderRadius: AppRadius.brButton,
                    boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Text('Partner Your Restaurant', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // App store badges placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AppStoreBadge(label: 'Available on', store: 'App Store', icon: Icons.apple),
              const SizedBox(width: 16),
              _AppStoreBadge(label: 'Get it on', store: 'Google Play', icon: Icons.android),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppStoreBadge extends StatelessWidget {
  final String label;
  final String store;
  final IconData icon;
  const _AppStoreBadge({required this.label, required this.store, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
              Text(store, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── FOOTER ────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final BuildContext context;
  final bool isMobile;
  const _Footer({required this.context, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 40),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]), borderRadius: AppRadius.brSm),
                      child: Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _FooterLink('Driver App', () => context.go('/driver-application')),
                    _FooterLink('Partner App', () => context.go('/partner-application')),
                    _FooterLink('About', () => context.go('/about')),
                    _FooterLink('Download', () => context.go('/download')),
                    _FooterLink('Help', () => context.go('/help-support')),
                    _FooterLink('Privacy', () => context.go('/privacy-policy')),
                    _FooterLink('Terms', () => context.go('/terms-conditions')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('2025 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]), borderRadius: AppRadius.brSm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('2025 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 24),
                _FooterLink('Driver App', () => context.go('/driver-application')),
                _FooterLink('Partner App', () => context.go('/partner-application')),
                _FooterLink('About', () => context.go('/about')),
                _FooterLink('Download', () => context.go('/download')),
                _FooterLink('Help', () => context.go('/help-support')),
                _FooterLink('Privacy', () => context.go('/privacy-policy')),
                _FooterLink('Terms', () => context.go('/terms-conditions')),
              ],
            ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }
}
