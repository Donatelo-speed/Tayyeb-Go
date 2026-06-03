import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../admin_design.dart';

class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});
  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  int _orders = 0, _activeOrders = 0, _stores = 0, _onlineDrivers = 0, _customers = 0, _pendingTickets = 0;
  double _revenue = 0;
  late StreamSubscription _orderSub, _storeSub, _driverSub, _userSub, _ticketSub;

  @override
  void initState() {
    super.initState();
    _orderSub = FirebaseFirestore.instance.collection('orders').snapshots().listen((s) {
      if (!mounted) return;
      setState(() {
        _orders = s.docs.length;
        _revenue = 0; _activeOrders = 0;
        for (final d in s.docs) {
          final data = d.data();
          _revenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;
          if (const ['pending', 'accepted', 'preparing', 'ready_for_driver', 'picked_up'].contains(data['status'])) _activeOrders++;
        }
      });
    });
    _storeSub = FirebaseFirestore.instance.collection('restaurants').snapshots().listen((s) => mounted ? setState(() => _stores = s.docs.length) : null);
    _driverSub = FirebaseFirestore.instance.collection('drivers').snapshots().listen((s) {
      if (!mounted) return;
      setState(() { _onlineDrivers = s.docs.where((d) => d.data()['isOnline'] == true).length; });
    });
    _userSub = FirebaseFirestore.instance.collection('users').snapshots().listen((s) => mounted ? setState(() => _customers = s.docs.length) : null);
    _ticketSub = FirebaseFirestore.instance.collection('support_tickets').where('status', whereIn: ['open', 'assigned', 'in_progress']).snapshots().listen((s) => mounted ? setState(() => _pendingTickets = s.docs.length) : null);
  }

  @override
  void dispose() { _orderSub.cancel(); _storeSub.cancel(); _driverSub.cancel(); _userSub.cancel(); _ticketSub.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _KpiRow(isDark: isDark, kpis: [
          _KpiData('Revenue Today', '\$${_revenue.toStringAsFixed(0)}', Icons.attach_money_rounded, AdminColors.success),
          _KpiData('Orders', '$_orders', Icons.receipt_long_rounded, AdminColors.info),
          _KpiData('Active Orders', '$_activeOrders', Icons.pending_actions_rounded, AdminColors.warning),
          _KpiData('Online Drivers', '$_onlineDrivers', Icons.delivery_dining_rounded, AdminColors.secondary),
        ]),
        const SizedBox(height: 16),
        _KpiRow(isDark: isDark, kpis: [
          _KpiData('Stores', '$_stores', Icons.store_rounded, AdminColors.primary),
          _KpiData('Customers', '$_customers', Icons.group_rounded, const Color(0xFF8B5CF6)),
          _KpiData('Pending Support', '$_pendingTickets', Icons.headset_mic_rounded, AdminColors.danger),
          _KpiData('Platform Health', '98%', Icons.monitor_heart_rounded, AdminColors.success),
        ]),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(flex: 3, child: _LiveMapWidget(isDark: isDark)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _ActivityFeed(isDark: isDark)),
        ]),
      ]),
    );
  }
}

class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}

class _KpiRow extends StatelessWidget {
  final bool isDark;
  final List<_KpiData> kpis;
  const _KpiRow({required this.isDark, required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Row(children: kpis.map((k) => Expanded(child: Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard,
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          boxShadow: AdminShadows.card(isDark),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: k.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.md)), child: Icon(k.icon, color: k.color, size: 18)), const Spacer(), Icon(Icons.trending_up_rounded, color: k.color.withValues(alpha: 0.5), size: 16)]),
          const SizedBox(height: 16),
          Text(k.value, style: isDark ? AdminTypography.kpiValue(true) : AdminTypography.kpiValue(false)),
          const SizedBox(height: 4),
          Text(k.label, style: isDark ? AdminTypography.kpiLabel(true) : AdminTypography.kpiLabel(false)),
        ]),
      ),
    ))).toList());
  }
}

class _LiveMapWidget extends StatefulWidget {
  final bool isDark;
  const _LiveMapWidget({required this.isDark});
  @override
  State<_LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<_LiveMapWidget> {
  final _mapCtrl = MapController();
  Map<String, dynamic>? _selected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('driver_locations').where('isOnline', isEqualTo: true).snapshots(),
      builder: (ctx, snap) {
        final drivers = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
        final markers = drivers.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final lat = (d['lat'] as num?)?.toDouble() ?? 34.733;
          final lng = (d['lng'] as num?)?.toDouble() ?? 36.715;
          final name = d['driverName'] as String? ?? 'Driver';
          final heading = (d['heading'] as num?)?.toDouble() ?? 0;
          final sel = _selected?['driverId'] == d['driverId'];
          return Marker(point: LatLng(lat, lng), width: sel ? 220 : 44, height: sel ? 80 : 44, child: GestureDetector(
            onTap: () => setState(() => _selected = sel ? null : Map<String, dynamic>.from(d)),
            child: sel
                ? Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: widget.isDark ? AdminColors.bgDarkCard : Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: AdminShadows.elevated(widget.isDark)), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(name, style: AdminTypography.label(widget.isDark)),
                    Text('📍 Online · ${d['heading'] != null ? '${heading.toStringAsFixed(0)}°' : 'Stationary'}', style: AdminTypography.caption(widget.isDark)),
                  ]))
                : Stack(alignment: Alignment.center, children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AdminColors.secondary.withValues(alpha: 0.15), shape: BoxShape.circle)),
                    Transform.rotate(angle: heading * 3.14159 / 180, child: const Icon(Icons.navigation_rounded, color: AdminColors.secondary, size: 22)),
                  ]),
          ));
        }).toList();

        markers.addAll(_storeMarkers());

        return Container(
          height: 440,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(widget.isDark)),
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
              decoration: BoxDecoration(color: widget.isDark ? AdminColors.bgDarkCard : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AdminShadows.card(widget.isDark)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.circle, color: AdminColors.success, size: 10), const SizedBox(width: 6),
                Text('${drivers.length} drivers', style: AdminTypography.label(widget.isDark)),
              ]),
            )),
            Positioned(bottom: 16, right: 16, child: FloatingActionButton.small(heroTag: 'dashboard_map', onPressed: () => _mapCtrl.move(const LatLng(34.733, 36.715), 13.0), backgroundColor: widget.isDark ? AdminColors.bgDarkSurface : Colors.white, child: const Icon(Icons.my_location_rounded, color: AdminColors.primary))),
          ]),
        );
      },
    );
  }

  List<Marker> _storeMarkers() {
    return [
      Marker(point: const LatLng(34.740, 36.718), width: 36, height: 36, child: Container(decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AdminColors.primary, width: 2)), child: const Icon(Icons.store_rounded, color: AdminColors.primary, size: 18))),
      Marker(point: const LatLng(34.728, 36.710), width: 36, height: 36, child: Container(decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AdminColors.primary, width: 2)), child: const Icon(Icons.store_rounded, color: AdminColors.primary, size: 18))),
    ];
  }
}

class _ActivityFeed extends StatelessWidget {
  final bool isDark;
  const _ActivityFeed({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activity_log').orderBy('timestamp', descending: true).limit(8).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('Live Activity', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)), const Spacer(), Icon(Icons.more_horiz_rounded, size: 18, color: isDark ? AdminColors.textDarkMuted : AdminColors.textLightMuted)]),
            const SizedBox(height: 16),
            if (docs.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No recent activity', style: isDark ? AdminTypography.caption(true) : AdminTypography.caption(false))))
            else ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.md)), child: Icon(_activityIcon(d['type'] as String?), color: AdminColors.primary, size: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['text'] as String? ?? '', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(_timeAgo((d['timestamp'] as Timestamp?)?.toDate()), style: isDark ? AdminTypography.caption(true) : AdminTypography.caption(false)),
                  ])),
                ]),
              );
            }),
          ]),
        );
      },
    );
  }

  IconData _activityIcon(String? type) {
    switch (type) {
      case 'order': return Icons.receipt_long_rounded;
      case 'store': return Icons.store_rounded;
      case 'driver': return Icons.delivery_dining_rounded;
      case 'user': return Icons.person_add_rounded;
      case 'payment': return Icons.payment_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}min ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}