import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});
  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  String _search = '';
  String _statusFilter = 'all';

  Future<void> _updateStatus(String id, String status, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection('drivers').doc(id).update({
        'status': status,
        'isOnline': status == 'online',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger));
    }
  }

  Future<void> _deleteDriver(String id, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AdminConfirmDialog(title: 'Delete $name', message: 'This action cannot be undone.', confirmLabel: 'Delete', danger: true));
    if (ok == true) { await FirebaseFirestore.instance.collection('drivers').doc(id).delete(); }
  }

  void _showDriverDialog({String? id, Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? existing?['displayName']);
    final emailCtrl = TextEditingController(text: existing?['email']);
    final phoneCtrl = TextEditingController(text: existing?['phone']);
    final vehicleCtrl = TextEditingController(text: existing?['vehicleType']);
    final plateCtrl = TextEditingController(text: existing?['vehiclePlate']);
    String driverType = existing?['driverType'] ?? 'platform';
    String? storeId = existing?['storeId'];
    final isEdit = id != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      backgroundColor: AdminColors.card(isDark),
      child: Container(width: 520, padding: const EdgeInsets.all(AdminSpacing.xxl), child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEdit ? 'Edit Driver' : 'Add Driver', style: AdminTypography.h2(isDark)),
          const SizedBox(height: AdminSpacing.xl),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded, size: 20))),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded, size: 20)), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded, size: 20)), keyboardType: TextInputType.phone),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.directions_car_rounded, size: 20))),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Vehicle Plate', prefixIcon: Icon(Icons.confirmation_number_rounded, size: 20))),
          const SizedBox(height: AdminSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: driverType,
            decoration: const InputDecoration(labelText: 'Driver Type', prefixIcon: Icon(Icons.badge_rounded, size: 20)),
            items: const [
              DropdownMenuItem(value: 'platform', child: Text('Platform Driver')),
              DropdownMenuItem(value: 'store', child: Text('Store Driver')),
            ],
            onChanged: (v) => setState(() => driverType = v ?? 'platform'),
          ),
          const SizedBox(height: AdminSpacing.xxl),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AdminColors.textSecondary(isDark)))),
            const SizedBox(width: AdminSpacing.md),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final data = <String, dynamic>{
                'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(), 'phone': phoneCtrl.text.trim(),
                'vehicleType': vehicleCtrl.text.trim(), 'vehiclePlate': plateCtrl.text.trim(),
                'driverType': driverType, 'updatedAt': FieldValue.serverTimestamp(),
              };
              if (storeId != null) data['storeId'] = storeId;
              try {
                if (isEdit) { await FirebaseFirestore.instance.collection('drivers').doc(id).update(data); }
                else { data['isOnline'] = false; data['status'] = 'offline'; data['isVerified'] = false; data['totalOrders'] = 0; data['completedOrders'] = 0; data['rating'] = 0.0; data['walletBalance'] = 0; data['totalEarnings'] = 0; data['createdAt'] = FieldValue.serverTimestamp(); await FirebaseFirestore.instance.collection('drivers').add(data); }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger)); }
}, child: Text(isEdit ? 'Update' : 'Add Driver')),
          ]),
        ]),
      )),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const statuses = ['all', 'online', 'offline', 'busy', 'suspended'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        var docs = snap.data!.docs;
        if (_search.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map;
            final name = (data['name'] ?? data['displayName'] as String? ?? '').toLowerCase();
            final email = (data['email'] as String? ?? '').toLowerCase();
            final q = _search.toLowerCase();
            return name.contains(q) || email.contains(q);
          }).toList();
        }
        if (_statusFilter != 'all') {
          docs = docs.where((d) {
            final data = d.data() as Map;
            final status = data['status'] as String? ?? (data['isOnline'] == true ? 'online' : 'offline');
            return status == _statusFilter;
          }).toList();
        }

        return Column(children: [
          AdminSectionHeader(
            title: 'Driver Management',
            count: docs.length,
            searchHint: 'Search drivers...',
            addLabel: 'Add Driver',
            onAdd: () => _showDriverDialog(),
            onSearch: (v) => setState(() => _search = v),
            filterChips: statuses.map((s) => Padding(
              padding: const EdgeInsets.only(right: AdminSpacing.sm),
              child: FilterChip(
                label: Text(s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1), style: const TextStyle(fontSize: 11)),
                selected: _statusFilter == s,
                onSelected: (v) => setState(() => _statusFilter = v ? s : 'all'),
                selectedColor: AdminColors.statusColor(s).withValues(alpha: 0.15),
              ),
            )).toList(),
          ),
          Expanded(
            child: docs.isEmpty
                ? const AdminEmptyState(icon: Icons.delivery_dining_rounded, title: 'No drivers found', subtitle: 'Add your first driver to get started', actionLabel: 'Add Driver')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final status = d['status'] as String? ?? (d['isOnline'] == true ? 'online' : 'offline');
                      final name = d['name'] ?? d['displayName'] as String? ?? 'Unknown';
                      final type = d['driverType'] as String? ?? 'platform';
                      final vehicle = d['vehicleType'] as String? ?? 'N/A';
                      final verified = d['isVerified'] == true;
                      final orders = d['totalOrders'] ?? 0;
                      final completed = d['completedOrders'] ?? 0;
                      final rating = (d['rating'] as num?)?.toDouble() ?? 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AdminColors.statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AdminRadius.lg),
                            ),
                            child: Icon(Icons.delivery_dining_rounded, color: AdminColors.statusColor(status), size: 24),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(name, style: AdminTypography.h4(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminStatusBadge(status: status),
                              const SizedBox(width: AdminSpacing.xs),
                              AdminBadge(label: type.toUpperCase(), color: AdminColors.info),
                              if (verified) const AdminBadge(label: 'VERIFIED', color: AdminColors.success),
                            ]),
                            const SizedBox(height: 4),
                            Text('$vehicle  ·  $completed/$orders orders  ·  ${rating.toStringAsFixed(1)} ⭐', style: AdminTypography.bodySmall(isDark)),
                          ])),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18),
                            onSelected: (v) {
                              if (v == 'delete') { _deleteDriver(docs[i].id, name); }
                              else { _updateStatus(docs[i].id, v, v == 'online'); }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'online', child: Text('Set Online')),
                              const PopupMenuItem(value: 'offline', child: Text('Set Offline')),
                              const PopupMenuItem(value: 'busy', child: Text('Set Busy')),
                              const PopupMenuItem(value: 'suspended', child: Text('Suspend')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AdminColors.danger))),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AdminColors.info), onPressed: () => _showDriverDialog(id: docs[i].id, existing: d), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}