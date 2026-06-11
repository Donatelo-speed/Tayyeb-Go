import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Marketing', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabCtrl,
            labelColor: context.primaryColor,
            unselectedLabelColor: context.textMutedColor,
            indicatorColor: context.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: 'Campaigns'),
              Tab(icon: Icon(Icons.local_offer_rounded, size: 18), text: 'Coupons'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            _CampaignsTab(),
            _CouponsTab(),
          ],
        ),
      ),
    );
  }
}

class _CampaignsTab extends StatelessWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('campaigns').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: context.primaryColor));
        }
        final docs = snap.data!.docs;
        return Stack(
          children: [
            docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: context.borderColor),
                        const SizedBox(height: 12),
                        Text('No campaigns yet', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Create your first campaign to drive orders.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
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
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
                        ),
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
                                  Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                  const SizedBox(height: 2),
                                  Text('${type.toUpperCase()} · $redemptions redemptions', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) async {
                                try {
                                  await FirebaseFirestore.instance.collection('campaigns').doc(docs[i].id).update({'isActive': v});
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                                  }
                                }
                              },
                              activeColor: context.primaryColor,
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Campaign?'),
                                    content: Text('This will permanently delete "$name".'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: context.errorColor))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await FirebaseFirestore.instance.collection('campaigns').doc(docs[i].id).delete();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                    }
                                  }
                                }
                              },
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
                label: Text('New Campaign', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                backgroundColor: context.primaryColor,
                foregroundColor: context.textPrimaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'free_delivery': return Icons.local_shipping_rounded;
      case 'ramadan': return Icons.nightlight_round;
      case 'referral': return Icons.share_rounded;
      case 'new_store': return Icons.store_rounded;
      default: return Icons.campaign_rounded;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('New Campaign', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.inter(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Campaign name',
                    hintText: 'Ramadan Iftar Special',
                    labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                    hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  style: GoogleFonts.inter(color: context.textPrimaryColor),
                  dropdownColor: context.surfaceColor,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                  ),
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
                  value: reward,
                  style: GoogleFonts.inter(color: context.textPrimaryColor),
                  dropdownColor: context.surfaceColor,
                  decoration: InputDecoration(
                    labelText: 'Reward type',
                    labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                  ),
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
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
              style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: context.textPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
      stream: FirebaseFirestore.instance.collection('coupons').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: context.primaryColor));
        }
        final docs = snap.data!.docs;
        return Stack(
          children: [
            docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 64, color: context.borderColor),
                        const SizedBox(height: 12),
                        Text('No coupons yet', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Create a coupon to track usage and limits.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
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
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(code, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: context.primaryColor, letterSpacing: 0)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${discount.toStringAsFixed(0)}% off', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                  const SizedBox(height: 2),
                                  Text('Used $used of $max', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) async {
                                try {
                                  await FirebaseFirestore.instance.collection('coupons').doc(docs[i].id).update({'isActive': v});
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                                  }
                                }
                              },
                              activeColor: context.primaryColor,
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Coupon?'),
                                    content: Text('This will permanently delete coupon "$code".'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: context.errorColor))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await FirebaseFirestore.instance.collection('coupons').doc(docs[i].id).delete();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                    }
                                  }
                                }
                              },
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
                label: Text('New Coupon', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                backgroundColor: context.primaryColor,
                foregroundColor: context.textPrimaryColor,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Coupon', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Code',
                  hintText: 'TAYYEB10',
                  labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Discount %',
                  labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxUsesCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Max uses',
                  labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
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
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: context.textPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
