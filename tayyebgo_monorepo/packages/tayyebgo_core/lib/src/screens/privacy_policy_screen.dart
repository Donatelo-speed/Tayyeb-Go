import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: Text('Privacy Policy', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Last updated', 'June 2026'),
          const SizedBox(height: 20),
          _section('1. Information We Collect', 'We collect information you provide directly:\n\n• Account information (name, email, phone number)\n• Delivery addresses\n• Payment information (processed securely via Stripe)\n• Order history and preferences\n• Device information and usage data'),
          _section('2. How We Use Your Information', 'We use your information to:\n\n• Process and deliver orders\n• Communicate about orders and promotions\n• Improve our services and user experience\n• Ensure platform safety and prevent fraud\n• Comply with legal obligations'),
          _section('3. Information Sharing', 'We share your information with:\n\n• Restaurants: Order details and delivery address\n• Drivers: Delivery address and contact info for order fulfillment\n• Payment processors: Secure payment handling\n• Legal authorities: When required by law'),
          _section('4. Data Security', 'We implement industry-standard security measures including encryption, secure servers, and regular security audits to protect your personal information.'),
          _section('5. Your Rights', 'You have the right to:\n\n• Access your personal data\n• Request correction of inaccurate data\n• Request deletion of your data\n• Opt out of marketing communications\n• Export your data'),
          _section('6. Children\'s Privacy', 'TayyebGo is not intended for children under 13. We do not knowingly collect personal information from children.'),
          _section('7. Changes to This Policy', 'We may update this policy from time to time. We will notify you of significant changes via email or in-app notification.'),
          _section('8. Contact Us', 'For privacy-related inquiries, contact us at:\n\nEmail: privacy@tayyebgo.com\nPhone: +963 11 234 5678'),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
