import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CustomerWalletScreen extends StatelessWidget {
  const CustomerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id ?? '';

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
          _buildBalanceCard(context, userId),
          const SizedBox(height: 28),
          Text('Recent Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          _buildTransactionsList(context, userId),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final balance = (data?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final coinBalance = (data?['loyaltyCoins'] as num?)?.toInt() ?? 0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.primaryColor,
                context.primaryColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 36, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.stars_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text('$coinBalance loyalty coins', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _walletAction(context, Icons.add_rounded, 'Top Up', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Top up coming soon', style: GoogleFonts.inter()),
                        backgroundColor: context.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  _walletAction(context, Icons.send_rounded, 'Send', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Send money coming soon', style: GoogleFonts.inter()),
                        backgroundColor: context.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  _walletAction(context, Icons.history_rounded, 'History', () {}),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _walletAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load transactions', style: GoogleFonts.inter(color: context.textMutedColor)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.primaryColor));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined, size: 32, color: context.textMutedColor),
                  ),
                  const SizedBox(height: 16),
                  Text('No transactions yet', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Your payment history will appear here', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] as String? ?? 'unknown';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final description = data['description'] as String? ?? '';
            final timestamp = data['createdAt'] as Timestamp?;
            final date = timestamp?.toDate();

            final isCredit = type == 'credit' || type == 'topup' || type == 'refund';
            final icon = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
            final color = isCredit ? context.successColor : context.errorColor;
            final sign = isCredit ? '+' : '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description.isNotEmpty ? description : (isCredit ? 'Top Up' : 'Payment'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor),
                        ),
                        if (date != null)
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$sign\$${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
