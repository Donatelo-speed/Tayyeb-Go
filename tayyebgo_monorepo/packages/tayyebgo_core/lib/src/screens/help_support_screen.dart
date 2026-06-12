import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help & Support', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header('Get Help'),
          const SizedBox(height: 16),
          _faqItem(context, 'How do I track my order?',
              'Once your order is placed, go to the Orders tab and tap on the active order. You can see real-time status updates and driver location.'),
          _faqItem(context, 'How do I cancel an order?',
              'Open your active order and tap "Cancel Order". You can cancel before the restaurant accepts the order for a full refund.'),
          _faqItem(context, 'How do I request a refund?',
              'Go to Order History, select the order, and tap "Report Issue". Describe the problem and our team will review within 24 hours.'),
          _faqItem(context, 'How do I change my delivery address?',
              'Go to Profile > Addresses to add, edit, or remove delivery addresses.'),
          _faqItem(context, 'How do I apply a promo code?',
              'At checkout, tap "Apply Promo Code" and enter your code. The discount will be applied to your order total.'),
          _faqItem(context, 'How do I become a driver?',
              'Download the TayyebGo Driver app, create an account, and complete the onboarding process. You\'ll need a valid driver\'s license and vehicle registration.'),
          const SizedBox(height: 32),
          _header('Contact Us'),
          const SizedBox(height: 16),
          _contactTile(
            context,
            icon: Icons.email_rounded,
            title: 'Email Support',
            subtitle: 'support@tayyebgo.com',
            onTap: () => _launchUrl('mailto:support@tayyebgo.com'),
          ),
          _contactTile(
            context,
            icon: Icons.phone_rounded,
            title: 'Phone Support',
            subtitle: '+963-XXX-XXX-XXX',
            onTap: () => _launchUrl('tel:+9630000000000'),
          ),
          _contactTile(
            context,
            icon: Icons.chat_rounded,
            title: 'WhatsApp',
            subtitle: 'Chat with us',
            onTap: () => _launchUrl('https://wa.me/9630000000000'),
          ),
          const SizedBox(height: 32),
          _header('Operating Hours'),
          const SizedBox(height: 8),
          Text(
            'Customer Support: 24/7\nPhone Support: 9:00 AM - 11:00 PM (Damascus Time)',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) {
    return Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary));
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(question, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textMuted,
            children: [Text(answer, style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppColors.textSecondary))],
          ),
        ),
      ),
    );
  }

  Widget _contactTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
