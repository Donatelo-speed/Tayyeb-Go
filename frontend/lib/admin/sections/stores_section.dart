import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class StoresSection extends StatefulWidget {
  const StoresSection({super.key});
  @override
  State<StoresSection> createState() => _StoresSectionState();
}

class _StoresSectionState extends State<StoresSection> {
  String _search = '';
  final _businessTypes = const ['Restaurant', 'Cafe', 'Bakery', 'Market', 'Supermarket', 'Pharmacy', 'Electronics', 'Flower Shop', 'Pet Store', 'Courier Partner'];

  Future<void> _toggleStore(String id, bool isOpen) async {
    try { await FirebaseFirestore.instance.collection('restaurants').doc(id).update({'isOpen': !isOpen}); } catch (_) {}
  }

  Future<void> _deleteStore(String id, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => _ConfirmDialog(title: 'Delete $name', message: 'This action cannot be undone.', confirmLabel: 'Delete', danger: true));
    if (ok == true) { await FirebaseFirestore.instance.collection('restaurants').doc(id).delete(); }
  }

  void _showCreateStore() => _showStoreDialog();

  void _showStoreDialog({String? id, Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final cuisineCtrl = TextEditingController(text: existing?['cuisine']);
    final phoneCtrl = TextEditingController(text: existing?['phone']);
    final addressCtrl = TextEditingController(text: existing?['address']);
    String type = existing?['businessType'] ?? 'Restaurant';
    final isEdit = id != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      backgroundColor: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard,
      child: Container(width: 520, padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isEdit ? 'Edit Store' : 'Create Store', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
        const SizedBox(height: 20),
        _buildField(nameCtrl, 'Store Name', Icons.store_rounded, isDark),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: type, decoration: _inputDeco('Business Type', Icons.business_rounded, isDark), items: _businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) { if (v != null) type = v; }),
        const SizedBox(height: 12),
        _buildField(cuisineCtrl, 'Cuisine / Category', Icons.restaurant_rounded, isDark),
        const SizedBox(height: 12),
        _buildField(phoneCtrl, 'Phone', Icons.phone_rounded, isDark),
        const SizedBox(height: 12),
        _buildField(addressCtrl, 'Address', Icons.location_on_rounded, isDark),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary))),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final data = <String, dynamic>{'name': nameCtrl.text.trim(), 'businessType': type, 'cuisine': cuisineCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'address': addressCtrl.text.trim(), 'updatedAt': FieldValue.serverTimestamp()};
            try {
              if (isEdit) { await FirebaseFirestore.instance.collection('restaurants').doc(id).update(data); }
              else { data['isOpen'] = true; data['rating'] = 0.0; data['commissionDebt'] = 0; data['commissionCeiling'] = 50000; data['createdAt'] = FieldValue.serverTimestamp(); await FirebaseFirestore.instance.collection('restaurants').add(data); }
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger)); }
          }, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg))), child: Text(isEdit ? 'Update' : 'Create')),
        ]),
      ]))),
    ));
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isDark) => InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)));
  Widget _buildField(TextEditingController ctrl, String label, IconData icon, bool isDark) => TextField(controller: ctrl, decoration: _inputDeco(label, icon, isDark));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _SkeletonLoader(isDark: isDark);
        if (!snap.hasData) return _ErrorState(isDark: isDark, onRetry: () => setState(() {}));
        var docs = snap.data!.docs;
        if (_search.isNotEmpty) docs = docs.where((d) => ((d.data() as Map)['name'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

        return Column(children: [
          _SectionHeader(isDark: isDark, title: 'Store Management', count: docs.length, onSearch: (v) => setState(() => _search = v), onAdd: _showCreateStore),
          Expanded(
            child: docs.isEmpty
                ? Center(child: _EmptyState(isDark: isDark, icon: Icons.store_rounded, title: 'No stores found', subtitle: 'Create your first store to get started'))
                : ListView.builder(padding: const EdgeInsets.all(20), itemCount: docs.length, itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final isOpen = d['isOpen'] == true;
                    return _StoreCard(isDark: isDark, name: d['name'] ?? 'Unnamed', type: d['businessType'] ?? d['cuisine'] ?? 'N/A', phone: d['phone'] ?? '—', address: d['address'] ?? '', isOpen: isOpen, onToggle: () => _toggleStore(docs[i].id, isOpen), onEdit: () => _showStoreDialog(id: docs[i].id, existing: d), onDelete: () => _deleteStore(docs[i].id, d['name'] ?? ''));
                  }),
          ),
        ]);
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final String title;
  final int count;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  const _SectionHeader({required this.isDark, required this.title, required this.count, required this.onSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, boxShadow: AdminShadows.topBar),
      child: Row(children: [
        Text(title, style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('$count', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
        const Spacer(),
        SizedBox(width: 200, child: TextField(onChanged: onSearch, decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search_rounded, size: 18), filled: true, fillColor: isDark ? AdminColors.bgDarkInput : AdminColors.bgLightInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
        const SizedBox(width: 8),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Create'), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)))),
      ]),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final bool isDark;
  final String name, type, phone, address;
  final bool isOpen;
  final VoidCallback onToggle, onEdit, onDelete;
  const _StoreCard({required this.isDark, required this.name, required this.type, required this.phone, required this.address, required this.isOpen, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: const Icon(Icons.store_rounded, color: AdminColors.primary, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(name, style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (isOpen ? AdminColors.success : AdminColors.danger).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOpen ? AdminColors.success : AdminColors.danger)))]),
          const SizedBox(height: 4),
          Text('$type · $phone · $address', style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Column(children: [
          IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AdminColors.info), onPressed: onEdit, constraints: const BoxConstraints(), padding: const EdgeInsets.all(6)),
          IconButton(icon: const Icon(Icons.delete_rounded, size: 18, color: AdminColors.danger), onPressed: onDelete, constraints: const BoxConstraints(), padding: const EdgeInsets.all(6)),
        ]),
        Switch(value: isOpen, onChanged: (_) => onToggle(), activeTrackColor: AdminColors.success.withValues(alpha: 0.3), activeThumbColor: AdminColors.success),
      ]),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final bool danger;
  const _ConfirmDialog({required this.title, required this.message, required this.confirmLabel, this.danger = false});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xl)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: danger ? AdminColors.danger : AdminColors.primary), child: Text(confirmLabel)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title, subtitle;
  const _EmptyState({required this.isDark, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: isDark ? AdminColors.textDarkMuted : AdminColors.textLightMuted),
      const SizedBox(height: 12),
      Text(title, style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
      const SizedBox(height: 4),
      Text(subtitle, style: isDark ? AdminTypography.caption(true) : AdminTypography.caption(false)),
    ]);
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorState({required this.isDark, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AdminColors.danger),
      const SizedBox(height: 12),
      Text('Failed to load data', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
    ]));
  }
}

class _SkeletonLoader extends StatelessWidget {
  final bool isDark;
  const _SkeletonLoader({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 8,
      itemBuilder: (_, _) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl)),
      ),
    );
  }
}