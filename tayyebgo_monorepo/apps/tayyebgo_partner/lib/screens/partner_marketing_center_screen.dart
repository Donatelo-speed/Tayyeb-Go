import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';

class PartnerMarketingCenterScreen extends StatelessWidget {
  const PartnerMarketingCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurantId = context.read<PartnerRoleController>().restaurantId;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Marketing Center', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsSection(restaurantId: restaurantId),
          const SizedBox(height: 24),
          _CouponsSection(restaurantId: restaurantId),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String? restaurantId;
  const _StatsSection({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final promosQuery = FirebaseFirestore.instance.collection('promos');
    final query = restaurantId != null
        ? promosQuery.where('restaurantId', isEqualTo: restaurantId)
        : promosQuery;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int activeCount = 0;
        int totalRedemptions = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final isActive = d['isActive'] as bool? ?? d['active'] as bool? ?? false;
          if (isActive) activeCount++;
          totalRedemptions += (d['usageCount'] as num?)?.toInt() ?? 0;
        }
        return Row(
          children: [
            Expanded(child: _miniStat(context, 'Active Promos', '$activeCount', context.warningColor)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat(context, 'Total Promos', '${docs.length}', context.successColor)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat(context, 'Redemptions', '$totalRedemptions', context.primaryColor)),
          ],
        );
      },
    );
  }

  Widget _miniStat(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CouponsSection extends StatelessWidget {
  final String? restaurantId;
  const _CouponsSection({this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Promo Codes', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showCreatePromoDialog(context, restaurantId),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('New', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: context.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: () {
            var q = FirebaseFirestore.instance.collection('promos').orderBy('createdAt', descending: true) as Query;
            if (restaurantId != null) {
              q = q.where('restaurantId', isEqualTo: restaurantId);
            }
            return q.snapshots();
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final code = d['code'] as String? ?? '';
                final type = d['type'] as String? ?? 'percentage';
                final value = (d['value'] as num?)?.toDouble() ?? 0;
                final isActive = d['isActive'] as bool? ?? d['active'] as bool? ?? false;
                final usageCount = (d['usageCount'] as num?)?.toInt() ?? 0;
                final usageLimit = (d['usageLimit'] as num?)?.toInt() ?? 0;
                final expiryDate = (d['expiryDate'] as Timestamp?)?.toDate();
                final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppRadius.brXl,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isActive && !isExpired
                              ? context.successColor.withValues(alpha: 0.1)
                              : context.errorColor.withValues(alpha: 0.1),
                          borderRadius: AppRadius.brMd,
                        ),
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: isActive && !isExpired ? context.successColor : context.errorColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(code, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive && !isExpired
                                        ? context.successColor.withValues(alpha: 0.1)
                                        : context.errorColor.withValues(alpha: 0.1),
                                    borderRadius: AppRadius.brSm,
                                  ),
                                  child: Text(
                                    isActive && !isExpired ? 'Active' : (isExpired ? 'Expired' : 'Inactive'),
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isActive && !isExpired ? context.successColor : context.errorColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$type — ${type == 'percentage' ? '${value.toStringAsFixed(0)}%' : '\$${value.toStringAsFixed(2)}'} off',
                              style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
                            ),
                            if (usageLimit > 0)
                              Text(
                                '$usageCount / $usageLimit uses',
                                style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: context.successColor,
                        onChanged: (v) async {
                          try {
                            await doc.reference.update({
                              'isActive': v,
                              'active': v,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.errorColor),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Promo'),
                              content: Text('Delete promo code "$code"? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: context.errorColor))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await doc.reference.delete();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.local_offer_outlined, size: 48, color: context.textMutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No promo codes yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            const SizedBox(height: 8),
            Text('Create a promo to attract customers', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
          ],
        ),
      ),
    );
  }
}

void _showCreatePromoDialog(BuildContext context, String? restaurantId) {
  final codeCtrl = TextEditingController();
  final valueCtrl = TextEditingController(text: '10');
  final minOrderCtrl = TextEditingController(text: '0');
  final usageLimitCtrl = TextEditingController(text: '0');
  String type = 'percentage';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) => AlertDialog(
        title: const Text('New Promo Code'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Coupon Code', hintText: 'SUMMER20'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                  DropdownMenuItem(value: 'flat', child: Text('Flat Amount')),
                ],
                onChanged: (v) => setLocalState(() => type = v ?? 'percentage'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: type == 'percentage' ? 'Discount %' : 'Discount Amount (\$)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Order Amount (\$)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usageLimitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Usage Limit (0 = unlimited)'),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              try {
                final code = codeCtrl.text.trim().toUpperCase();
                final value = double.tryParse(valueCtrl.text.trim()) ?? 10;
                final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0;
                final usageLimit = int.tryParse(usageLimitCtrl.text.trim()) ?? 0;
                await FirebaseFirestore.instance.collection('promos').add({
                  'code': code,
                  'type': type,
                  'value': value,
                  'minOrder': minOrder,
                  'minOrderAmount': minOrder,
                  'active': true,
                  'isActive': true,
                  'usageCount': 0,
                  'usageLimit': usageLimit,
                  if (restaurantId != null) 'restaurantId': restaurantId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to create promo: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
