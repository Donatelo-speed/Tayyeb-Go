import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.driverAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Driver', style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.driverAccent, AppColors.emerald],
                            ).createShader(bounds),
                            child: Text('Dashboard', style: GoogleFonts.inter(
                              fontWeight: FontWeight.w300,
                              fontSize: 28,
                              color: Colors.white,
                            )),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/driver-profile'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.surfaceAltColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(Icons.person_rounded, color: AppColors.textMuted, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: GestureDetector(
                  onTap: _toggleOnline,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isOnline
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [context.surfaceAltColor, context.surfaceColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        if (_isOnline)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: context.textMutedColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _isOnline ? 'You are Online' : 'You are Offline',
                            style: TextStyle(
                              color: _isOnline ? Colors.white : context.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 52,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? Colors.white.withValues(alpha: 0.2)
                                : context.surfaceAltColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _isOnline ? Colors.white : context.textMutedColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(child: _earningsCard(
                      label: 'Balance',
                      value: 'SYP ${wallet?.balance.toStringAsFixed(0) ?? '0'}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF10B981),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _earningsCard(
                      label: 'Deliveries',
                      value: '${wallet?.totalDeliveries ?? 0}',
                      icon: Icons.delivery_dining_rounded,
                      color: context.primaryColor,
                    )),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(child: _quickAction(
                      icon: Icons.list_alt_rounded,
                      label: 'Requests',
                      color: context.warningColor,
                      onTap: () => context.go('/available-requests'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Earnings',
                      color: const Color(0xFF10B981),
                      onTap: () => context.go('/earnings'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAction(
                      icon: Icons.wallet_rounded,
                      label: 'Wallet',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.go('/wallet'),
                    )),
                  ],
                ),
              ),
            ),

            if (dispatchProv.assignedDispatches.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _AssignedDispatchCard(
                    dispatches: dispatchProv.assignedDispatches,
                    onAccept: (d) => _handleDispatchAction(d, 'accept'),
                    onReject: (d) => _handleDispatchAction(d, 'reject'),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text('Active Deliveries', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                )),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _ActiveOrdersSection(wallet: wallet),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Earnings', style: GoogleFonts.inter(
                              fontSize: 14,
                              color: context.textMutedColor,
                            )),
                            Text('SYP ${wallet?.totalEarned.toStringAsFixed(0) ?? '0'}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                )),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/earnings'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Details', style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _earningsCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.textPrimary,
          )),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
          )),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            )),
          ],
        ),
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
      decoration: BoxDecoration(
        color: context.warningColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.warningColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delivery_dining, color: context.warningColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text('New Delivery Requests', style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              )),
            ],
          ),
          const SizedBox(height: 14),
          ...dispatches.take(3).map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order: ${(d['orderId'] as String? ?? '').substring(0, 6)}...',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text('Delivery fee included',
                                style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onAccept(d),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.check_circle, color: context.successColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onReject(d),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.cancel, color: context.errorColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ActiveOrdersSection extends StatelessWidget {
  final DriverWalletModel? wallet;
  const _ActiveOrdersSection({this.wallet});

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
            return GestureDetector(
              onTap: () => context.go('/active-delivery/${doc.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Anything: ${d['storeName'] as String? ?? 'Delivery'}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('Status: ${d['status'] as String? ?? ''}',
                              style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                        ],
                      ),
                    ),
                        Icon(Icons.chevron_right, color: context.textMutedColor, size: 20),
                  ],
                ),
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
                    .where('status', whereIn: ['accepted', 'shopping', 'en_route'])
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) return const SizedBox.shrink();
                  if (snap.hasData && snap.data!.docs.isEmpty && foodDeliveries.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inbox_rounded, color: context.textMutedColor, size: 28),
                          const SizedBox(width: 14),
                          Text('No active deliveries',
                              style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
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
                return GestureDetector(
                  onTap: () => context.go('/active-delivery-food/$id'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Food Delivery',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Status: ${d['status'] as String? ?? ''}',
                                  style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                            ],
                          ),
                        ),
                    Icon(Icons.chevron_right, color: context.textMutedColor, size: 20),
                      ],
                    ),
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
