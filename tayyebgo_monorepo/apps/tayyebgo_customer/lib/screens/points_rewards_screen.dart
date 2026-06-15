import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PointsRewardsScreen extends StatelessWidget {
  const PointsRewardsScreen({super.key});

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
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5)),
                    child: Icon(Icons.arrow_back_ios_rounded, color: context.textPrimaryColor, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Points & Rewards', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor, letterSpacing: 0)),
              ],
            ),
            const SizedBox(height: 24),
            // Points balance
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryHover]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Text('Your Points', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('2,450', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 44, color: Colors.white, letterSpacing: 0)),
                  const SizedBox(height: 4),
                  Text('\$24.50 value', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Earn 1 point for every \$1 spent. Redeem 100 points = \$1.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('How to Earn', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
            const SizedBox(height: 16),
            _earnRow(context, Icons.shopping_bag_rounded, 'Place an order', '+1 point per \$1', AppColors.primary),
            _earnRow(context, Icons.star_rounded, 'Leave a review', '+10 points', AppColors.warning),
            _earnRow(context, Icons.person_add_rounded, 'Refer a friend', '+50 points', AppColors.driverAccent),
            _earnRow(context, Icons.check_circle_rounded, 'Complete profile', '+25 points', AppColors.adminAccent),
            const SizedBox(height: 28),
            Text('Redeem Points', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
            const SizedBox(height: 16),
            _redeemRow(context, 'Free Delivery', '100 points', Icons.delivery_dining_rounded),
            _redeemRow(context, '\$1 Off', '100 points', Icons.money_off_rounded),
            _redeemRow(context, '\$5 Off', '450 points', Icons.local_offer_rounded),
            _redeemRow(context, '\$10 Off', '850 points', Icons.card_giftcard_rounded),
          ],
        ),
      ),
    );
  }

  Widget _earnRow(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
            Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          ])),
        ],
      ),
    );
  }

  Widget _redeemRow(BuildContext context, String title, String points, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor))),
          AnimatedPressScale(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Text(points, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
