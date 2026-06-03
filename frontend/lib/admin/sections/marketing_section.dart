import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class MarketingSection extends StatefulWidget {
  const MarketingSection({super.key});
  @override
  State<MarketingSection> createState() => _MarketingSectionState();
}

class _MarketingSectionState extends State<MarketingSection> {
  void _showCreateCampaign() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '10');
    String type = 'percentage';
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
      child: Container(width: 480, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create Campaign', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)), const SizedBox(height: 16),
        TextField(controller: nameCtrl, decoration: _deco('Campaign Name')), const SizedBox(height: 12),
        TextField(controller: descCtrl, decoration: _deco('Description'), maxLines: 2), const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: type, items: const [DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount')), DropdownMenuItem(value: 'fixed', child: Text('Fixed Discount')), DropdownMenuItem(value: 'free_delivery', child: Text('Free Delivery'))], onChanged: (v) { if (v != null) type = v; }, decoration: _deco('Type')),
        const SizedBox(height: 12),
        TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: _deco('Value')),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            await FirebaseFirestore.instance.collection('campaigns').add({'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'type': type, 'value': double.tryParse(discountCtrl.text) ?? 10, 'active': true, 'createdAt': FieldValue.serverTimestamp()});
            if (ctx.mounted) Navigator.pop(ctx);
          }, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg))), child: const Text('Create')),
        ]),
      ])),
    ));
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('campaigns').orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
        return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Marketing Campaigns', style: isDark ? AdminTypography.h2(true) : AdminTypography.h2(false)),
            const Spacer(),
            ElevatedButton.icon(onPressed: _showCreateCampaign, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('New Campaign'), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)))),
          ]),
          const SizedBox(height: 20),
          if (docs.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(48), child: Text('No campaigns yet', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false))))
          else ...docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final active = d['active'] == true;
            final type = d['type'] ?? 'percentage';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: const Icon(Icons.campaign_rounded, color: AdminColors.warning, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['name'] as String? ?? 'N/A', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
                    const SizedBox(height: 2),
                    Text(d['description'] as String? ?? '', style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (active ? AdminColors.success : AdminColors.textLightMuted).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? AdminColors.success : AdminColors.textLightMuted))),
                  Switch(value: active, onChanged: (v) async { await FirebaseFirestore.instance.collection('campaigns').doc(doc.id).update({'active': v}); }, activeThumbColor: AdminColors.success),
                ]),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkSurface : AdminColors.bgLightSurface, borderRadius: BorderRadius.circular(8)), child: Text(type == 'free_delivery' ? 'FREE DELIVERY' : type == 'percentage' ? '${d['value']}% OFF' : '\$${d['value']} OFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminColors.warning))),
              ]),
            );
          }),
        ]));
      },
    );
  }
}