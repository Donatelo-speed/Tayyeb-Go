import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

const _purple = Color(0xFF8B5CF6);

class DriversView extends StatefulWidget {
  const DriversView();
  @override
  State<DriversView> createState() => _DriversViewState();
}

class _DriversViewState extends State<DriversView> {
  String _driverTypeFilter = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Drivers', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.inter(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Search drivers...',
                        hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                        prefixIcon: Icon(Icons.search_rounded, color: context.textMutedColor, size: 20),
                        filled: true,
                        fillColor: context.surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.primaryColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(context, 'All', 'all'),
                  const SizedBox(width: 4),
                  _filterChip(context, 'Platform', 'platform'),
                  const SizedBox(width: 4),
                  _filterChip(context, 'Store', 'store'),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').limit(500).snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: context.primaryColor));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error loading drivers', style: GoogleFonts.inter(color: context.textMutedColor)));
                  }
                  var docs = snap.data?.docs ?? [];
                  if (_driverTypeFilter != 'all') {
                    docs = docs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return (d['driverType'] as String? ?? 'platform') == _driverTypeFilter;
                    }).toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    docs = docs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name = (d['displayName'] as String? ?? '').toLowerCase();
                      final email = (d['email'] as String? ?? '').toLowerCase();
                      return name.contains(q) || email.contains(q);
                    }).toList();
                  }
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delivery_dining_outlined, size: 64, color: context.borderColor),
                          const SizedBox(height: 12),
                          Text('No drivers registered', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final displayName = d['displayName'] as String? ?? d['email'] as String? ?? 'Unknown';
                      final email = d['email'] as String? ?? '';
                      final isOnline = d['isActive'] == true;
                      final driverType = d['driverType'] as String? ?? 'platform';
                      final storeId = d['storeId'] as String? ?? '';
                      final rating = (d['rating'] as num?)?.toDouble() ?? 0;
                      final ordersCompleted = (d['ordersCompleted'] as num?)?.toInt() ?? 0;
                      final earnings = (d['earnings'] as num?)?.toDouble() ?? 0;
                      final isVerified = d['isVerified'] as bool? ?? false;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: context.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: context.primaryColor)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(displayName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                          const SizedBox(width: 6),
                                          _driverTypeBadge(context, driverType),
                                          if (isVerified) ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.verified, size: 14, color: context.primaryColor),
                                          ],
                                        ],
                                      ),
                                      Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (rating > 0)
                                  Row(
                                    children: [
                                      Icon(Icons.star_rounded, size: 16, color: context.warningColor),
                                      Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                                    ],
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isOnline ? context.successColor : context.textMutedColor).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(isOnline ? 'Active' : 'Inactive', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isOnline ? context.successColor : context.textMutedColor)),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'approve') _approveDriver(context, id, displayName);
                                    if (v == 'suspend') _suspendDriver(context, id, displayName);
                                    if (v == 'verify') _verifyDriver(context, id, isVerified);
                                    if (v == 'assign') _showAssignStoreDialog(context, id, displayName, driverType, storeId);
                                    if (v == 'reset') _resetDriverAccount(context, id, displayName);
                                  },
                                  icon: Icon(Icons.more_vert_rounded, color: context.textMutedColor, size: 20),
                                  color: context.surfaceColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.check_circle, size: 20, color: context.successColor), title: Text('Approve'))),
                                    if (isOnline) PopupMenuItem(value: 'suspend', child: ListTile(leading: Icon(Icons.pause_circle, size: 20, color: context.warningColor), title: Text('Suspend'))),
                                    PopupMenuItem(value: 'verify', child: ListTile(leading: Icon(Icons.verified, size: 20, color: context.primaryColor), title: Text('Verify/Unverify'))),
                                    if (driverType == 'store') const PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.store, size: 20), title: Text('Assign Store'))),
                                    const PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(Icons.refresh, size: 20), title: Text('Reset Stats'))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _driverStat(context, Icons.shopping_bag_rounded, '$ordersCompleted', 'Orders', context.primaryColor),
                                const SizedBox(width: 16),
                                _driverStat(context, Icons.attach_money_rounded, '\$${earnings.toStringAsFixed(0)}', 'Earnings', context.successColor),
                                const SizedBox(width: 16),
                                _driverStat(context, Icons.person_pin_rounded, driverType.replaceAll('_', ' ').toUpperCase(), 'Type', _purple),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String value) {
    final selected = _driverTypeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _driverTypeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? context.primaryColor : context.borderColor),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? context.textPrimaryColor : context.textMutedColor)),
      ),
    );
  }

  Widget _driverTypeBadge(BuildContext context, String type) {
    final c = type == 'platform' ? context.successColor : context.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(type.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _driverStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
      ],
    );
  }

  void _showAssignStoreDialog(BuildContext context, String driverId, String driverName, String driverType, String currentStoreId) {
    final storeCtrl = TextEditingController(text: currentStoreId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Assign Store', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign "$driverName" to a store:', style: GoogleFonts.inter(color: context.textPrimaryColor)),
              const SizedBox(height: 16),
              TextField(
                controller: storeCtrl,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Store ID',
                  hintText: 'Enter store document ID',
                  labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                ),
              ),
              const SizedBox(height: 8),
              Text('Leave empty to unassign from current store', style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
          ElevatedButton(
            onPressed: () async {
              final storeId = storeCtrl.text.trim();
              try {
                await FirebaseFirestore.instance.collection('users').doc(driverId).update({
                  'storeId': storeId.isEmpty ? FieldValue.delete() : storeId,
                  'driverType': storeId.isEmpty ? 'platform' : 'store',
                });
                if (ctx.mounted) {
                  ctx.showSuccess(storeId.isEmpty ? '$driverName unassigned' : '$driverName assigned to store');
                }
              } catch (e) {
                if (ctx.mounted) ctx.showError('Failed to assign store');
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: context.textPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveDriver(BuildContext context, String id, String name) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({'isActive': true, 'approvedAt': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('activity_log').add({
        'text': 'Driver "$name" approved',
        'color': 'green',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSuccess('$name approved');
    } catch (e) {
      if (context.mounted) context.showError('Failed to approve driver');
    }
  }

  Future<void> _suspendDriver(BuildContext context, String id, String name) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({'isActive': false, 'suspendedAt': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('activity_log').add({
        'text': 'Driver "$name" suspended',
        'color': 'orange',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSuccess('$name suspended');
    } catch (e) {
      if (context.mounted) context.showError('Failed to suspend driver');
    }
  }

  Future<void> _verifyDriver(BuildContext context, String id, bool currentVerified) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({'isVerified': !currentVerified});
      if (context.mounted) {
        context.showSuccess(currentVerified ? 'Verification removed' : 'Driver verified');
      }
    } catch (e) {
      if (context.mounted) context.showError('Failed to update verification status');
    }
  }

  Future<void> _resetDriverAccount(BuildContext context, String id, String name) async {
    final confirmed = await context.confirmAction(
      title: 'Reset Stats',
      message: 'Reset earnings and stats for "$name"? This cannot be undone.',
      confirmLabel: 'Reset',
      confirmColor: context.warningColor,
    );
    if (!confirmed) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({
        'ordersCompleted': 0,
        'earnings': 0,
        'rating': 0,
        'resetAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSuccess('$name stats reset');
    } catch (e) {
      if (context.mounted) context.showError('Failed to reset $name stats');
    }
  }
}
