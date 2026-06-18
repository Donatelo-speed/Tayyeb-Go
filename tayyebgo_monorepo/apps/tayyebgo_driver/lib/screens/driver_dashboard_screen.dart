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
    try {
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
    } catch (e) {
      debugPrint('[DriverDashboard] _loadInitialOnlineState error: $e');
      if (mounted) {
        DriverLocationService.instance.start(userId);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = context.watch<DriverWalletProvider>();
    final wallet = walletProv.wallet;
    final dispatchProv = context.watch<DispatchProvider>();
    final auth = context.watch<AuthProvider>();
    final driverName = (auth.user?.displayName ?? 'Driver').split(' ').first;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedFadeSlide(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              '${_getGreeting()}, $driverName',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryColor,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedFadeSlide(
                            delay: 100,
                            duration: const Duration(milliseconds: 500),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isOnline ? AppColors.driverAccent : AppColors.textMuted,
                                    shape: BoxShape.circle,
                                    boxShadow: _isOnline ? [
                                      BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
                                    ] : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isOnline ? 'Online & Ready' : 'Offline',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: _isOnline ? AppColors.driverAccent : AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedFadeSlide(
                      delay: 200,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedPressScale(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.8)],
                            ),
                            borderRadius: AppRadius.brXl,
                            boxShadow: [
                              BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              driverName[0].toUpperCase(),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Online Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 150,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedPressScale(
                    onTap: _toggleOnline,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isOnline
                              ? [AppColors.driverAccent, const Color(0xFF059669)]
                              : [context.surfaceColor, context.surfaceColor],
                        ),
                        borderRadius: AppRadius.brXl,
                        boxShadow: _isOnline
                            ? [BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.white : AppColors.textMuted,
                              shape: BoxShape.circle,
                              boxShadow: _isOnline ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isOnline ? 'You are Online' : 'Tap to go Online',
                                  style: TextStyle(
                                    color: _isOnline ? Colors.white : context.textPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!_isOnline)
                                  Text(
                                    'Start receiving delivery requests',
                                    style: TextStyle(color: context.textMutedColor, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 52, height: 28,
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.white.withValues(alpha: 0.2) : context.surfaceAltColor,
                              borderRadius: AppRadius.brLg,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: _isOnline ? Colors.white : AppColors.textMuted,
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
            ),

            // Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 200,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    children: [
                      Expanded(child: TGStat(label: 'Balance', value: 'SYP ${wallet?.balance.toStringAsFixed(0) ?? '0'}', icon: Icons.account_balance_wallet_rounded, color: AppColors.driverAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: TGStat(label: 'Earned', value: 'SYP ${wallet?.totalEarned.toStringAsFixed(0) ?? '0'}', icon: Icons.trending_up_rounded, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: TGStat(label: 'Deliveries', value: '${wallet?.totalDeliveries ?? 0}', icon: Icons.delivery_dining_rounded, color: AppColors.adminAccent)),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 250,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    children: [
                      _quickAction(context, Icons.list_alt_rounded, 'Requests', AppColors.warning, () => context.push('/available-requests')),
                      const SizedBox(width: 12),
                      _quickAction(context, Icons.map_rounded, 'Heat Map', AppColors.driverAccent, () => context.push('/heatmap')),
                      const SizedBox(width: 12),
                      _quickAction(context, Icons.account_balance_wallet_rounded, 'Wallet', AppColors.purple, () => context.push('/wallet')),
                    ],
                  ),
                ),
              ),
            ),

            // Active Dispatches
            if (dispatchProv.assignedDispatches.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: AnimatedFadeSlide(
                    delay: 300,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 4, height: 20, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.5)]), borderRadius: AppRadius.brSm)),
                            const SizedBox(width: 12),
                            Text('Active Dispatch', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor, letterSpacing: 0)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AssignedDispatchCard(
                          dispatches: dispatchProv.assignedDispatches,
                          onAccept: (d) => _handleDispatchAction(d, 'accept'),
                          onReject: (d) => _handleDispatchAction(d, 'reject'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Active Deliveries
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 350,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 20, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primary, AppColors.primaryHover]), borderRadius: AppRadius.brSm)),
                          const SizedBox(width: 12),
                          Text('Active Deliveries', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor, letterSpacing: 0)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ActiveOrdersSection(wallet: wallet),
                    ],
                  ),
                ),
              ),
            ),

            // Performance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 400,
                  duration: const Duration(milliseconds: 500),
                  child: _buildPerformanceCard(context),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: AnimatedPressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppRadius.brLg,
            border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
          .handleError((e) {
        debugPrint('[DriverDashboard] users stream error: $e');
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final rating = (data?['rating'] as num?)?.toDouble() ?? 0.0;
        final totalDeliveries = data?['totalDeliveries'] ?? 0;
        String ratingText = rating > 0 ? rating.toStringAsFixed(1) : '—';
        String subText = rating >= 4.5 ? 'Excellent rating!' : rating > 0 ? 'Keep going!' : 'Complete deliveries to earn a rating';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.driverAccent, AppColors.driverAccent.withValues(alpha: 0.8)],
            ),
            borderRadius: AppRadius.brXl,
            boxShadow: [BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver Score', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(ratingText, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 32, color: Colors.white, letterSpacing: 0)),
                    const SizedBox(height: 4),
                    Text(subText, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.brCard,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 4),
                  Text('$totalDeliveries deliveries', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleOnline() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    setState(() => _isOnline = !_isOnline);
    DriverLocationService.instance.setOnlineStatus(userId, _isOnline);
    if (_isOnline) {
      DriverLocationService.instance.start(userId);
    }
  }

  Future<void> _handleDispatchAction(Map<String, dynamic> dispatch, String action) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final dispatchId = dispatch['id'] as String?;
    if (dispatchId == null) return;
    try {
      if (action == 'accept') {
        await FirebaseFirestore.instance.collection('dispatch_requests').doc(dispatchId).update({
          'status': 'accepted',
          'driverId': userId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) context.push('/active-delivery-food/$dispatchId');
      } else if (action == 'reject') {
        await FirebaseFirestore.instance.collection('dispatch_requests').doc(dispatchId).update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _AssignedDispatchCard extends StatelessWidget {
  final List<Map<String, dynamic>> dispatches;
  final Function(Map<String, dynamic>) onAccept;
  final Function(Map<String, dynamic>) onReject;
  const _AssignedDispatchCard({required this.dispatches, required this.onAccept, required this.onReject});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: dispatches.map((d) {
        final restaurant = d['restaurantName'] ?? d['restaurantId'] ?? 'Restaurant';
        final items = (d['items'] as List?)?.length ?? 0;
        final total = ((d['totalCents'] ?? 0) / 100).toStringAsFixed(0);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.driverAccent.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.restaurant_rounded, color: AppColors.driverAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('$restaurant', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor))),
                Text('SYP $total', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.driverAccent)),
              ]),
              const SizedBox(height: 8),
              Text('$items item${items == 1 ? '' : 's'}', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onReject(d),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
                    child: Text('Reject', style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAccept(d),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.driverAccent, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ActiveOrdersSection extends StatelessWidget {
  final dynamic wallet;
  const _ActiveOrdersSection({required this.wallet});
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dispatch_requests')
          .where('driverId', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'picked_up']).snapshots()
          .handleError((e) {
        debugPrint('[DriverDashboard] dispatch_requests stream error: $e');
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.brCard,
            ),
            child: Center(
              child: Text('No active deliveries', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
            ),
          );
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final restaurant = data['restaurantName'] ?? 'Restaurant';
            final customer = data['customerName'] ?? 'Customer';
            final status = data['status'] ?? 'unknown';
            final orderId = doc.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.brCard,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: AppRadius.brSm),
                      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.warning)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/active-delivery-food/$orderId'),
                      child: Text('Open', style: TextStyle(color: AppColors.driverAccent, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _infoRow(Icons.restaurant_rounded, 'Pickup', restaurant, context),
                  const SizedBox(height: 4),
                  _infoRow(Icons.person_rounded, 'Deliver to', customer, context),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
      Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis)),
    ]);
  }
}
