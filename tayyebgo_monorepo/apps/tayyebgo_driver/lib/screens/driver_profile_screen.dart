import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Driver';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            // Header
            AnimatedFadeSlide(
              duration: const Duration(milliseconds: 500),
              child: Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: context.textPrimaryColor,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar Card
            AnimatedFadeSlide(
              delay: 100,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.driverAccent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 32, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white, letterSpacing: 0),
                    ),
                    const SizedBox(height: 4),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Platform Driver',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Account Section
            AnimatedFadeSlide(
              delay: 200,
              duration: const Duration(milliseconds: 500),
              child: TGSection(title: 'Account', color: AppColors.driverAccent),
            ),
            const SizedBox(height: 12),
            AnimatedFadeSlide(
              delay: 250,
              duration: const Duration(milliseconds: 500),
              child: TGListItem(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.driverAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.person_rounded, color: AppColors.driverAccent, size: 20)),
                title: 'Personal Information',
                onTap: () => context.push('/edit-profile'),
              ),
            ),
            AnimatedFadeSlide(
              delay: 275,
              duration: const Duration(milliseconds: 500),
              child: TGListItem(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.driverAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.directions_car_rounded, color: AppColors.driverAccent, size: 20)),
                title: 'Vehicle Details',
                onTap: () => context.push('/edit-profile'),
              ),
            ),
            AnimatedFadeSlide(
              delay: 300,
              duration: const Duration(milliseconds: 500),
              child: TGListItem(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.driverAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.badge_rounded, color: AppColors.driverAccent, size: 20)),
                title: 'Documents',
                onTap: () => context.push('/documents'),
              ),
            ),
            AnimatedFadeSlide(
              delay: 325,
              duration: const Duration(milliseconds: 500),
              child: TGListItem(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.driverAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.history_rounded, color: AppColors.driverAccent, size: 20)),
                title: 'Delivery History',
                onTap: () => context.push('/delivery-history'),
              ),
            ),
            const SizedBox(height: 24),
            // Preferences Section
            AnimatedFadeSlide(
              delay: 350,
              duration: const Duration(milliseconds: 500),
              child: _sectionHeader(context, 'Preferences'),
            ),
            const SizedBox(height: 12),
            AnimatedFadeSlide(
              delay: 375,
              duration: const Duration(milliseconds: 500),
              child: _menuItem(context, Icons.language_rounded, 'Language', () => context.push('/settings')),
            ),
            AnimatedFadeSlide(
              delay: 400,
              duration: const Duration(milliseconds: 500),
              child: _menuItem(context, Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
            ),
            AnimatedFadeSlide(
              delay: 425,
              duration: const Duration(milliseconds: 500),
              child: _menuItem(context, Icons.lock_outline_rounded, 'Change Password', () => context.push('/forgot-password')),
            ),
            const SizedBox(height: 24),
            // Support Section
            AnimatedFadeSlide(
              delay: 450,
              duration: const Duration(milliseconds: 500),
              child: _sectionHeader(context, 'Support'),
            ),
            const SizedBox(height: 12),
            AnimatedFadeSlide(
              delay: 475,
              duration: const Duration(milliseconds: 500),
              child: _menuItem(context, Icons.help_outline_rounded, 'Help Center', () => context.push('/help-support')),
            ),
            AnimatedFadeSlide(
              delay: 500,
              duration: const Duration(milliseconds: 500),
              child: _menuItem(context, Icons.shield_rounded, 'Safety Hub', () => context.push('/safety')),
            ),
            AnimatedFadeSlide(
              delay: 525,
              duration: const Duration(milliseconds: 500),
              child: _menuItem(context, Icons.info_outline_rounded, 'About', () => context.push('/help-support')),
            ),
            const SizedBox(height: 24),
            // Sign Out
            AnimatedFadeSlide(
              delay: 550,
              duration: const Duration(milliseconds: 500),
              child: AnimatedPressScale(
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: context.textPrimaryColor,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return AnimatedPressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.driverAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.driverAccent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
