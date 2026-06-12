import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
        title: Text('Terms & Conditions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Last updated', 'June 2026'),
          const SizedBox(height: 20),
          _section('1. Acceptance of Terms', 'By using TayyebGo, you agree to these Terms & Conditions. If you do not agree, please do not use the app.'),
          _section('2. Service Description', 'TayyebGo is a multi-vertical delivery platform connecting customers with restaurants, grocery stores, pharmacies, and other businesses. We facilitate ordering, delivery, and payment processing.'),
          _section('3. User Accounts', 'You must be at least 13 years old to create an account. You are responsible for maintaining the security of your account and all activities under your account.'),
          _section('4. Orders & Payments', '• All prices include applicable taxes unless stated otherwise\n• Payment is processed at the time of order placement\n• Delivery fees vary by distance and demand\n• Tips are voluntary and go directly to drivers'),
          _section('5. Cancellation & Refunds', '• Orders can be cancelled before restaurant acceptance for a full refund\n• After preparation begins, cancellation may result in partial charges\n• Refund requests for quality issues are reviewed within 24 hours\n• Credits are applied to your TayyebGo wallet'),
          _section('6. Delivery', 'Estimated delivery times are approximate. TayyebGo is not liable for delays caused by weather, traffic, or other unforeseen circumstances.'),
          _section('7. Prohibited Conduct', 'You may not:\n• Use the app for illegal purposes\n• Attempt to gain unauthorized access to any part of the app\n• Harass drivers, restaurants, or other users\n• Create fake accounts or place fraudulent orders'),
          _section('8. Intellectual Property', 'All content, trademarks, and technology in TayyebGo are owned by TayyebGo and protected by applicable intellectual property laws.'),
          _section('9. Limitation of Liability', 'TayyebGo provides the platform "as is" and is not liable for the quality of food, actions of third-party restaurants or drivers, or indirect damages.'),
          _section('10. Governing Law', 'These terms are governed by the laws of the Syrian Arab Republic. Any disputes shall be resolved in the courts of Homs, Syria.'),
          _section('11. Contact', 'For questions about these terms:\n\nEmail: legal@tayyebgo.com\nPhone: +963-XXX-XXX-XXX'),
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
