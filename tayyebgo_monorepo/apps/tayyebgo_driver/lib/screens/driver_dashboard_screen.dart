import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isOnline = false;
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;

    return AppScaffold(
      title: 'Driver Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OnlineToggle(
            isOnline: _isOnline,
            isToggling: _isToggling,
            onToggle: _toggleOnline,
          ),
          const SizedBox(height: 16),
          if (wallet != null) _WalletSummary(wallet: wallet),
          const SizedBox(height: 16),
          _QuickActions(),
          const SizedBox(height: 16),
          _ActiveOrderCard(),
          const SizedBox(height: 12),
          _EarningsTodayCard(wallet: wallet),
        ],
      ),
    );
  }

  Future<void> _toggleOnline() async {
    setState(() => _isToggling = true);
    final newState = !_isOnline;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('driver_locations').doc(userId).set({
        'isOnline': newState,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (!mounted) return;
    setState(() {
      _isOnline = newState;
      _isToggling = false;
    });
  }
}

class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggle;
  const _OnlineToggle({
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [TayyebGoTheme.primaryColor, const Color(0xFF43A047)]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(isOnline ? Icons.circle : Icons.circle_outlined,
              color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOnline ? 'You are Online' : 'You are Offline',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: isToggling ? null : (_) => onToggle(),
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _WalletSummary extends StatelessWidget {
  final DriverWalletModel wallet;
  const _WalletSummary({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _sumItem(Icons.account_balance_wallet, 'Balance', 'SYP ${wallet.balance.toStringAsFixed(0)}'),
                _sumItem(Icons.trending_up, 'Today', 'SYP 0'),
                _sumItem(Icons.emoji_events, 'Level', wallet.level.displayName),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _sumItem(Icons.delivery_dining, 'Deliveries', '${wallet.totalDeliveries}'),
                _sumItem(Icons.star, 'Rating', wallet.averageRating.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sumItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: TayyebGoTheme.primaryColor, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.list_alt,
            label: 'Available\nRequests',
            color: Colors.orange,
            onTap: () => context.go('/available-requests'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Earnings',
            color: TayyebGoTheme.primaryColor,
            onTap: () => context.go('/earnings'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.wallet,
            label: 'Wallet',
            color: Colors.purple,
            onTap: () => context.go('/wallet'),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('anything_requests')
          .where('driverId', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'shopping', 'en_route'])
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.inbox, color: Colors.grey, size: 32),
                  const SizedBox(width: 16),
                  const Text('No active deliveries',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        final doc = snap.data!.docs.first;
        final d = doc.data() as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: Icon(Icons.delivery_dining, color: TayyebGoTheme.primaryColor),
            title: Text('Active: ${d['storeName'] as String? ?? 'Delivery'}'),
            subtitle: Text('Status: ${d['status'] as String? ?? ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/active-delivery/${doc.id}'),
          ),
        );
      },
    );
  }
}

class _EarningsTodayCard extends StatelessWidget {
  final DriverWalletModel? wallet;
  const _EarningsTodayCard({this.wallet});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('SYP ${wallet?.totalEarned.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/earnings'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Details'),
            ),
          ],
        ),
      ),
    );
  }
}
