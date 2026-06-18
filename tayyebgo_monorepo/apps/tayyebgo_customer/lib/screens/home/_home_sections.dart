import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// Header row with location selector and notification bell
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: AnimatedFadeSlide(
            duration: const Duration(milliseconds: 500),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/addresses'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadius.brCard,
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deliver to', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                            Text('Al Hamra, Homs', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedPressScale(
                  onTap: () => context.push('/notifications'),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadius.brCard,
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Icon(Icons.notifications_outlined, color: context.textMutedColor, size: 22)),
                        Positioned(
                          right: 10, top: 10,
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.error, blurRadius: 4, spreadRadius: 1)],
                            ),
                          ),
                        ),
                      ],
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

/// Greeting text with user name
class HomeGreeting extends StatelessWidget {
  final String displayName;
  const HomeGreeting({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: AnimatedFadeSlide(
          delay: 100,
          duration: const Duration(milliseconds: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryHover],
                ).createShader(bounds),
                child: Text(
                  displayName.isNotEmpty ? displayName : 'Guest',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 32, color: Colors.white, letterSpacing: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search bar that navigates to explore
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: AnimatedFadeSlide(
          delay: 200,
          duration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: () => context.push('/explore'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.brCard,
                border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                  const SizedBox(width: 12),
                  Text('Search restaurants, cuisines...', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick category chips row
class HomeCategories extends StatelessWidget {
  final VoidCallback onFoodTap;
  final VoidCallback onGroceryTap;
  final VoidCallback onPharmacyTap;
  final VoidCallback onRetailTap;

  const HomeCategories({
    super.key,
    required this.onFoodTap,
    required this.onGroceryTap,
    required this.onPharmacyTap,
    required this.onRetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: AnimatedFadeSlide(
          delay: 250,
          duration: const Duration(milliseconds: 500),
          child: Row(
            children: [
              _categoryChip(context, Icons.restaurant_rounded, 'Food', AppColors.primary, onFoodTap),
              const SizedBox(width: 10),
              _categoryChip(context, Icons.local_grocery_store_rounded, 'Grocery', AppColors.driverAccent, onGroceryTap),
              const SizedBox(width: 10),
              _categoryChip(context, Icons.local_pharmacy_rounded, 'Pharmacy', AppColors.error, onPharmacyTap),
              const SizedBox(width: 10),
              _categoryChip(context, Icons.store_rounded, 'Retail', AppColors.adminAccent, onRetailTap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: AnimatedPressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppRadius.brCard,
            border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title with gradient accent bar
class HomeSectionTitle extends StatelessWidget {
  final String title;
  final Color gradientStart;
  final Color gradientEnd;
  final Widget? trailing;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.gradientStart = AppColors.primary,
    this.gradientEnd = AppColors.primaryHover,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientStart, gradientEnd],
            ),
            borderRadius: AppRadius.brSm,
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
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
