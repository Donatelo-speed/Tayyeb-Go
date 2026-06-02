import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class MarketingView extends StatefulWidget {
  const MarketingView({super.key});

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      title: 'Marketing & Coupons',
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.dividerColor.withValues(alpha: 0.3))),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: context.primaryColor,
              unselectedLabelColor: context.textSecondaryColor,
              indicatorColor: context.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.campaign, size: 18), text: 'Campaigns'),
                Tab(icon: Icon(Icons.local_offer, size: 18), text: 'Coupons'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _CampaignsTab(),
                _CouponsTab(),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class _CampaignsTab extends StatelessWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs;
        return Stack(
          children: [
            docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: context.textMutedColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('No campaigns yet', style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Create your first campaign to drive orders.', style: TextStyle(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final name = d['name'] as String? ?? 'Unnamed';
                      final type = d['type'] as String? ?? 'general';
                      final isActive = d['isActive'] as bool? ?? false;
                      final redemptions = (d['redemptions'] as num?)?.toInt() ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: cardDecoBordered(context),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(_iconForType(type), size: 20, color: context.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                  const SizedBox(height: 2),
                                  Text('${type.toUpperCase()} · $redemptions redemptions', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => FirebaseFirestore.instance.collection('campaigns').doc(docs[i].id).update({'isActive': v}),
                            ),
                            IconButton(
                              onPressed: () => FirebaseFirestore.instance.collection('campaigns').doc(docs[i].id).delete(),
                              icon: Icon(Icons.delete_outline, color: context.textMutedColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showCampaignDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Campaign'),
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'free_delivery': return Icons.local_shipping;
      case 'ramadan': return Icons.nightlight_round;
      case 'referral': return Icons.share;
      case 'new_store': return Icons.store;
      default: return Icons.campaign;
    }
  }

  void _showCampaignDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String type = 'free_delivery';
    String reward = 'free_delivery';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: context.surfaceColor,
          title: const Text('New Campaign'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Campaign name', hintText: 'Ramadan Iftar Special')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'free_delivery', child: Text('Free Delivery')),
                    DropdownMenuItem(value: 'ramadan', child: Text('Ramadan Offer')),
                    DropdownMenuItem(value: 'new_store', child: Text('New Store Launch')),
                    DropdownMenuItem(value: 'referral', child: Text('Referral Bonus')),
                    DropdownMenuItem(value: 'general', child: Text('General Discount')),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? 'general'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: reward,
                  decoration: const InputDecoration(labelText: 'Reward type'),
                  items: const [
                    DropdownMenuItem(value: 'free_delivery', child: Text('Free Delivery')),
                    DropdownMenuItem(value: 'percent_off', child: Text('Percent Off')),
                    DropdownMenuItem(value: 'amount_off', child: Text('Amount Off')),
                  ],
                  onChanged: (v) => setLocal(() => reward = v ?? 'free_delivery'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('campaigns').add({
                  'name': nameCtrl.text.trim().isEmpty ? 'Campaign' : nameCtrl.text.trim(),
                  'type': type,
                  'reward': reward,
                  'isActive': true,
                  'redemptions': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponsTab extends StatelessWidget {
  const _CouponsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coupons')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs;
        return Stack(
          children: [
            docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 64, color: context.textMutedColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('No coupons yet', style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Create a coupon to track usage and limits.', style: TextStyle(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final code = d['code'] as String? ?? 'NO-CODE';
                      final discount = (d['discountPercent'] as num?)?.toDouble() ?? 0;
                      final used = (d['usedCount'] as num?)?.toInt() ?? 0;
                      final max = (d['maxUses'] as num?)?.toInt() ?? 0;
                      final isActive = d['isActive'] as bool? ?? false;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: cardDecoBordered(context),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.primaryColor, letterSpacing: 1)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${discount.toStringAsFixed(0)}% off', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                  const SizedBox(height: 2),
                                  Text('Used $used of $max', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => FirebaseFirestore.instance.collection('coupons').doc(docs[i].id).update({'isActive': v}),
                            ),
                            IconButton(
                              onPressed: () => FirebaseFirestore.instance.collection('coupons').doc(docs[i].id).delete(),
                              icon: Icon(Icons.delete_outline, color: context.textMutedColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showCouponDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Coupon'),
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCouponDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '10');
    final maxUsesCtrl = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: const Text('New Coupon'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code', hintText: 'TAYYEB10')),
              const SizedBox(height: 12),
              TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount %')),
              const SizedBox(height: 12),
              TextField(controller: maxUsesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max uses')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('coupons').add({
                'code': codeCtrl.text.trim().toUpperCase(),
                'discountPercent': double.tryParse(discountCtrl.text) ?? 0,
                'maxUses': int.tryParse(maxUsesCtrl.text) ?? 0,
                'usedCount': 0,
                'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
