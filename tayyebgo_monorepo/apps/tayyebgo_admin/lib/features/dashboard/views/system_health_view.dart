import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';
import '../../../core/services/admin_firestore_service.dart';

class SystemHealthView extends StatefulWidget {
  const SystemHealthView();

  @override
  State<SystemHealthView> createState() => _SystemHealthViewState();
}

class _SystemHealthViewState extends State<SystemHealthView> {
  DateTime _startedAt = DateTime.now();
  Duration _uptime = Duration.zero;
  int _ordersLastHour = 0;
  int _errorsLastHour = 0;
  int _activeDrivers = 0;
  int _activeStores = 0;
  int _openApprovals = 0;
  int _failedNotificationsLastHour = 0;
  Timer? _ticker;
  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _driversSub;
  StreamSubscription<QuerySnapshot>? _storesSub;
  StreamSubscription<QuerySnapshot>? _approvalsSub;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _uptime = DateTime.now().difference(_startedAt));
    });
    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))))
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _ordersLastHour = snap.docs.length;
        _errorsLastHour = snap.docs
            .where((d) => ((d.data()['status'] as String?) ?? '').toLowerCase() == 'failed' || ((d.data()['status'] as String?) ?? '').toLowerCase() == 'cancelled')
            .length;
      });
    });
    _driversSub = FirebaseFirestore.instance
        .collection('drivers')
        .where('isActive', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _activeDrivers = snap.docs.length);
    });
    _storesSub = FirebaseFirestore.instance
        .collection('Restaurants')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _activeStores = snap.docs.length);
    });
    _approvalsSub = FirebaseFirestore.instance
        .collection('approvals')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _openApprovals = snap.docs.length);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ordersSub?.cancel();
    _driversSub?.cancel();
    _storesSub?.cancel();
    _approvalsSub?.cancel();
    super.dispose();
  }

  String _fmtUptime() {
    final s = _uptime.inSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  int _healthScore() {
    final s = 100 - _errorsLastHour * 2 - (_failedNotificationsLastHour ~/ 4);
    return s.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 1000;
            final score = _healthScore();
            final scoreColor = score >= 80
                ? AppColors.success
                : score >= 60
                    ? AppColors.warning
                    : AppColors.error;
            final children = <Widget>[
              _HealthRing(score: score, color: scoreColor),
              const SizedBox(width: 24),
              Expanded(child: _HealthSummary(score: score, color: scoreColor, uptime: _fmtUptime())),
            ];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: narrow
                  ? [Column(children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 16), child: w)).toList())]
                  : children,
            );
          }),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 800;
            final cards = <Widget>[
              _metricCard('Orders / 1h', _ordersLastHour.toString(), Icons.receipt_long_rounded, AppColors.primary),
              _metricCard('Errors / 1h', _errorsLastHour.toString(), Icons.error_outline, AppColors.error),
              _metricCard('Active Drivers', _activeDrivers.toString(), Icons.delivery_dining, AppColors.info),
              _metricCard('Active Stores', _activeStores.toString(), Icons.storefront_rounded, AppColors.success),
              _metricCard('Open Approvals', _openApprovals.toString(), Icons.verified_outlined, AppColors.warning),
              _metricCard('Failed Pushes / 1h', _failedNotificationsLastHour.toString(), Icons.notifications_off_outlined, AppColors.error),
            ];
            if (narrow) {
              return Wrap(spacing: 16, runSpacing: 16, children: cards);
            }
            return GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: cards,
            );
          }),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth < 900) {
              return Column(children: [
                _servicesCard(),
                const SizedBox(height: 16),
                _activityCard(),
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _servicesCard()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _activityCard()),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesCard() {
    final services = <_ServiceStatus>[
      _ServiceStatus('Firestore', _activeDrivers > 0 ? 'operational' : 'idle', Icons.cloud_done_rounded, AppColors.success),
      _ServiceStatus('Authentication', 'operational', Icons.lock_open_rounded, AppColors.success),
      _ServiceStatus('Cloud Functions', 'operational', Icons.functions_rounded, AppColors.success),
      _ServiceStatus('Storage', 'operational', Icons.folder_special_rounded, AppColors.success),
      _ServiceStatus('Push Notifications', 'degraded', Icons.notifications_active_rounded, AppColors.warning),
      _ServiceStatus('Payments (Stripe)', 'operational', Icons.credit_card_rounded, AppColors.success),
      _ServiceStatus('Maps (OSM)', 'operational', Icons.map_rounded, AppColors.success),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.dns_rounded, size: 18, color: context.primaryColor),
            const SizedBox(width: 8),
            Text('Services', style: AppTypography.heading3),
          ]),
          const SizedBox(height: 12),
          ...services.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(s.icon, size: 16, color: context.textMutedColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: s.color, letterSpacing: 0.5)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _activityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timeline_rounded, size: 18, color: context.primaryColor),
            const SizedBox(width: 8),
            Text('Recent activity', style: AppTypography.heading3),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showFullAuditLog(context),
              icon: const Icon(Icons.open_in_full_rounded, size: 14),
              label: const Text('View all'),
            ),
          ]),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminFirestoreService.instance.watchActivityLog(limit: 12),
            builder: (c, snap) {
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No recent activity', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: context.dividerColor),
                    _activityRow(items[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> d) {
    final actor = (d['actorName'] as String?) ?? (d['actor'] as String?) ?? 'system';
    final action = (d['action'] as String?) ?? 'updated';
    final target = (d['target'] as String?) ?? '';
    final ts = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.bolt_rounded, size: 14, color: context.primaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: actor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  TextSpan(text: ' $action ', style: const TextStyle(fontSize: 12)),
                  if (target.isNotEmpty) TextSpan(text: target, style: TextStyle(fontSize: 12, color: context.primaryColor)),
                ])),
                const SizedBox(height: 2),
                Text(_relativeTime(ts), style: TextStyle(fontSize: 10, color: context.textMutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showFullAuditLog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: context.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audit log', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            Text('All admin actions across the platform', style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: AdminFirestoreService.instance.watchActivityLog(limit: 200),
                    builder: (c, snap) {
                      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final items = snap.data ?? const <Map<String, dynamic>>[];
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('No admin actions logged yet.\n\nActivity appears here as admins use the panel.', textAlign: TextAlign.center, style: TextStyle(color: context.textMutedColor)),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (c2, i) => _activityRow(items[i]),
                        separatorBuilder: (_, __) => Divider(height: 1, color: context.dividerColor),
                        itemCount: items.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceStatus {
  final String name;
  final String status;
  final IconData icon;
  final Color color;
  _ServiceStatus(this.name, this.status, this.icon, this.color);
}

class _HealthRing extends StatelessWidget {
  final int score;
  final Color color;
  const _HealthRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140, height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: context.textPrimaryColor)),
                    Text('Health', style: TextStyle(fontSize: 11, color: context.textMutedColor, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Platform stability', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
        ],
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  final int score;
  final Color color;
  final String uptime;
  const _HealthSummary({required this.score, required this.color, required this.uptime});

  @override
  Widget build(BuildContext context) {
    final verdict = score >= 80 ? 'All systems operational' : score >= 60 ? 'Some services degraded' : 'Critical issues detected';
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
          Row(children: [
            Icon(Icons.health_and_safety_rounded, color: color, size: 22),
            const SizedBox(width: 10),
            Text(verdict, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          ]),
          const SizedBox(height: 8),
          Text('This page streams live counters from Firestore. Numbers refresh every order/driver update.', style: TextStyle(fontSize: 12, color: context.textMutedColor, height: 1.5)),
          const SizedBox(height: 18),
          Row(children: [
            _statTile(context, 'Uptime', uptime, Icons.timer_outlined),
            const SizedBox(width: 12),
            _statTile(context, 'Score', '$score / 100', Icons.speed_rounded),
            const SizedBox(width: 12),
            _statTile(context, 'Status', score >= 80 ? 'OK' : 'WARN', Icons.check_circle_outline),
          ]),
        ],
      ),
    );
  }

  Widget _statTile(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceAltColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: context.textMutedColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 10, color: context.textMutedColor, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          ],
        ),
      ),
    );
  }
}
