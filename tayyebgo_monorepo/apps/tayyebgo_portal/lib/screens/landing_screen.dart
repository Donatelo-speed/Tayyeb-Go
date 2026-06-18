import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// Public landing page for TayyebGo — shown before authentication.
/// Hero, features, download CTAs, and social proof.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 640;
    final isTablet = w >= 640 && w < 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sidebarBg, const Color(0xFF0D1117)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNavBar(context, isMobile),
              _buildHero(context, isMobile, isTablet),
              _buildFeatures(context, isMobile),
              _buildDownloadCTA(context, isMobile),
              _buildFooter(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, bool isMobile) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                borderRadius: AppRadius.brSm,
              ),
              child: Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
            ),
            const Spacer(),
            if (!isMobile) ...[
              _navLink('Features', () {}),
              _navLink('Pricing', () {}),
              _navLink('Support', () {}),
              const SizedBox(width: 16),
            ],
            PressScale(
              onTap: () => context.push('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.brButton,
                ),
                child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 36.0 : isTablet ? 48.0 : 64.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: isMobile ? 48 : 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.brFull,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text('Multi-vertical delivery platform', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Color(0xFFB0B8C4)]).createShader(bounds),
            child: Text(
              'Deliver anything.\nFrom anywhere.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: titleSize, color: Colors.white, height: 1.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Food, groceries, pharmacy, retail — one platform for all your delivery needs.\nBuilt for Syria, designed for the world.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: isMobile ? 16 : 18, height: 1.6),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PressScale(
                onTap: () => context.push('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                    borderRadius: AppRadius.brButton,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Text('Get Started Free', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                PressScale(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brButton,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('View Demo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context, bool isMobile) {
    final features = [
      _Feature(Icons.restaurant_rounded, 'Food Delivery', 'Restaurant-quality meals delivered fast', AppColors.primary),
      _Feature(Icons.local_grocery_store_rounded, 'Grocery', 'Fresh groceries at your doorstep', AppColors.driverAccent),
      _Feature(Icons.local_pharmacy_rounded, 'Pharmacy', 'Medicines delivered with care', AppColors.error),
      _Feature(Icons.store_rounded, 'Retail', 'Any product, delivered same-day', AppColors.adminAccent),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: 64),
      child: Column(
        children: [
          Text('One platform, every vertical', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 24 : 32, color: Colors.white)),
          const SizedBox(height: 12),
          Text('Why use 4 apps when one does it all?', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features.map((f) => _buildFeatureCard(context, f, isMobile)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _Feature f, bool isMobile) {
    final cardWidth = isMobile ? 280.0 : 240.0;
    return HoverElevation(
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: f.color.withValues(alpha: 0.1),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(f.icon, color: f.color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(f.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 8),
            Text(f.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadCTA(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: 64),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 32 : 64),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryHover.withValues(alpha: 0.08)],
          ),
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('Ready to get started?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 24 : 32, color: Colors.white)),
            const SizedBox(height: 16),
            Text('Join thousands of users across Syria', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 32),
            PressScale(
              onTap: () => context.push('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                  borderRadius: AppRadius.brButton,
                ),
                child: Text('Create Free Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: 32),
      child: Column(
        children: [
          Divider(color: AppColors.border.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          isMobile
              ? Column(
                  children: [
                    Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('2024 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2024 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                    Row(
                      children: [
                        _footerLink('Privacy Policy', () => context.push('/privacy-policy')),
                        _footerLink('Terms', () => context.push('/terms-conditions')),
                        _footerLink('Help', () => context.push('/help-support')),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _Feature(this.icon, this.title, this.description, this.color);
}
