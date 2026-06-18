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
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedTab = _tabCtrl.index);
      }
    });
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
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final filtered = walletProv.transactions.where((txn) {
                          final ts = txn['timestamp'];
                          if (ts == null) return _selectedTab == 0;
                          DateTime date;
                          if (ts is DateTime) {
                            date = ts;
                          } else if (ts is String) {
                            date = DateTime.tryParse(ts) ?? DateTime(2000);
                          } else {
                            return _selectedTab == 0;
                          }
                          if (_selectedTab == 1) {
                            return date.year == now.year && date.month == now.month && date.day == now.day;
                          } else if (_selectedTab == 2) {
                            final weekAgo = now.subtract(const Duration(days: 7));
                            return date.isAfter(weekAgo);
                          }
                          return true;
                        }).toList();
                        if (filtered.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: AppRadius.brLg,
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Center(
                              child: Text('No transactions for this period', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
                            ),
                          );
                        }
                        return Column(
                          children: filtered.map((txn) => _TransactionCard(txn: txn)).toList(),
                        );
                      },
                    ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.brFull,
        boxShadow: [
          BoxShadow(
            color: AppColors.driverAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Total Earned', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'SYP ${wallet.totalEarned.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 40, color: Colors.white, letterSpacing: 0),
          ),
          const SizedBox(height: 24),
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
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: AppRadius.brMd),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_levelColor(wallet.level), _levelColor(wallet.level).withValues(alpha: 0.7)],
                  ),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(_levelIcon(wallet.level), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.level.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                    Text('${wallet.totalDeliveries} deliveries', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (wallet.level != DriverLevel.elite) ...[
            const SizedBox(height: 16),
            Text('$nextDeliveries more to ${wallet.nextLevel.displayName}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: LinearProgressIndicator(
                value: wallet.totalDeliveries / wallet.nextLevel.minDeliveries,
                backgroundColor: context.borderColor.withValues(alpha: 0.5),
                color: AppColors.driverAccent,
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 16),
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
        borderRadius: AppRadius.brMd,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isEarning
                    ? [AppColors.driverAccent.withValues(alpha: 0.15), AppColors.driverAccent.withValues(alpha: 0.05)]
                    : [AppColors.warning.withValues(alpha: 0.15), AppColors.warning.withValues(alpha: 0.05)],
              ),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(
              isEarning ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isEarning ? AppColors.driverAccent : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['description'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  txn['timestamp'] != null ? _formatDate(txn['timestamp']) : '',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'SYP ${(txn['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isEarning ? AppColors.driverAccent : AppColors.warning,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    DateTime date;
    if (ts is DateTime) {
      date = ts;
    } else if (ts is String) {
      date = DateTime.tryParse(ts) ?? DateTime(2000);
    } else {
      return '';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
