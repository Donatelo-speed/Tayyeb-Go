import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerMarketingCenterScreen extends StatelessWidget {
  const PartnerMarketingCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Marketing Center', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statRow([
            _miniStat(context, 'Active Campaigns', '2', context.warningColor),
            _miniStat(context, 'Coupons Used', '47', context.successColor),
            _miniStat(context, 'Redemptions', '128', context.primaryColor),
          ]),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Campaigns', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('New', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: context.warningColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campaignCard(context, 'Welcome Offer', '20% off first order', '156 views', '34 redemptions', true),
          const SizedBox(height: 10),
          _campaignCard(context, 'Weekend Special', 'Free delivery Sat-Sun', '89 views', '12 redemptions', true),
          const SizedBox(height: 10),
          _campaignCard(context, 'Ramadan Deal', 'Iftar combo SYP 3,500', '0 views', '0 redemptions', false),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Coupons', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('New', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: context.warningColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _couponCard(context, 'WELCOME20', '20% off', 'Max 50 uses', '23 used'),
          const SizedBox(height: 10),
          _couponCard(context, 'FREEDEL', 'Free delivery', 'Max 100 uses', '67 used'),
        ],
      ),
    );
  }

  Widget _statRow(List<Widget> children) {
    return Row(
      children: children.map((c) => Expanded(child: c)).toList().expand((w) => [w, const SizedBox(width: 10)]).toList()..removeLast(),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _campaignCard(BuildContext context, String title, String desc, String views, String redemptions, bool active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? context.warningColor.withValues(alpha: 0.3) : context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(views, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
                    const SizedBox(width: 10),
                    Text(redemptions, style: GoogleFonts.inter(color: context.warningColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: active ? context.successColor.withValues(alpha: 0.1) : context.textMutedColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(active ? 'Active' : 'Draft', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: active ? context.successColor : context.textMutedColor)),
          ),
        ],
      ),
    );
  }

  Widget _couponCard(BuildContext context, String code, String discount, String limit, String used) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: context.warningColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(code, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.warningColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(discount, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                Text('$limit · $used', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 20),
        ],
      ),
    );
  }
}
