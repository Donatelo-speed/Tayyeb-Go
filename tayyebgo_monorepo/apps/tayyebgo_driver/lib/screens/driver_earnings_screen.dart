import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  @override
  void initState() {
    super.initState();
    final user = AuthProvider.instance?.user;
    if (user != null) {
      context.read<DriverWalletProvider>().loadWallet(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;

    return AppScaffold(
      title: 'Earnings',
      body: walletProv.isLoading
          ? const ShimmerLoading(itemCount: 3)
          : wallet == null
              ? const Center(child: Text('No earnings data'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _EarningsSummaryCard(wallet: wallet),
                    const SizedBox(height: 16),
                    _LevelCard(wallet: wallet),
                    const SizedBox(height: 16),
                    Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...walletProv.transactions.map((txn) => ListTile(
                      dense: true,
                      leading: Icon(
                        txn['type'] == 'earning' ? Icons.arrow_upward : Icons.arrow_downward,
                        color: txn['type'] == 'earning' ? Colors.green : Colors.orange,
                      ),
                      title: Text(txn['description'] as String? ?? ''),
                      trailing: Text(
                        'SYP ${(txn['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: txn['type'] == 'earning' ? Colors.green : Colors.red,
                        ),
                      ),
                    )),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Total Earned', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('SYP ${wallet.totalEarned.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.account_balance_wallet, 'Balance', 'SYP ${wallet.balance.toStringAsFixed(0)}'),
                _stat(Icons.hourglass_bottom, 'Pending', 'SYP ${wallet.pendingPayout.toStringAsFixed(0)}'),
                _stat(Icons.check_circle, 'Withdrawn', 'SYP ${wallet.totalWithdrawn.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: TayyebGoTheme.primaryColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_levelIcon(wallet.level), color: _levelColor(wallet.level)),
                const SizedBox(width: 8),
                Text(wallet.level.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                Text('${wallet.totalDeliveries} deliveries', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (wallet.level != DriverLevel.elite) ...[
              const SizedBox(height: 8),
              Text('$nextDeliveries more deliveries to reach ${wallet.nextLevel.displayName}'),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: wallet.totalDeliveries / wallet.nextLevel.minDeliveries,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _bonusTag(Icons.star, '${wallet.averageRating.toStringAsFixed(1)} avg'),
                const SizedBox(width: 12),
                _bonusTag(Icons.local_fire_department, '${wallet.currentStreak} day streak'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _levelIcon(DriverLevel l) => switch (l) {
        DriverLevel.bronze => Icons.emoji_events,
        DriverLevel.silver => Icons.emoji_events,
        DriverLevel.gold => Icons.emoji_events,
        DriverLevel.elite => Icons.diamond,
      };

  Color _levelColor(DriverLevel l) => switch (l) {
        DriverLevel.bronze => Colors.brown,
        DriverLevel.silver => Colors.grey,
        DriverLevel.gold => Colors.amber,
        DriverLevel.elite => Colors.cyan,
      };

  Widget _bonusTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TayyebGoTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TayyebGoTheme.primaryColor),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
