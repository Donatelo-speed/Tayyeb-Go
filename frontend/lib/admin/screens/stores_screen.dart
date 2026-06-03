import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});
  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  String _search = '';
  String _filterType = 'All';

  Future<void> _toggleStore(String id, bool isOpen) async {
    try { await FirebaseFirestore.instance.collection('restaurants').doc(id).update({'isOpen': !isOpen}); } catch (_) {}
  }

  Future<void> _deleteStore(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminConfirmDialog(title: 'Delete $name', message: 'This action cannot be undone.', confirmLabel: 'Delete', danger: true),
    );
    if (ok == true) { await FirebaseFirestore.instance.collection('restaurants').doc(id).delete(); }
  }

  void _showStoreDialog({String? id, Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final cuisineCtrl = TextEditingController(text: existing?['cuisine']);
    final phoneCtrl = TextEditingController(text: existing?['phone']);
    final addressCtrl = TextEditingController(text: existing?['address']);
    final latCtrl = TextEditingController(text: existing?['lat']?.toString());
    final lngCtrl = TextEditingController(text: existing?['lng']?.toString());
    String type = existing?['businessType'] ?? 'Restaurant';
    String deliveryMode = existing?['deliveryMode'] ?? 'platform';
    bool fallbackEnabled = existing?['fallbackEnabled'] ?? true;
    int fallbackDelay = existing?['fallbackDelayMinutes'] ?? 10;
    final isEdit = id != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      backgroundColor: AdminColors.card(isDark),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? 'Edit Store' : 'Create Business', style: AdminTypography.h2(isDark)),
            const SizedBox(height: AdminSpacing.xl),
            _buildField(nameCtrl, 'Business Name', Icons.store_rounded, isDark),
            const SizedBox(height: AdminSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: InputDecoration(labelText: 'Business Type', prefixIcon: const Icon(Icons.business_rounded, size: 20)),
              items: businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) { if (v != null) type = v; },
            ),
            const SizedBox(height: AdminSpacing.md),
            _buildField(cuisineCtrl, 'Cuisine / Category', Icons.restaurant_rounded, isDark),
            const SizedBox(height: AdminSpacing.md),
            _buildField(phoneCtrl, 'Phone', Icons.phone_rounded, isDark),
            const SizedBox(height: AdminSpacing.md),
            _buildField(addressCtrl, 'Address', Icons.location_on_rounded, isDark),
            const SizedBox(height: AdminSpacing.md),
            Row(children: [
              Expanded(child: _buildField(latCtrl, 'Latitude', Icons.map_rounded, isDark)),
              const SizedBox(width: AdminSpacing.md),
              Expanded(child: _buildField(lngCtrl, 'Longitude', Icons.map_rounded, isDark)),
            ]),
            const SizedBox(height: AdminSpacing.lg),
            Text('Delivery Mode', style: AdminTypography.h4(isDark)),
            const SizedBox(height: AdminSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: deliveryMode,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.delivery_dining_rounded, size: 20)),
              items: deliveryModes.map((m) => DropdownMenuItem(value: m, child: Text(m.replaceFirst(m[0], m[0].toUpperCase())))).toList(),
              onChanged: (v) => setState(() => deliveryMode = v ?? 'platform'),
            ),
            if (deliveryMode == 'hybrid') ...[
              const SizedBox(height: AdminSpacing.md),
              Row(children: [
                Text('Fallback to platform drivers', style: AdminTypography.body(isDark)),
                const Spacer(),
                Switch(value: fallbackEnabled, onChanged: (v) => setState(() => fallbackEnabled = v)),
              ]),
              if (fallbackEnabled) ...[
                const SizedBox(height: AdminSpacing.sm),
                Row(children: [
                  Text('Fallback delay (minutes)', style: AdminTypography.bodySmall(isDark)),
                  const Spacer(),
                  SizedBox(width: 80, child: TextField(
                    controller: TextEditingController(text: fallbackDelay.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => fallbackDelay = int.tryParse(v) ?? 10,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  )),
                ]),
              ],
            ],
            const SizedBox(height: AdminSpacing.xxl),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AdminColors.textSecondary(isDark)))),
              const SizedBox(width: AdminSpacing.md),
              ElevatedButton(onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(), 'businessType': type, 'cuisine': cuisineCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(), 'address': addressCtrl.text.trim(),
                  'deliveryMode': deliveryMode, 'fallbackEnabled': fallbackEnabled, 'fallbackDelayMinutes': fallbackDelay,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                final lat = double.tryParse(latCtrl.text.trim());
                final lng = double.tryParse(lngCtrl.text.trim());
                if (lat != null) data['lat'] = lat;
                if (lng != null) data['lng'] = lng;
                try {
                  if (isEdit) { await FirebaseFirestore.instance.collection('restaurants').doc(id).update(data); }
                  else { data['isOpen'] = true; data['rating'] = 0.0; data['commissionDebt'] = 0; data['commissionRate'] = 15; data['createdAt'] = FieldValue.serverTimestamp(); await FirebaseFirestore.instance.collection('restaurants').add(data); }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger)); }
              }, child: Text(isEdit ? 'Update' : 'Create Business')),
            ]),
          ]),
        ),
      ),
    ));
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, bool isDark) => TextField(controller: ctrl, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        var docs = snap.data!.docs;
        if (_search.isNotEmpty) docs = docs.where((d) => ((d.data() as Map)['name'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
        if (_filterType != 'All') docs = docs.where((d) => ((d.data() as Map)['businessType'] as String? ?? '') == _filterType).toList();

        return Column(children: [
          AdminSectionHeader(
            title: 'Store Management',
            count: docs.length,
            searchHint: 'Search stores...',
            addLabel: 'Create Business',
            onAdd: () => _showStoreDialog(),
            onSearch: (v) => setState(() => _search = v),
            filterChips: businessTypes.take(6).map((t) => Padding(
              padding: const EdgeInsets.only(right: AdminSpacing.sm),
              child: FilterChip(
                label: Text(t, style: const TextStyle(fontSize: 11)),
                selected: _filterType == t,
                onSelected: (v) => setState(() => _filterType = v ? t : 'All'),
              ),
            )).toList(),
          ),
          Expanded(
            child: docs.isEmpty
                ? const AdminEmptyState(icon: Icons.store_rounded, title: 'No stores found', subtitle: 'Create your first business to get started', actionLabel: 'Create Business')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final isOpen = d['isOpen'] == true;
                      final isSuspended = d['isSuspended'] == true;
                      final type = d['businessType'] ?? d['cuisine'] ?? 'N/A';
                      final mode = d['deliveryMode'] ?? 'platform';
                      final orders = d['orderCount'] ?? d['totalOrders'] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AdminColors.primary.withValues(alpha: 0.1), AdminColors.primary.withValues(alpha: 0.05)]),
                              borderRadius: BorderRadius.circular(AdminRadius.lg),
                            ),
                            child: const Icon(Icons.store_rounded, color: AdminColors.primary, size: 24),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(d['name'] ?? 'Unnamed', style: AdminTypography.h4(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminBadge(label: type, color: AdminColors.primary),
                              if (isSuspended) const Padding(padding: EdgeInsets.only(left: 4), child: AdminBadge(label: 'SUSPENDED', color: AdminColors.danger)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('${d['phone'] ?? 'No phone'}  ·  ${d['address'] ?? 'No address'}', style: AdminTypography.bodySmall(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminBadge(label: mode.toUpperCase(), color: mode == 'hybrid' ? const Color(0xFF7C3AED) : AdminColors.info),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('$orders orders', style: AdminTypography.caption(isDark)),
                              const SizedBox(width: AdminSpacing.md),
                              Icon(Icons.star_rounded, size: 12, color: AdminColors.warning),
                              Text(' ${(d['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}', style: AdminTypography.caption(isDark)),
                            ]),
                          ])),
                          Row(children: [
                            IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AdminColors.info), onPressed: () => _showStoreDialog(id: docs[i].id, existing: d), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.delete_rounded, size: 18, color: AdminColors.danger), onPressed: () => _deleteStore(docs[i].id, d['name'] ?? ''), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: AdminSpacing.sm),
                            Switch(value: isOpen, onChanged: (_) => _toggleStore(docs[i].id, isOpen), activeTrackColor: AdminColors.success.withValues(alpha: 0.3), activeThumbColor: AdminColors.success),
                          ]),
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