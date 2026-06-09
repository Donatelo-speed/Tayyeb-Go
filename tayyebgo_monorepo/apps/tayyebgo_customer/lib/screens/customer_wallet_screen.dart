import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CustomerWalletScreen extends StatelessWidget {
  const CustomerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance', style: GoogleFonts.inter(color: context.textPrimaryColor.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 8),
                Text('SYP 0', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 36, color: context.textPrimaryColor)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _walletAction(context, Icons.add_rounded, 'Top Up'),
                    const SizedBox(width: 12),
                    _walletAction(context, Icons.send_rounded, 'Send'),
                    const SizedBox(width: 12),
                    _walletAction(context, Icons.history_rounded, 'History'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Recent Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 56, color: context.surfaceAltColor),
                  const SizedBox(height: 12),
                  Text('No transactions yet', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletAction(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.textPrimaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.textPrimaryColor, size: 22),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor)),
          ],
        ),
      ),
    );
  }
}
