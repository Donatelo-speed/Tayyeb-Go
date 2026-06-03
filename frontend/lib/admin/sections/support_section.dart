import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class SupportSection extends StatefulWidget {
  const SupportSection({super.key});
  @override
  State<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<SupportSection> {
  String _filter = 'open';

  Future<void> _updateStatus(String id, String status) async {
    try { await FirebaseFirestore.instance.collection('support_tickets').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = ['all', 'open', 'assigned', 'in_progress', 'resolved', 'closed'];
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: statuses.map((s) {
        final sel = _filter == s;
        return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(s.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? Colors.white : null)), selected: sel, onSelected: (_) => setState(() => _filter = s), selectedColor: AdminColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide.none));
      }).toList())),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('createdAt', descending: true).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            var docs = snap.data!.docs;
            if (_filter != 'all') docs = docs.where((d) => (d.data() as Map)['status'] == _filter).toList();
            if (docs.isEmpty) return Center(child: Text('No ${_filter == 'all' ? '' : _filter} tickets', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)));
            return ListView.builder(padding: const EdgeInsets.all(20), itemCount: docs.length, itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final status = d['status'] as String? ?? 'open';
              final c = AdminColors.statusColor(status);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: Icon(_ticketIcon(d['category'] as String?), color: c, size: 18)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['subject'] as String? ?? 'No subject', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
                    const SizedBox(height: 2),
                    Text('${d['customerName'] ?? 'Anonymous'} · ${d['category'] ?? 'General'}', style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c))),
                  PopupMenuButton<String>(onSelected: (s) => _updateStatus(docs[i].id, s), itemBuilder: (_) => ['open', 'assigned', 'in_progress', 'resolved', 'closed'].where((s) => s != status).map((s) => PopupMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))).toList(), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.more_vert_rounded, size: 16))),
                ]),
              );
            });
          },
        ),
      ),
    ]);
  }

  IconData _ticketIcon(String? cat) {
    switch (cat) { case 'complaint': return Icons.report_problem_rounded; case 'suggestion': return Icons.lightbulb_rounded; case 'refund': return Icons.money_off_rounded; case 'bug': return Icons.bug_report_rounded; default: return Icons.help_outline_rounded; }
  }
}

class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({super.key});
  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  int _orders = 0, _stores = 0, _drivers = 0, _customers = 0;
  double _revenue = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final o = await FirebaseFirestore.instance.collection('orders').get();
    final s = await FirebaseFirestore.instance.collection('restaurants').get();
    final d = await FirebaseFirestore.instance.collection('drivers').get();
    final u = await FirebaseFirestore.instance.collection('users').get();
    if (!mounted) return;
    double r = 0;
    for (final doc in o.docs) { r += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0; }
    setState(() { _orders = o.docs.length; _stores = s.docs.length; _drivers = d.docs.length; _customers = u.docs.length; _revenue = r; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Platform Analytics', style: isDark ? AdminTypography.h2(true) : AdminTypography.h2(false)),
      const SizedBox(height: 20),
      Row(children: [Expanded(child: _AnCard(isDark: isDark, label: 'Total Revenue', value: '\$${_revenue.toStringAsFixed(0)}', color: AdminColors.success)), const SizedBox(width: 12), Expanded(child: _AnCard(isDark: isDark, label: 'Total Orders', value: '$_orders', color: AdminColors.info))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _AnCard(isDark: isDark, label: 'Stores', value: '$_stores', color: AdminColors.primary)), const SizedBox(width: 12), Expanded(child: _AnCard(isDark: isDark, label: 'Drivers', value: '$_drivers', color: AdminColors.warning)), const SizedBox(width: 12), Expanded(child: _AnCard(isDark: isDark, label: 'Customers', value: '$_customers', color: const Color(0xFF8B5CF6)))]),
      const SizedBox(height: 32),
      Text('Top Performing Stores', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
      const SizedBox(height: 16),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').orderBy('rating', descending: true).limit(5).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return Column(children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)), child: Row(children: [
              const Icon(Icons.trending_up_rounded, color: AdminColors.success, size: 20), const SizedBox(width: 12),
              Expanded(child: Text(d['name'] ?? 'N/A', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false))),
              const Icon(Icons.star_rounded, color: AdminColors.warning, size: 16), const SizedBox(width: 4),
              Text((d['rating'] as num?)?.toStringAsFixed(1) ?? '0.0', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)),
            ]));
          }).toList());
        },
      ),
    ]));
  }
}

class _AnCard extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final Color color;
  const _AnCard({required this.isDark, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 12),
      Text(value, style: isDark ? AdminTypography.kpiValue(true) : AdminTypography.kpiValue(false)),
      Text(label, style: isDark ? AdminTypography.kpiLabel(true) : AdminTypography.kpiLabel(false)),
    ]));
  }
}