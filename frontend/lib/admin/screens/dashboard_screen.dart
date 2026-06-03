import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription? _orderSub, _storeSub, _driverSub, _userSub, _ticketSub;
  int _orders = 0, _activeOrders = 0, _stores = 0, _onlineDrivers = 0, _customers = 0, _pendingTickets = 0;
  double _revenue = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _orderSub = db.collection('orders').snapshots().listen((s) {
      if (!mounted) return;
      double rev = 0; int active = 0;
      for (final d in s.docs) {
        final data = d.data();
        rev += (data['totalAmount'] as num?)?.toDouble() ?? 0;
        if (const ['pending', 'accepted', 'preparing', 'ready_for_driver', 'picked_up'].contains(data['status'])) active++;
      }
      setState(() { _orders = s.docs.length; _revenue = rev; _activeOrders = active; _loading = false; });
    });
    _storeSub = db.collection('restaurants').snapshots().listen((s) => mounted ? setState(() => _stores = s.docs.where((d) => (d.data()['isOpen'] == true) && (d.data()['isSuspended'] != true)).length) : null);
    _driverSub = db.collection('drivers').snapshots().listen((s) => mounted ? setState(() => _onlineDrivers = s.docs.where((d) => d.data()['isOnline'] == true).length) : null);
    _userSub = db.collection('users').snapshots().listen((s) => mounted ? setState(() => _customers = s.docs.length) : null);
    _ticketSub = db.collection('support_tickets').where('status', whereIn: ['open', 'assigned', 'in_progress']).snapshots().listen((s) => mounted ? setState(() => _pendingTickets = s.docs.length) : null);
  }

  @override
  void dispose() {
    _orderSub?.cancel(); _storeSub?.cancel(); _driverSub?.cancel(); _userSub?.cancel(); _ticketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const AdminSkeletonCard(isDark: true);

    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth > 900;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Operations Command Center', style: AdminTypography.h1(isDark)),
            const Spacer(),
            Text('Last updated: just now', style: AdminTypography.caption(isDark)),
          ]),
          const SizedBox(height: AdminSpacing.xxl),
          _buildKpiGrid(isDark, wide),
          const SizedBox(height: AdminSpacing.xxl),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _LiveMap(isDark: isDark)),
              const SizedBox(width: AdminSpacing.xl),
              Expanded(flex: 2, child: _ActivityFeed(isDark: isDark)),
            ])
          else ...[
            _LiveMap(isDark: isDark),
            const SizedBox(height: AdminSpacing.xl),
            _ActivityFeed(isDark: isDark),
          ],
          const SizedBox(height: AdminSpacing.xxl),
          _buildQuickActions(isDark),
        ]),
      );
    });
  }

  Widget _buildKpiGrid(bool isDark, bool wide) {
    final kpis = [
      _Kpi('Revenue Today', '\$${_revenue.toStringAsFixed(0)}', Icons.attach_money_rounded, AdminColors.success),
      _Kpi('Orders Today', '$_orders', Icons.receipt_long_rounded, AdminColors.info),
      _Kpi('Active Orders', '$_activeOrders', Icons.pending_actions_rounded, AdminColors.warning),
      _Kpi('Online Drivers', '$_onlineDrivers', Icons.delivery_dining_rounded, const Color(0xFF0891B2)),
      _Kpi('Active Stores', '$_stores', Icons.store_rounded, AdminColors.primary),
      _Kpi('Customers', '$_customers', Icons.group_rounded, const Color(0xFF7C3AED)),
      _Kpi('Pending Tickets', '$_pendingTickets', Icons.headset_mic_rounded, AdminColors.danger),
      _Kpi('Platform Health', '98%', Icons.monitor_heart_rounded, AdminColors.success),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 4 : 2,
        crossAxisSpacing: AdminSpacing.md,
        mainAxisSpacing: AdminSpacing.md,
        childAspectRatio: wide ? 1.5 : 1.3,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => AdminKpiCard(
        label: kpis[i].label,
        value: kpis[i].value,
        icon: kpis[i].icon,
        color: kpis[i].color,
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions', style: AdminTypography.h3(isDark)),
      const SizedBox(height: AdminSpacing.lg),
      Wrap(spacing: AdminSpacing.md, runSpacing: AdminSpacing.md, children: [
        _QuickAction(isDark: isDark, icon: Icons.store_rounded, label: 'Add Store', color: AdminColors.primary),
        _QuickAction(isDark: isDark, icon: Icons.delivery_dining_rounded, label: 'Add Driver', color: AdminColors.info),
        _QuickAction(isDark: isDark, icon: Icons.notifications_active_rounded, label: 'Send Notification', color: AdminColors.warning),
        _QuickAction(isDark: isDark, icon: Icons.campaign_rounded, label: 'Create Campaign', color: const Color(0xFF7C3AED)),
      ]),
    ]);
  }
}

class _Kpi {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Kpi(this.label, this.value, this.icon, this.color);
}

class _QuickAction extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.isDark, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xl, vertical: AdminSpacing.lg),
          decoration: cardDecoration(isDark),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AdminSpacing.md),
            Text(label, style: AdminTypography.h4(isDark)),
          ]),
        ),
      ),
    );
  }
}

class _LiveMap extends StatefulWidget {
  final bool isDark;
  const _LiveMap({required this.isDark});
  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  final _mapCtrl = MapController();
  Map<String, dynamic>? _selected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('driver_locations').where('isOnline', isEqualTo: true).snapshots(),
      builder: (ctx, snap) {
        final drivers = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
        final markers = <Marker>[];

        for (final doc in drivers) {
          final d = doc.data() as Map<String, dynamic>;
          final lat = (d['lat'] as num?)?.toDouble() ?? 34.733;
          final lng = (d['lng'] as num?)?.toDouble() ?? 36.715;
          final name = d['driverName'] as String? ?? 'Driver';
          final heading = (d['heading'] as num?)?.toDouble() ?? 0;
          final sel = _selected?['driverId'] == d['driverId'];

          markers.add(Marker(
            point: LatLng(lat, lng),
            width: sel ? 200 : 40,
            height: sel ? 70 : 40,
            child: GestureDetector(
              onTap: () => setState(() => _selected = sel ? null : Map<String, dynamic>.from(d)),
              child: sel
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AdminColors.card(widget.isDark), borderRadius: BorderRadius.circular(10), boxShadow: AdminShadows.lg(widget.isDark)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(name, style: AdminTypography.label(widget.isDark)),
                        Text('Online', style: AdminTypography.caption(widget.isDark)),
                      ]),
                    )
                  : Stack(alignment: Alignment.center, children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: AdminColors.success.withValues(alpha: 0.15), shape: BoxShape.circle)),
                      Transform.rotate(angle: heading * 3.14159 / 180, child: const Icon(Icons.navigation_rounded, color: AdminColors.success, size: 18)),
                    ]),
            ),
          ));
        }

        markers.add(Marker(point: const LatLng(34.740, 36.718), width: 32, height: 32, child: Container(decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AdminColors.primary, width: 2)), child: const Icon(Icons.store_rounded, color: AdminColors.primary, size: 16))));
        markers.add(Marker(point: const LatLng(34.728, 36.710), width: 32, height: 32, child: Container(decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AdminColors.primary, width: 2)), child: const Icon(Icons.store_rounded, color: AdminColors.primary, size: 16))));

        return Container(
          height: 420,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AdminRadius.xl), border: Border.all(color: AdminColors.border(widget.isDark))),
          child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(initialCenter: const LatLng(34.733, 36.715), initialZoom: 13.0, onTap: (_, _) => setState(() => _selected = null)),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.tayyebgo.app'),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
            Positioned(top: 12, left: 12, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AdminColors.card(widget.isDark), borderRadius: BorderRadius.circular(12), boxShadow: AdminShadows.md(widget.isDark)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${drivers.length} drivers online', style: AdminTypography.label(widget.isDark)),
              ]),
            )),
            Positioned(bottom: 16, right: 16, child: FloatingActionButton.small(heroTag: 'dash_map', onPressed: () => _mapCtrl.move(const LatLng(34.733, 36.715), 13.0), backgroundColor: AdminColors.card(widget.isDark), child: const Icon(Icons.my_location_rounded, color: AdminColors.primary))),
            Positioned(top: 12, right: 12, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AdminColors.card(widget.isDark), borderRadius: BorderRadius.circular(8), boxShadow: AdminShadows.md(widget.isDark)),
              child: Text('Homs, Syria', style: AdminTypography.caption(widget.isDark)),
            )),
          ]),
        );
      },
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  final bool isDark;
  const _ActivityFeed({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activity_log').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
        return Container(
          height: 420,
          padding: const EdgeInsets.all(AdminSpacing.xl),
          decoration: cardDecoration(isDark),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Live Activity', style: AdminTypography.h3(isDark)),
              const Spacer(),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Live', style: AdminTypography.caption(isDark)),
            ]),
            const SizedBox(height: AdminSpacing.lg),
            Expanded(
              child: docs.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_rounded, size: 40, color: AdminColors.textMuted(isDark)),
                      const SizedBox(height: AdminSpacing.md),
                      Text('No recent activity', style: AdminTypography.bodySmall(isDark)),
                    ]))
                  : ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AdminSpacing.md),
                      itemBuilder: (_, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final type = d['type'] as String? ?? '';
                        final icon = _activityIcon(type);
                        final color = _activityColor(type);
                        return Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.md)),
                            child: Icon(icon, color: color, size: 16),
                          ),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d['text'] as String? ?? '', style: AdminTypography.body(isDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(timeAgo((d['timestamp'] as Timestamp?)?.toDate()), style: AdminTypography.caption(isDark)),
                          ])),
                        ]);
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'order': return Icons.receipt_long_rounded;
      case 'store': return Icons.store_rounded;
      case 'driver': return Icons.delivery_dining_rounded;
      case 'user': return Icons.person_add_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'refund': return Icons.replay_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'order': return AdminColors.info;
      case 'store': return AdminColors.primary;
      case 'driver': return AdminColors.success;
      case 'user': return const Color(0xFF7C3AED);
      case 'payment': return AdminColors.warning;
      case 'refund': return AdminColors.danger;
      default: return AdminColors.slate400;
    }
  }
}