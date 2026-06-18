import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

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
            children: [
              _NavBar(isMobile: isMobile),
              _HeroSection(isMobile: isMobile, isTablet: isTablet),
              _AppShowcase(isMobile: isMobile, isTablet: isTablet),
              _FeatureHighlights(isMobile: isMobile),
              _Footer(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NAV BAR ───────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final bool isMobile;
  const _NavBar({required this.isMobile});

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
              _NavLink('Driver App', () => context.go('/driver-application')),
              _NavLink('Partner App', () => context.go('/partner-application')),
              _NavLink('About', () => context.go('/about')),
              const SizedBox(width: 12),
            ],
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

// ─── HERO ──────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  const _HeroSection({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 80),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Download TayyebGo',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: isMobile ? 36 : isTablet ? 50 : 64, color: Colors.white, height: 1.08),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your city, your deliveries, your way.\nAvailable on iOS and Android.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: isMobile ? 16 : 19, height: 1.7),
          ),
          const SizedBox(height: 48),

          // Download buttons
          Wrap(
            spacing: 20,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _StoreBadge(
                icon: Icons.apple,
                label: 'Download on the',
                store: 'App Store',
                onTap: () {},
              ),
              _StoreBadge(
                icon: Icons.android_rounded,
                label: 'Get it on',
                store: 'Google Play',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── APP SHOWCASE ──────────────────────────────────────

class _AppShowcase extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  const _AppShowcase({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceAlt,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 60, offset: const Offset(0, 20)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: isMobile
          ? Column(children: [
              _PhoneMockup(color: AppColors.primary),
              const SizedBox(height: 32),
              _AppDescription(),
            ])
          : Row(
              children: [
                Expanded(child: _PhoneMockup(color: AppColors.primary)),
                const SizedBox(width: 48),
                Expanded(child: _AppDescription()),
              ],
            ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final Color color;
  const _PhoneMockup({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 480,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Status bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('9:41', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Row(children: [
                Icon(Icons.signal_cellular_alt_rounded, color: AppColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Icon(Icons.wifi_rounded, color: AppColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Icon(Icons.battery_full_rounded, color: AppColors.textMuted, size: 12),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          // App header
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: AppRadius.brSm,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brFull,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 8),
                Text('Search...', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Category chips
          Row(
            children: [
              _MiniChip('Food', AppColors.primary),
              const SizedBox(width: 6),
              _MiniChip('Grocery', AppColors.driverAccent),
              const SizedBox(width: 6),
              _MiniChip('Pharmacy', AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          // Fake cards
          _FakeCard('Al-Sham Kitchen', '4.8', '25 min'),
          const SizedBox(height: 8),
          _FakeCard('Damascus Sweets', '4.9', '15 min'),
          const SizedBox(height: 8),
          _FakeCard('Fresh Market', '4.7', '20 min'),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _FakeCard extends StatelessWidget {
  final String name;
  final String rating;
  final String time;
  const _FakeCard(this.name, this.rating, this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.brSm), child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 14)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Icon(Icons.star_rounded, color: AppColors.warning, size: 10),
                const SizedBox(width: 2),
                Text(rating, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 10),
                const SizedBox(width: 2),
                Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
              ]),
            ],
          )),
        ],
      ),
    );
  }
}

class _AppDescription extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Everything you need,\ndelivered in minutes', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 28, color: Colors.white, height: 1.2)),
        const SizedBox(height: 20),
        _FeatureRow(Icons.restaurant_rounded, 'Food from 500+ restaurants', AppColors.primary),
        const SizedBox(height: 12),
        _FeatureRow(Icons.local_grocery_store_rounded, 'Groceries & daily essentials', AppColors.driverAccent),
        const SizedBox(height: 12),
        _FeatureRow(Icons.local_pharmacy_rounded, 'Medicines with privacy', AppColors.error),
        const SizedBox(height: 12),
        _FeatureRow(Icons.store_rounded, 'Any product from local stores', AppColors.adminAccent),
        const SizedBox(height: 12),
        _FeatureRow(Icons.location_on_rounded, 'Real-time GPS tracking', AppColors.success),
        const SizedBox(height: 12),
        _FeatureRow(Icons.payment_rounded, 'Secure & cashless payments', AppColors.warning),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MiniStoreBadge(Icons.apple, 'App Store'),
            _MiniStoreBadge(Icons.android_rounded, 'Google Play'),
          ],
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _FeatureRow(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.brSm), child: Icon(icon, color: color, size: 14)),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }
}

class _MiniStoreBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStoreBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── FEATURE HIGHLIGHTS ────────────────────────────────

class _FeatureHighlights extends StatelessWidget {
  final bool isMobile;
  const _FeatureHighlights({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(Icons.speed_rounded, 'Lightning Fast', 'Average delivery in under 30 minutes', AppColors.primary),
      _FeatureData(Icons.location_searching_rounded, 'Live Tracking', 'Watch your order in real-time on the map', AppColors.driverAccent),
      _FeatureData(Icons.shield_rounded, 'Verified Drivers', 'Every driver is background-checked and rated', AppColors.success),
      _FeatureData(Icons.support_agent_rounded, '24/7 Support', 'Help is always just a tap away', AppColors.adminAccent),
      _FeatureData(Icons.star_rounded, 'Rate & Review', 'Help us improve with your feedback', AppColors.warning),
      _FeatureData(Icons.offline_bolt_rounded, 'Offline Mode', 'Place orders even with poor connectivity', AppColors.error),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
      ),
      child: Column(
        children: [
          Text('Why TayyebGo?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('Built with you in mind', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          isMobile
              ? Column(children: features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _FeatureCard(data: f))).toList())
              : GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(data.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STORE BADGE (Large) ───────────────────────────────

class _StoreBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String store;
  final VoidCallback onTap;
  const _StoreBadge({required this.icon, required this.label, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brButton,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                Text(store, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FOOTER ────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isMobile;
  const _Footer({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 40),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15)))),
      child: isMobile
          ? Column(children: [
              Text('2025 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ])
          : Row(children: [
              Text('2025 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              GestureDetector(onTap: () => context.go('/privacy-policy'), child: Text('Privacy Policy', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
              const SizedBox(width: 20),
              GestureDetector(onTap: () => context.go('/terms-conditions'), child: Text('Terms', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
              const SizedBox(width: 20),
              GestureDetector(onTap: () => context.go('/help-support'), child: Text('Help', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
            ]),
    );
  }
}
