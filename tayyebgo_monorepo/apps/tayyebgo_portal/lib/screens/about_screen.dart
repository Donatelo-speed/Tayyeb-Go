import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              _MissionSection(isMobile: isMobile),
              _StorySection(isMobile: isMobile, isTablet: isTablet),
              _ValuesSection(isMobile: isMobile),
              _TeamSection(isMobile: isMobile),
              _CTASection(isMobile: isMobile),
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
              _NavLink('Features', () => context.go('/')),
              _NavLink('Driver App', () => context.go('/driver-application')),
              _NavLink('Partner App', () => context.go('/partner-application')),
              _NavLink('Support', () => context.go('/help-support')),
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
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 96),
      child: Column(
        children: [
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
                Text('Founded in Homs, Syria', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFB8C0CC), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Built for Syria.\nDesigned for the World.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: isMobile ? 36 : isTablet ? 50 : 64, color: Colors.white, height: 1.08),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'We started with a simple belief: everyone in Syria deserves access to everything in their city.\nFrom food to pharmacy to retail — one platform to deliver it all.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: isMobile ? 16 : 19, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ─── MISSION ───────────────────────────────────────────

class _MissionSection extends StatelessWidget {
  final bool isMobile;
  const _MissionSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      padding: EdgeInsets.all(isMobile ? 32 : 56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryHover.withValues(alpha: 0.04),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_objects_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 24),
          Text('Our Mission', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: isMobile ? 24 : 32, color: Colors.white)),
          const SizedBox(height: 16),
          Text(
            'To build the most reliable delivery infrastructure in Syria and the MENA region — connecting people with the things they need, when they need them, delivered with care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: isMobile ? 16 : 18, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ─── STORY ─────────────────────────────────────────────

class _StorySection extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  const _StorySection({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      child: isMobile
          ? Column(children: [
              _StoryTimeline(isVertical: true),
            ])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StoryTimeline(isVertical: false)),
              ],
            ),
    );
  }
}

class _StoryTimeline extends StatelessWidget {
  final bool isVertical;
  const _StoryTimeline({required this.isVertical});

  @override
  Widget build(BuildContext context) {
    final milestones = [
      _Milestone('2024', 'The Idea', 'Founded in Homs with a vision to solve last-mile delivery in Syria.'),
      _Milestone('2025', 'Launch', 'Launched TayyebGo with food delivery across 3 Syrian cities.'),
      _Milestone('Q3 2025', 'Expansion', 'Added grocery, pharmacy, and retail delivery verticals.'),
      _Milestone('2026', 'Scale', 'Expanding to all major Syrian cities and launching partner platform.'),
      _Milestone('Future', 'Vision', 'Becoming the MENA region\'s leading multi-vertical delivery platform.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Our Journey', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: Colors.white)),
        const SizedBox(height: 12),
        Text('From a small city in Syria to a platform for everyone', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
        const SizedBox(height: 40),
        ...milestones.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: _MilestoneCard(data: m),
        )),
      ],
    );
  }
}

class _Milestone {
  final String year;
  final String title;
  final String description;
  const _Milestone(this.year, this.title, this.description);
}

class _MilestoneCard extends StatelessWidget {
  final _Milestone data;
  const _MilestoneCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 60, color: AppColors.primary.withValues(alpha: 0.2)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.year, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(data.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 8),
              Text(data.description, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── VALUES ────────────────────────────────────────────

class _ValuesSection extends StatelessWidget {
  final bool isMobile;
  const _ValuesSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final values = [
      _Value(Icons.favorite_rounded, 'Care', 'Every delivery is personal. We treat every order like it\'s for our own family.', AppColors.error),
      _Value(Icons.bolt_rounded, 'Speed', 'Fast is not optional. We optimize every step for maximum efficiency.', AppColors.warning),
      _Value(Icons.shield_rounded, 'Trust', 'Safety and security at every touchpoint — for customers, drivers, and partners.', AppColors.driverAccent),
      _Value(Icons.lightbulb_rounded, 'Innovation', 'We build technology that adapts to Syria\'s unique challenges and opportunities.', AppColors.adminAccent),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15)), bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
      ),
      child: Column(
        children: [
          Text('What We Stand For', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('Core values that guide everything we build', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          isMobile
              ? Column(children: values.map((v) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _ValueCard(data: v))).toList())
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: values.map((v) => _ValueCard(data: v)).toList(),
                ),
        ],
      ),
    );
  }
}

class _Value {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _Value(this.icon, this.title, this.description, this.color);
}

class _ValueCard extends StatelessWidget {
  final _Value data;
  const _ValueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
                const SizedBox(height: 6),
                Text(data.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TEAM ──────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  final bool isMobile;
  const _TeamSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 64 : 96),
      child: Column(
        children: [
          Text('Built by a Passionate Team', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isMobile ? 26 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text('A team of engineers, designers, and operators committed to transforming delivery in Syria', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 56),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _TeamMember('Diana', 'Founder & CEO', Icons.person_rounded, AppColors.primary),
              _TeamMember('Ahmad', 'CTO', Icons.code_rounded, AppColors.driverAccent),
              _TeamMember('Fatima', 'Head of Operations', Icons.group_rounded, AppColors.adminAccent),
              _TeamMember('Omar', 'Lead Engineer', Icons.devices_rounded, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final IconData icon;
  final Color color;
  const _TeamMember(this.name, this.role, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 4),
          Text(role, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── CTA ───────────────────────────────────────────────

class _CTASection extends StatelessWidget {
  final bool isMobile;
  const _CTASection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 32 : 64),
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
          Text('Join the TayyebGo Family', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: isMobile ? 24 : 36, color: Colors.white)),
          const SizedBox(height: 16),
          Text('Whether you\'re ordering, delivering, or running a restaurant — there\'s a place for you.', textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: isMobile ? 15 : 18)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              PressScale(
                onTap: () => context.go('/driver-application'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
                    borderRadius: AppRadius.brButton,
                  ),
                  child: Text('Become a Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                ),
              ),
              PressScale(
                onTap: () => context.go('/partner-application'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.warning, Color(0xFFE8960C)]),
                    borderRadius: AppRadius.brButton,
                  ),
                  child: Text('Partner Your Restaurant', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                ),
              ),
              PressScale(
                onTap: () => context.push('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brButton,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Text('Start Ordering', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                ),
              ),
            ],
          ),
        ],
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
