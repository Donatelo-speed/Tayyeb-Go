import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// Referral Screen - Invite friends and earn rewards
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Row(
              children: [
                AnimatedPressScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(
                        color: context.borderColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: context.textPrimaryColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Refer & Earn',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Hero Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C42), Color(0xFFFFB347)],
                ),
                borderRadius: AppRadius.brXxl,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                      borderRadius: AppRadius.brXxl,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Give \$3, Get \$3',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your code with friends.\nThey get \$3 off their first order.\nYou get \$3 when they order!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Referral Code
            Text(
              'Your Referral Code',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'TAYYEB-DIANA'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Code copied!', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.brLg,
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referral Code',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TAYYEB-DIANA',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Share buttons
            Row(
              children: [
                Expanded(
                  child: AnimatedPressScale(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'WhatsApp',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedPressScale(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                          color: context.borderColor.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, color: context.textPrimaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Share',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // How it works
            Text(
              'How It Works',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _stepItem(context, '1', 'Share your code', 'Send your referral code to friends'),
            _stepItem(context, '2', 'Friend orders', 'They get \$3 off their first order'),
            _stepItem(context, '3', 'You earn', 'You get \$3 credit when they complete'),
            const SizedBox(height: 24),
            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.brLg,
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  _statColumn(context, '0', 'Friends Referred'),
                  _statColumn(context, '\$0', 'Earned So Far'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepItem(BuildContext context, String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryHover],
              ),
              borderRadius: AppRadius.brMd,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
