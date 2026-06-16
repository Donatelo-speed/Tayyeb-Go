import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});
  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  final _amountCtrl = TextEditingController();
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = AuthProvider.instance?.user;
      if (user != null) {
        context.read<DriverWalletProvider>().loadWallet(user.id);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: walletProv.isLoading
          ? Center(child: CircularProgressIndicator(color: context.successColor))
          : wallet == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, size: 36, color: context.textMutedColor),
                      ),
                      const SizedBox(height: 16),
                      Text('No wallet data', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _BalanceCard(wallet: wallet),
                    const SizedBox(height: 16),
                    if (wallet.availableBalance > 0)
                      _PayoutSection(
                        walletProv: walletProv,
                        maxAmount: wallet.availableBalance,
                        amountCtrl: _amountCtrl,
                        isRequesting: _isRequesting,
                        onRequest: _requestPayout,
                      ),
                  ],
                ),
    );
  }

  Future<void> _requestPayout(DriverWalletProvider prov, double maxAmount) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0 || amount > maxAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid amount', style: GoogleFonts.inter()),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }
    setState(() => _isRequesting = true);
    try {
      final amountInCents = (amount * 100).round();
      final result = await StripeCheckoutService.requestDriverPayout(
        amountInCents: amountInCents,
        payoutMethod: 'bank_transfer',
      );
      if (!mounted) return;
      setState(() => _isRequesting = false);
      _amountCtrl.clear();
      if (result.success) {
        final uid = AuthProvider.instance?.user?.id;
        if (uid != null) prov.loadWallet(uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payout requested successfully', style: GoogleFonts.inter()),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Request failed', style: GoogleFonts.inter()),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.inter()),
          backgroundColor: context.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _BalanceCard extends StatelessWidget {
  final DriverWalletModel wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0D3320), context.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.successColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('Available Balance', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            'SYP ${wallet.availableBalance.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 40, color: context.successColor),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _levelColor(wallet.level).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              wallet.level.displayName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: _levelColor(wallet.level)),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(DriverLevel l) => switch (l) {
        DriverLevel.bronze => const Color(0xFFCD7F32),
        DriverLevel.silver => const Color(0xFF9CA3AF),
        DriverLevel.gold => const Color(0xFFF59E0B),
        DriverLevel.elite => const Color(0xFF06B6D4),
      };
}

class _PayoutSection extends StatelessWidget {
  final DriverWalletProvider walletProv;
  final double maxAmount;
  final TextEditingController amountCtrl;
  final bool isRequesting;
  final Future<void> Function(DriverWalletProvider, double) onRequest;

  const _PayoutSection({
    required this.walletProv,
    required this.maxAmount,
    required this.amountCtrl,
    required this.isRequesting,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Payout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                prefixIcon: Icon(Icons.monetization_on_rounded, size: 20, color: context.textMutedColor),
                suffixText: 'Max: ${maxAmount.toStringAsFixed(0)}',
                suffixStyle: GoogleFonts.inter(color: context.successColor, fontSize: 12, fontWeight: FontWeight.w600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isRequesting ? null : () => onRequest(walletProv, maxAmount),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isRequesting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Request Payout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
