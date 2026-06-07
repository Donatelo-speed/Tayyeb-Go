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

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with WidgetsBindingObserver {
  bool _isOnline = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialOnlineState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    if (state == AppLifecycleState.paused) {
      DriverLocationService.instance.setOnlineStatus(userId, true);
    } else if (state == AppLifecycleState.resumed && _isOnline) {
      DriverLocationService.instance.forceRefresh(userId);
    }
  }

  Future<void> _loadInitialOnlineState() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('driver_locations')
        .doc(userId)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _isOnline = (doc.data()?['isOnline'] as bool?) ?? false;
      });
    }
    if (_isOnline && mounted) {
      DriverLocationService.instance.start(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;
    final dispatchProv = context.watch<DispatchProvider>();

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
          if (dispatchProv.assignedDispatches.isNotEmpty)
            _AssignedDispatchCard(
              dispatches: dispatchProv.assignedDispatches,
              onAccept: (d) => _handleDispatchAction(d, 'accept'),
              onReject: (d) => _handleDispatchAction(d, 'reject'),
            ),
          const SizedBox(height: 16),
          _ActiveOrdersSection(),
          const SizedBox(height: 16),
          _EarningsTodayCard(wallet: wallet),
        ],
      ),
    );
  }

  Future<void> _handleDispatchAction(
      Map<String, dynamic> dispatch, String action) async {
    final id = dispatch['id'] as String;
    final prov = context.read<DispatchProvider>();
    if (action == 'accept') {
      await prov.acceptDispatch(id);
      if (mounted) context.go('/active-delivery-food/$id');
    } else {
      await prov.rejectDispatch(id);
    }
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
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isOnline': newState,
      }).catchError((_) {});
      if (newState) {
        DriverLocationService.instance.start(userId);
      } else {
        DriverLocationService.instance.stop();
      }
    }
    if (!mounted) return;
    setState(() {
      _isOnline = newState;
      _isToggling = false;
    });
  }
}

class _AssignedDispatchCard extends StatelessWidget {
  final List<Map<String, dynamic>> dispatches;
  final void Function(Map<String, dynamic>) onAccept;
  final void Function(Map<String, dynamic>) onReject;

  const _AssignedDispatchCard({
    required this.dispatches,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delivery_dining, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text('New Delivery Requests',
                  style: TayyebGoTheme.heading3),
            ],
          ),
          const SizedBox(height: 12),
          ...dispatches.take(3).map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order: ${(d['orderId'] as String? ?? '').substring(0, 6)}...',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('Delivery fee included',
                              style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                      onPressed: () => onAccept(d),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.error),
                      onPressed: () => onReject(d),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
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
              ? [TayyebGoTheme.primaryColor, AppColors.success]
              : [TayyebGoTheme.textMuted, TayyebGoTheme.textSecondary],
        ),
        borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
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
    );
  }

  Widget _sumItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: TayyebGoTheme.primaryColor, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 11, color: TayyebGoTheme.textMuted)),
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
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Earnings',
            color: TayyebGoTheme.primaryColor,
            onTap: () => context.go('/earnings'),
          ),
        ),
        const SizedBox(width: 12),
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
      borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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

class _ActiveOrdersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return const SizedBox.shrink();

    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('anything_requests')
              .where('driverId', isEqualTo: userId)
              .where('status', whereIn: ['accepted', 'shopping', 'en_route'])
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return const SizedBox.shrink();
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            final doc = snap.data!.docs.first;
            final d = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: TayyebGoTheme.cardDecoration,
              child: ListTile(
                leading: Icon(Icons.shopping_bag, color: TayyebGoTheme.primaryColor),
                title: Text(
                    'Anything: ${d['storeName'] as String? ?? 'Delivery'}'),
                subtitle: Text('Status: ${d['status'] as String? ?? ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/active-delivery/${doc.id}'),
              ),
            );
          },
        ),
        Consumer<DispatchProvider>(
          builder: (context, prov, _) {
            final foodDeliveries = prov.activeDeliveries;
            if (foodDeliveries.isEmpty) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('anything_requests')
                    .where('driverId', isEqualTo: userId)
                    .where('status',
                        whereIn: ['accepted', 'shopping', 'en_route'])
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) return const SizedBox.shrink();
                  if (snap.hasData &&
                      snap.data!.docs.isEmpty &&
                      foodDeliveries.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: TayyebGoTheme.cardDecoration,
                      child: Row(
                        children: [
                          Icon(Icons.inbox, color: TayyebGoTheme.textMuted, size: 32),
                          const SizedBox(width: 16),
                          Text('No active deliveries',
                              style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }
            return Column(
              children: foodDeliveries.map((d) {
                final id = d['id'] as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: TayyebGoTheme.cardDecoration,
                  child: ListTile(
                    leading: Icon(Icons.delivery_dining, color: TayyebGoTheme.primaryColor),
                    title: const Text('Food Delivery'),
                    subtitle: Text('Status: ${d['status'] as String? ?? ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/active-delivery-food/$id'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EarningsTodayCard extends StatelessWidget {
  final DriverWalletModel? wallet;
  const _EarningsTodayCard({this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings', style: TextStyle(fontWeight: FontWeight.bold, color: TayyebGoTheme.textPrimary)),
                Text('SYP ${wallet?.totalEarned.toStringAsFixed(0) ?? '0'}',
                    style: TayyebGoTheme.heading2),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.go('/earnings'),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Details'),
          ),
        ],
      ),
    );
  }
}
