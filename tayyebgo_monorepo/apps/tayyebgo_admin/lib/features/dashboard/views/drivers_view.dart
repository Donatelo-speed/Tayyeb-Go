import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return pageContainer(context, child: AppScaffold(
      showAppBar: false,
      title: 'Drivers',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search drivers...',
                    prefixIcon: Icon(Icons.search, color: context.textMutedColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(tooltip: 'Clear search', icon: Icon(Icons.clear, color: context.textMutedColor), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              _filterChip(context, 'All', 'all', isDark),
              const SizedBox(width: 4),
              _filterChip(context, 'Platform', 'platform', isDark),
              const SizedBox(width: 4),
              _filterChip(context, 'Store', 'store', isDark),
            ]),
          ),
          Expanded(
            child: StreamScreenBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').limit(500).snapshots(),
              onLoading: () => const ShimmerLoading(itemCount: 4),
              onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
              onSuccess: (context, snapshot) {
                var docs = snapshot.docs;
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
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delivery_dining_outlined, size: 64, color: context.textMutedColor),
                      const SizedBox(height: 16),
                      Text('No drivers registered', style: TextStyle(color: context.textMutedColor, fontSize: 16)),
                    ]),
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
                        color: isDark ? DarkAppColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: (isDark ? DarkAppColors.divider : AppColors.divider)),
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.delivery_dining, color: context.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(displayName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                    const SizedBox(width: 8),
                                    _driverTypeBadge(driverType),
                                    if (storeId.isNotEmpty && driverType == 'store') ...[
                                      const SizedBox(width: 4),
                                      Text('ID: ${storeId.substring(0, 6)}...', style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                                    ],
                                    if (isVerified) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.verified, size: 14, color: Colors.blue),
                                    ],
                                  ]),
                                  Text(email, style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (rating > 0)
                              Row(children: [
                                Icon(Icons.star, size: 16, color: AppColors.warning),
                                Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                                const SizedBox(width: 8),
                              ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isOnline ? AppColors.success : context.textMutedColor).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOnline ? 'Active' : 'Inactive',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOnline ? AppColors.success : context.textMutedColor),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'approve') _approveDriver(context, id, displayName);
                                if (v == 'suspend') _suspendDriver(context, id, displayName);
                                if (v == 'verify') _verifyDriver(context, id, isVerified);
                                if (v == 'assign') _showAssignStoreDialog(context, id, displayName, driverType, storeId);
                                if (v == 'reset') _resetDriverAccount(context, id, displayName);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.check_circle, size: 20, color: AppColors.success), title: Text('Approve'))),
                                if (isOnline) const PopupMenuItem(value: 'suspend', child: ListTile(leading: Icon(Icons.pause_circle, size: 20, color: Colors.orange), title: Text('Suspend'))),
                                const PopupMenuItem(value: 'verify', child: ListTile(leading: Icon(Icons.verified, size: 20, color: Colors.blue), title: Text('Verify/Unverify'))),
                                if (driverType == 'store') const PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.store, size: 20), title: Text('Assign Store'))),
                                const PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(Icons.refresh, size: 20), title: Text('Reset Stats'))),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _driverStat(context, Icons.shopping_bag, '$ordersCompleted', 'Orders', context.primaryColor),
                            const SizedBox(width: 16),
                            _driverStat(context, Icons.attach_money, '\$${earnings.toStringAsFixed(0)}', 'Earnings', AppColors.success),
                            const SizedBox(width: 16),
                            _driverStat(context, Icons.person_pin, driverType.replaceAll('_', ' ').toUpperCase(), 'Type', AppColors.premium),
                          ]),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String value, bool isDark) {
    final selected = _driverTypeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _driverTypeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : (isDark ? DarkAppColors.surface : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? context.primaryColor : (isDark ? DarkAppColors.divider : AppColors.divider)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : context.textSecondaryColor)),
      ),
    );
  }

  Widget _driverTypeBadge(String type) {
    final c = type == 'platform' ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(type.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Widget _driverStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
    ]);
  }

  void _showAssignStoreDialog(BuildContext context, String driverId, String driverName, String driverType, String currentStoreId) {
    final storeCtrl = TextEditingController(text: currentStoreId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? DarkAppColors.surface : null,
        title: const Text('Assign Store'),
        content: SizedBox(
          width: 350,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assign "$driverName" to a store:', style: TextStyle(color: context.textPrimaryColor)),
            const SizedBox(height: 16),
            TextField(
              controller: storeCtrl,
              decoration: const InputDecoration(labelText: 'Store ID', hintText: 'Enter store document ID'),
            ),
            const SizedBox(height: 8),
            Text('Leave empty to unassign from current store', style: TextStyle(fontSize: 11, color: context.textMutedColor)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Save'),
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
      confirmColor: Colors.orange,
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
