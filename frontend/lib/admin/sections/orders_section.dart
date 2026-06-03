import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class OrdersSection extends StatefulWidget {
  const OrdersSection({super.key});
  @override
  State<OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<OrdersSection> {
  String _statusFilter = 'all';
  final String _search = '';

  Future<void> _updateStatus(String id, String status) async {
    try { await FirebaseFirestore.instance.collection('orders').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = ['all', 'pending', 'accepted', 'preparing', 'ready_for_driver', 'picked_up', 'delivered', 'cancelled'];
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard,
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: statuses.map((s) {
          final sel = _statusFilter == s;
          return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(s.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary)), selected: sel, onSelected: (_) => setState(() => _statusFilter = s), backgroundColor: isDark ? AdminColors.bgDarkSurface : AdminColors.bgLightSurface, selectedColor: AdminColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide.none));
        }).toList())),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return _loading(isDark);
            var docs = snap.data!.docs;
            if (_statusFilter != 'all') docs = docs.where((d) => (d.data() as Map)['status'] == _statusFilter).toList();
            if (_search.isNotEmpty) docs = docs.where((d) => ((d.data() as Map)['customerName'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
            if (docs.isEmpty) return Center(child: Text(_statusFilter == 'all' ? 'No orders' : 'No $_statusFilter orders', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final status = d['status'] as String? ?? 'pending';
                final items = d['items'] as List? ?? [];
                final itemStr = items.isEmpty ? 'No items' : items.take(3).map((e) => e is Map ? '${e['quantity'] ?? 1}x ${e['name'] ?? 'Item'}' : 'Item').join(', ');
                final c = AdminColors.statusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: Icon(Icons.receipt_long_rounded, color: c, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('#${docs[i].id.substring(0, 8)}', style: isDark ? AdminTypography.mono(true) : AdminTypography.mono(false)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c))),
                      ]),
                      const SizedBox(height: 4),
                      Text(d['customerName'] as String? ?? 'Guest', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)),
                      const SizedBox(height: 2),
                      Text(itemStr, style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Text('\$${(d['totalAmount'] as num?)?.toStringAsFixed(0) ?? '0'}', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
                    PopupMenuButton<String>(onSelected: (s) => _updateStatus(docs[i].id, s), itemBuilder: (_) => ['pending', 'accepted', 'preparing', 'ready_for_driver', 'picked_up', 'delivered', 'cancelled'].where((s) => s != status).map((s) => PopupMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))).toList(), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: isDark ? AdminColors.borderDark : AdminColors.borderLight), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_drop_down_rounded, size: 16))),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _loading(bool isDark) => const Center(child: CircularProgressIndicator(color: AdminColors.primary));
}

class DriversSection extends StatefulWidget {
  const DriversSection({super.key});
  @override
  State<DriversSection> createState() => _DriversSectionState();
}

class _DriversSectionState extends State<DriversSection> {
  Future<void> _toggleOnline(String id, bool online) async {
    try { await FirebaseFirestore.instance.collection('drivers').doc(id).update({'isOnline': !online}); } catch (_) {}
  }

  Future<void> _suspend(String id) async {
    try { await FirebaseFirestore.instance.collection('drivers').doc(id).update({'isActive': false, 'suspendedAt': FieldValue.serverTimestamp()}); } catch (_) {}
  }

  void _showAddDriver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    String type = 'platform';
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      child: Container(width: 480, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Driver', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)), const SizedBox(height: 16),
        TextField(controller: nameCtrl, decoration: _deco('Name', Icons.person_rounded)),
        const SizedBox(height: 12),
        TextField(controller: phoneCtrl, decoration: _deco('Phone', Icons.phone_rounded)),
        const SizedBox(height: 12),
        TextField(controller: vehicleCtrl, decoration: _deco('Vehicle', Icons.directions_car_rounded)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: type, items: [const DropdownMenuItem(value: 'platform', child: Text('Platform Driver')), const DropdownMenuItem(value: 'store', child: Text('Store Driver'))], onChanged: (v) { if (v != null) type = v; }, decoration: _deco('Driver Type', Icons.badge_rounded)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            await FirebaseFirestore.instance.collection('drivers').add({'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'vehicle': vehicleCtrl.text.trim(), 'type': type, 'isOnline': false, 'isActive': true, 'rating': 0.0, 'todayDeliveries': 0, 'todayEarnings': 0.0, 'createdAt': FieldValue.serverTimestamp()});
            if (ctx.mounted) Navigator.pop(ctx);
          }, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg))), child: const Text('Create')),
        ]),
      ])),
    ));
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
        final docs = snap.data!.docs;
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard,
            child: Row(children: [
              Text('Driver Management', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _showAddDriver, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Driver'), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)))),
            ]),
          ),
          Expanded(
            child: docs.isEmpty
                ? Center(child: Text('No drivers', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)))
                : ListView.builder(padding: const EdgeInsets.all(20), itemCount: docs.length, itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final online = d['isOnline'] == true;
                    final active = d['isActive'] != false;
                    final type = d['type'] as String? ?? 'platform';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
                      child: Row(children: [
                        Stack(children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: AdminColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: const Icon(Icons.delivery_dining_rounded, color: AdminColors.secondary)),
                          Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: online ? AdminColors.success : AdminColors.textLightMuted, shape: BoxShape.circle, border: Border.all(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, width: 2)))),
                        ],),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['name'] as String? ?? 'Unknown', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
                          const SizedBox(height: 2),
                          Text('${d['vehicle'] ?? 'N/A'} · ${d['todayDeliveries'] ?? 0} deliveries · $type driver', style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (online ? AdminColors.success : AdminColors.textLightMuted).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(online ? 'Online' : 'Offline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: online ? AdminColors.success : AdminColors.textLightMuted))),
                        const SizedBox(width: 8),
                        Switch(value: online, onChanged: (_) => _toggleOnline(docs[i].id, online), activeThumbColor: AdminColors.success),
                        if (active) IconButton(icon: const Icon(Icons.block_rounded, size: 18, color: AdminColors.danger), onPressed: () => _suspend(docs[i].id), constraints: const BoxConstraints(), padding: const EdgeInsets.all(6), tooltip: 'Suspend'),
                      ]),
                    );
                  }),
          ),
        ]);
      },
    );
  }
}