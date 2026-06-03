import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});
  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  void _showCampaignDialog({String? id, Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final descCtrl = TextEditingController(text: existing?['description']);
    final valueCtrl = TextEditingController(text: existing?['value']?.toString());
    String type = existing?['type'] ?? 'percentage';
    String audience = existing?['targetAudience'] ?? 'all';
    final isEdit = id != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      backgroundColor: AdminColors.card(isDark),
      child: Container(width: 480, padding: const EdgeInsets.all(AdminSpacing.xxl), child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEdit ? 'Edit Campaign' : 'Create Campaign', style: AdminTypography.h2(isDark)),
          const SizedBox(height: AdminSpacing.xl),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Campaign Name', prefixIcon: Icon(Icons.campaign_rounded, size: 20))),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded, size: 20)), maxLines: 2),
          const SizedBox(height: AdminSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Discount Type', prefixIcon: Icon(Icons.discount_rounded, size: 20)),
            items: const [
              DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount')),
              DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
              DropdownMenuItem(value: 'free_delivery', child: Text('Free Delivery')),
            ],
            onChanged: (v) => setState(() => type = v ?? 'percentage'),
          ),
          const SizedBox(height: AdminSpacing.md),
          TextField(controller: valueCtrl, decoration: InputDecoration(labelText: type == 'percentage' ? 'Discount %' : 'Amount (\$)', prefixIcon: const Icon(Icons.monetization_on_rounded, size: 20)), keyboardType: TextInputType.number),
          const SizedBox(height: AdminSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: audience,
            decoration: const InputDecoration(labelText: 'Target Audience', prefixIcon: Icon(Icons.group_rounded, size: 20)),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'customers', child: Text('Customers Only')),
              DropdownMenuItem(value: 'drivers', child: Text('Drivers Only')),
              DropdownMenuItem(value: 'stores', child: Text('Store Owners')),
            ],
            onChanged: (v) => setState(() => audience = v ?? 'all'),
          ),
          const SizedBox(height: AdminSpacing.xxl),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AdminColors.textSecondary(isDark)))),
            const SizedBox(width: AdminSpacing.md),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final data = <String, dynamic>{
                'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(),
                'type': type, 'value': double.tryParse(valueCtrl.text.trim()) ?? 0,
                'targetAudience': audience, 'updatedAt': FieldValue.serverTimestamp(),
              };
              try {
                if (isEdit) { await FirebaseFirestore.instance.collection('campaigns').doc(id).update(data); }
                else { data['isActive'] = false; data['createdAt'] = FieldValue.serverTimestamp(); await FirebaseFirestore.instance.collection('campaigns').add(data); }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger)); }
            }, child: Text(isEdit ? 'Update' : 'Create Campaign')),
          ]),
        ]),
      ),
    )));
  }

  Future<void> _toggleActive(String id, bool active) async {
    try { await FirebaseFirestore.instance.collection('campaigns').doc(id).update({'isActive': !active}); } catch (_) {}
  }

  Future<void> _deleteCampaign(String id, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AdminConfirmDialog(title: 'Delete $name', message: 'This campaign will be permanently removed.', confirmLabel: 'Delete', danger: true));
    if (ok == true) { await FirebaseFirestore.instance.collection('campaigns').doc(id).delete(); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        final docs = snap.data!.docs;
        return Column(children: [
          AdminSectionHeader(
            title: 'Marketing Campaigns', count: docs.length,
            addLabel: 'Create Campaign',
            onAdd: () => _showCampaignDialog(),
          ),
          Expanded(
            child: docs.isEmpty
                ? const AdminEmptyState(icon: Icons.campaign_rounded, title: 'No campaigns', subtitle: 'Create your first marketing campaign', actionLabel: 'Create Campaign')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final name = d['name'] ?? 'Unnamed';
                      final type = d['type'] as String? ?? 'percentage';
                      final value = (d['value'] as num?)?.toDouble() ?? 0;
                      final audience = d['targetAudience'] as String? ?? 'all';
                      final isActive = d['isActive'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: (isActive ? AdminColors.success : AdminColors.slate400).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)),
                            child: Icon(Icons.campaign_rounded, color: isActive ? AdminColors.success : AdminColors.slate400, size: 22),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(name, style: AdminTypography.h4(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminStatusBadge(status: isActive ? 'active' : 'inactive'),
                            ]),
                            const SizedBox(height: 4),
                            Text('${type == 'percentage' ? '$value% off' : type == 'fixed' ? '\$$value off' : 'Free Delivery'}  ·  $audience', style: AdminTypography.bodySmall(isDark)),
                          ])),
                          IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AdminColors.info), onPressed: () => _showCampaignDialog(id: docs[i].id, existing: d), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          IconButton(icon: const Icon(Icons.delete_rounded, size: 18, color: AdminColors.danger), onPressed: () => _deleteCampaign(docs[i].id, name), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          Switch(value: isActive, onChanged: (_) => _toggleActive(docs[i].id, isActive), activeTrackColor: AdminColors.success.withValues(alpha: 0.3), activeThumbColor: AdminColors.success),
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