import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class ZonesView extends StatelessWidget {
  const ZonesView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      title: 'Delivery Zones',
      actions: [
        TextButton.icon(
          onPressed: () => _showZoneDialog(context, null),
          icon: const Icon(Icons.add),
          label: const Text('New Zone'),
        ),
      ],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('zones')
            .orderBy('name')
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 120);
          final docs = snap.data!.docs;
          if (docs.isEmpty) return _buildEmptyState(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 500 ? 1 : constraints.maxWidth < 900 ? 2 : 3;
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _zoneCard(context, d, docs[i].id);
                },
              );
            },
          );
        },
      ),
    ));
  }

  Widget _zoneCard(BuildContext context, Map<String, dynamic> d, String id) {
    final name = d['name'] as String? ?? 'Unnamed Zone';
    final fee = (d['deliveryFee'] as num?)?.toDouble() ?? 0;
    final driverCount = (d['driverCount'] as num?)?.toInt() ?? 0;
    final avgTime = (d['avgDeliveryTime'] as num?)?.toDouble() ?? 0;
    final demand = d['demandLevel'] as String? ?? 'low';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showZoneDialog(context, d..['id'] = id),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoBordered(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on, size: 18, color: context.primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                  ),
                  _demandBadge(demand),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _stat(context, Icons.local_shipping, '$driverCount', 'Drivers'),
                  const SizedBox(width: 12),
                  _stat(context, Icons.attach_money, fee.toStringAsFixed(0), 'Fee'),
                  const SizedBox(width: 12),
                  _stat(context, Icons.timer, '${avgTime.toInt()}', 'Min'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: context.textMutedColor),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          ]),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: context.textMutedColor)),
        ],
      ),
    );
  }

  Widget _demandBadge(String demand) {
    final color = demand == 'high' ? AppColors.error : demand == 'medium' ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(demand.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 64, color: context.textMutedColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No delivery zones yet', style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('Add Homs neighborhoods to define service areas, delivery fees, and demand levels.', style: TextStyle(color: context.textMutedColor, fontSize: 13), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showZoneDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Create First Zone'),
          ),
        ],
      ),
    );
  }

  void _showZoneDialog(BuildContext context, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final feeCtrl = TextEditingController(text: (existing?['deliveryFee'] as num?)?.toString() ?? '');
    final driversCtrl = TextEditingController(text: (existing?['driverCount'] as num?)?.toString() ?? '');
    final avgTimeCtrl = TextEditingController(text: (existing?['avgDeliveryTime'] as num?)?.toString() ?? '');
    String demand = existing?['demandLevel'] as String? ?? 'medium';
    bool isActive = existing?['isActive'] as bool? ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Text(isEdit ? 'Edit Zone' : 'New Zone'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Zone name', hintText: 'Al Waer, Bab Amr, etc.'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Delivery fee'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: driversCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Target drivers'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avgTimeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Avg delivery time (min)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: demand,
                    decoration: const InputDecoration(labelText: 'Demand level'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setLocal(() => demand = v ?? 'medium'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isActive,
                    title: const Text('Active'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setLocal(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('zones').doc(existing['id'] as String).delete();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameCtrl.text.trim(),
                  'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                  'driverCount': int.tryParse(driversCtrl.text) ?? 0,
                  'avgDeliveryTime': double.tryParse(avgTimeCtrl.text) ?? 0,
                  'demandLevel': demand,
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (isEdit) {
                  await FirebaseFirestore.instance.collection('zones').doc(existing['id'] as String).update(data);
                } else {
                  data['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('zones').add(data);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
