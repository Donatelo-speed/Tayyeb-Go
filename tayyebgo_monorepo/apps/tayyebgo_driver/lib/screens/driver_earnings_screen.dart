import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final user = AuthProvider.instance?.user;
    if (user != null) {
      context.read<DriverWalletProvider>().loadWallet(user.id);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Earnings', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
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
                      Text('No earnings data', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Start delivering to see earnings', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _EarningsSummaryCard(wallet: wallet),
                    const SizedBox(height: 16),
                    _LevelCard(wallet: wallet),
                    const SizedBox(height: 20),
                    TabBar(
                      controller: _tabCtrl,
                      labelColor: context.successColor,
                      unselectedLabelColor: context.textMutedColor,
                      indicatorColor: context.successColor,
                      indicatorWeight: 3,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Today'),
                        Tab(text: 'Week'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Recent Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                    const SizedBox(height: 12),
                    if (walletProv.transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Center(
                          child: Text('No transactions yet', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
                        ),
                      )
                    else
                      ...walletProv.transactions.map((txn) => _TransactionCard(txn: txn)),
                  ],
                ),
    );
  }
}

class _EarningsSummaryCard extends StatelessWidget {
  final DriverWalletModel wallet;
  const _EarningsSummaryCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Text('Total Earned', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            'SYP ${wallet.totalEarned.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 36, color: context.successColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(context, Icons.account_balance_wallet_rounded, 'Balance', 'SYP ${wallet.balance.toStringAsFixed(0)}'),
              _stat(context, Icons.hourglass_bottom_rounded, 'Pending', 'SYP ${wallet.pendingPayout.toStringAsFixed(0)}'),
              _stat(context, Icons.check_circle_rounded, 'Withdrawn', 'SYP ${wallet.totalWithdrawn.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: context.successColor, size: 20),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
        Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final DriverWalletModel wallet;
  const _LevelCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final nextDeliveries = wallet.deliveriesToNextLevel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _levelColor(wallet.level).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_levelIcon(wallet.level), color: _levelColor(wallet.level), size: 20),
              ),
              const SizedBox(width: 10),
              Text(wallet.level.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
              const Spacer(),
              Text('${wallet.totalDeliveries} deliveries', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
            ],
          ),
          if (wallet.level != DriverLevel.elite) ...[
            const SizedBox(height: 12),
            Text('$nextDeliveries more to ${wallet.nextLevel.displayName}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: wallet.totalDeliveries / wallet.nextLevel.minDeliveries,
                backgroundColor: context.borderColor,
                color: context.successColor,
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _bonusTag(context, Icons.star_rounded, '${wallet.averageRating.toStringAsFixed(1)} avg'),
              const SizedBox(width: 8),
              _bonusTag(context, Icons.local_fire_department_rounded, '${wallet.currentStreak} day streak'),
            ],
          ),
        ],
      ),
    );
  }

  IconData _levelIcon(DriverLevel l) => switch (l) {
        DriverLevel.bronze => Icons.emoji_events_rounded,
        DriverLevel.silver => Icons.emoji_events_rounded,
        DriverLevel.gold => Icons.emoji_events_rounded,
        DriverLevel.elite => Icons.diamond_rounded,
      };

  Color _levelColor(DriverLevel l) => switch (l) {
        DriverLevel.bronze => const Color(0xFFCD7F32),
        DriverLevel.silver => const Color(0xFF9CA3AF),
        DriverLevel.gold => const Color(0xFFF59E0B),
        DriverLevel.elite => const Color(0xFF06B6D4),
      };

  Widget _bonusTag(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.successColor),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.successColor)),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TransactionCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isEarning = txn['type'] == 'earning';
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
              color: isEarning ? context.successColor.withValues(alpha: 0.1) : context.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEarning ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isEarning ? context.successColor : context.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn['description'] as String? ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: context.textPrimaryColor)),
              ],
            ),
          ),
          Text(
            'SYP ${(txn['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isEarning ? context.successColor : context.warningColor,
            ),
          ),
        ],
      ),
    );
  }
}
