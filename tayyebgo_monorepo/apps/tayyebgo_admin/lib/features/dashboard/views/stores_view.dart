import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
import 'shared.dart';
import 'store_detail_view.dart';
import 'create_business_wizard.dart';
import 'business_type.dart';
import '../../../core/services/admin_firestore_service.dart';
import '../../../core/widgets/app_empty_state.dart' as empty;

class StoresView extends StatefulWidget {
  const StoresView();
  @override
  State<StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<StoresView> with SingleTickerProviderStateMixin {
  VerticalType _verticalFilter = VerticalType.restaurant;
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
      title: 'Businesses',
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateBusinessWizard(context),
            icon: const Icon(Icons.add_business, size: 18),
            label: const Text('Create Business'),
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white),
          ),
        ],
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or cuisine...',
                    prefixIcon: Icon(Icons.search, color: context.textMutedColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: Icon(Icons.clear, color: context.textMutedColor),
                            onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<VerticalType>(
                value: _verticalFilter,
                underline: const SizedBox.shrink(),
                items: VerticalType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.displayName))).toList(),
                onChanged: (v) { if (v != null) setState(() => _verticalFilter = v); },
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AdminFirestoreService.instance.watchStoresRaw(limit: 500),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const ShimmerLoading(itemCount: 4);
                }
                if (snap.hasError) {
                  return empty.AppEmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load stores',
                    subtitle: snap.error.toString(),
                    actionLabel: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }
                var docs = (snap.data ?? const []).map((d) => _MapDoc(d)).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final d = doc.data();
                    final name = (d['name'] as String? ?? '').toLowerCase();
                    final cuisine = (d['cuisineType'] as String? ?? '').toLowerCase();
                    return name.contains(q) || cuisine.contains(q);
                  }).toList();
                }
                docs = docs.where((doc) {
                  final d = doc.data();
                  final vt = VerticalType.fromValue(d['verticalType'] as String? ?? '');
                  return vt == _verticalFilter;
                }).toList();
                if (docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.store_outlined, size: 64, color: context.textMutedColor),
                      const SizedBox(height: 16),
                      Text('No businesses yet', style: TextStyle(color: context.textMutedColor, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateBusinessWizard(context),
                        icon: const Icon(Icons.add_business),
                        label: const Text('Create Business'),
                      ),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final id = docs[i].id;
                    final name = d['name'] as String? ?? 'Unknown';
                    final cuisine = d['cuisineType'] as String? ?? '';
                    final vt = VerticalType.fromValue(d['verticalType'] as String? ?? '');
                    final active = d['isActive'] as bool? ?? true;
                    final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
                    final deliveryMode = d['deliveryMode'] as String? ?? 'platform_only';
                    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
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
                      child: _buildStoreHeader(context, d, id, name, cuisine, vt, active, commission, deliveryMode, rating, isDark, docs[i]),
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

  Widget _buildStoreHeader(BuildContext context, Map<String, dynamic> d, String id, String name, String cuisine,
      VerticalType vt, bool active, double commission, String deliveryMode, double rating, bool isDark, _MapDoc doc) {
    final status = BusinessStatus.fromValue(d['businessStatus'] as String?);
    final businessTypeId = d['businessType'] as String? ?? d['cuisineType'] as String? ?? '';
    return Row(children: [
      CircleAvatar(
        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
        child: Icon(businessIcon(BusinessTypes.byId(businessTypeId).iconKey), color: context.primaryColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${commission.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryColor)),
              ),
              const SizedBox(width: 4),
              _deliveryModeBadge(deliveryMode),
              const SizedBox(width: 4),
              _buildStatusBadge(context, status),
            ]),
            if (cuisine.isNotEmpty)
              Text(cuisine, style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
          ],
        ),
      ),
      if (rating > 0)
        Row(children: [
          Icon(Icons.star, size: 16, color: AppColors.warning),
          Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: context.textMutedColor)),
          const SizedBox(width: 8),
        ]),
      Switch(
        value: active,
        activeColor: AppColors.success,
        onChanged: (v) async {
          try {
            await AdminFirestoreService.instance.updateStoreActive(id, v);
            if (context.mounted) context.showSuccess(v ? '$name activated' : '$name deactivated');
          } catch (e) {
            if (context.mounted) context.showError('Failed to update $name');
          }
        },
      ),
      PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') _showStoreDialog(context, doc);
          if (v == 'details') _showStoreDetail(context, id, name);
          if (v == 'delivery') _showDeliveryModeDialog(context, id, deliveryMode, d);
          if (v == 'delete') _confirmDelete(context, id, name);
          if (v == 'approve') _approveStore(context, id, name);
          if (v == 'suspend') _suspendStore(context, id, name);
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'details', child: ListTile(leading: Icon(Icons.info, size: 20), title: Text('Details'))),
          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit'))),
          const PopupMenuItem(value: 'delivery', child: ListTile(leading: Icon(Icons.local_shipping, size: 20), title: Text('Delivery Mode'))),
          const PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.check_circle, size: 20, color: AppColors.success), title: Text('Approve'))),
          if (active) const PopupMenuItem(value: 'suspend', child: ListTile(leading: Icon(Icons.pause_circle, size: 20, color: Colors.orange), title: Text('Suspend'))),
          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, size: 20, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
        ],
      ),
    ]);
  }

  void _showStoreDetail(BuildContext context, String storeId, String storeName) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StoreDetailView(storeId: storeId, storeName: storeName),
    ));
  }



  Widget _deliveryModeBadge(String mode) {
    Color c;
    switch (mode) {
      case 'store_only': c = AppColors.primary; break;
      case 'platform_only': c = AppColors.success; break;
      case 'hybrid': c = AppColors.premium; break;
      default: c = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(mode.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Widget _buildStatusBadge(BuildContext context, BusinessStatus status) {
    final color = statusColor(status.colorKey, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          status.displayName.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.4),
        ),
      ]),
    );
  }

  void _showDeliveryModeDialog(BuildContext context, String storeId, String currentMode, Map<String, dynamic> storeData) {
    String selected = currentMode;
    bool fallbackEnabled = storeData['allowPlatformFallback'] as bool? ?? true;
    final fallbackDelayCtrl = TextEditingController(text: '${storeData['fallbackDelaySeconds'] as int? ?? 30}');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delivery Mode Configuration'),
          backgroundColor: isDark ? DarkAppColors.surface : null,
          content: SizedBox(
            width: 350,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Select delivery mode:', style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              const SizedBox(height: 8),
              ...['store_only', 'platform_only', 'hybrid'].map((mode) => RadioListTile<String>(
                title: Text(mode.replaceAll('_', ' ').toUpperCase()),
                subtitle: Text(_deliveryModeDescription(mode), style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                value: mode,
                groupValue: selected,
                onChanged: (v) { if (v != null) setDialogState(() => selected = v); },
                dense: true,
              )),
              if (selected == 'hybrid') ...[
                const Divider(),
                SwitchListTile(
                  title: const Text('Allow Fallback'),
                  subtitle: const Text('Fallback to platform drivers if store drivers unavailable'),
                  value: fallbackEnabled,
                  onChanged: (v) => setDialogState(() => fallbackEnabled = v),
                ),
                if (fallbackEnabled) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: fallbackDelayCtrl,
                    decoration: const InputDecoration(labelText: 'Fallback Delay (seconds)', suffixText: 'sec'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updates = <String, dynamic>{
                  'deliveryMode': selected,
                };
                if (selected == 'hybrid') {
                  updates['allowPlatformFallback'] = fallbackEnabled;
                  updates['fallbackDelaySeconds'] = int.tryParse(fallbackDelayCtrl.text) ?? 30;
                }
                try {
                  await AdminFirestoreService.instance.updateStore(storeId, updates);
                  if (ctx.mounted) ctx.showSuccess('Delivery mode updated');
                } catch (e) {
                  if (ctx.mounted) ctx.showError('Failed to update delivery mode');
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _deliveryModeDescription(String mode) {
    switch (mode) {
      case 'store_only': return 'Only store-assigned drivers can deliver';
      case 'platform_only': return 'Only platform drivers can deliver';
      case 'hybrid': return 'Store drivers first, then platform fallback';
      default: return '';
    }
  }

  void _showCreateBusinessWizard(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateBusinessWizard(),
    );
  }

  void _showStoreDialog(BuildContext context, _MapDoc? existing) {
    final d = existing?.data();
    final isEdit = existing != null;
    VerticalType selectedVertical = VerticalType.fromValue(d?['verticalType'] as String? ?? 'restaurant');
    final nameCtrl = TextEditingController(text: d?['name'] as String? ?? '');
    final cuisineCtrl = TextEditingController(text: d?['cuisineType'] as String? ?? '');
    final ownerCtrl = TextEditingController(text: d?['ownerId'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: d?['phone'] as String? ?? '');
    final commissionCtrl = TextEditingController(text: (d?['commissionPercent'] as num?)?.toDouble().toStringAsFixed(0) ?? '15');
    final latitudeCtrl = TextEditingController(text: (d?['latitude'] as num?)?.toString() ?? '');
    final longitudeCtrl = TextEditingController(text: (d?['longitude'] as num?)?.toString() ?? '');
    final streetCtrl = TextEditingController(text: d?['street'] as String? ?? '');
    final cityCtrl = TextEditingController(text: d?['city'] as String? ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Store' : 'Add Store'),
          backgroundColor: isDark ? DarkAppColors.surface : null,
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                DropdownButtonFormField<VerticalType>(
                  value: selectedVertical,
                  decoration: const InputDecoration(labelText: 'Vertical Type'),
                  items: VerticalType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.displayName))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => selectedVertical = v); },
                ),
                if (selectedVertical == VerticalType.restaurant) ...[
                  const SizedBox(height: 12),
                  TextField(controller: cuisineCtrl, decoration: const InputDecoration(labelText: 'Cuisine Type'), textCapitalization: TextCapitalization.words),
                ],
                const SizedBox(height: 12),
                TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'Owner ID'), enabled: !isEdit),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: commissionCtrl, decoration: const InputDecoration(labelText: 'Commission %', suffixText: '%'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: streetCtrl, decoration: const InputDecoration(labelText: 'Street'), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'), textCapitalization: TextCapitalization.words)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: latitudeCtrl, decoration: const InputDecoration(labelText: 'Lat'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: longitudeCtrl, decoration: const InputDecoration(labelText: 'Lng'), keyboardType: TextInputType.number)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'verticalType': selectedVertical.value,
                  'ownerId': ownerCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'commissionPercent': double.tryParse(commissionCtrl.text.trim()) ?? 15.0,
                  'street': streetCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'latitude': double.tryParse(latitudeCtrl.text.trim()) ?? 0.0,
                  'longitude': double.tryParse(longitudeCtrl.text.trim()) ?? 0.0,
                  'isActive': d?['isActive'] as bool? ?? true,
                  'deliveryMode': d?['deliveryMode'] as String? ?? 'platform_only',
                };
                if (selectedVertical == VerticalType.restaurant) {
                  data['cuisineType'] = cuisineCtrl.text.trim();
                }
                if (!isEdit) {
                  data['createdAt'] = FieldValue.serverTimestamp();
                }
                try {
                  if (isEdit) {
                    await AdminFirestoreService.instance.updateStore(existing.id, data);
                    if (ctx.mounted) ctx.showSuccess('Store updated');
                  } else {
                    await AdminFirestoreService.instance.createStore(data);
                    if (ctx.mounted) ctx.showSuccess('Store created');
                  }
                } catch (e) {
                  if (ctx.mounted) ctx.showError('Failed to save store');
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? DarkAppColors.surface : null,
        title: const Text('Delete Store'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              AdminFirestoreService.instance.deleteStore(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveStore(BuildContext context, String id, String name) async {
    try {
      await FirebaseFirestore.instance.collection('Restaurants').doc(id).update({'isActive': true, 'approvedAt': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('activity_log').add({
        'text': 'Store "$name" approved',
        'color': 'green',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSuccess('$name approved');
    } catch (e) {
      if (context.mounted) context.showError('Failed to approve $name');
    }
  }

  Future<void> _suspendStore(BuildContext context, String id, String name) async {
    final confirmed = await context.confirmAction(
      title: 'Suspend Store',
      message: 'Are you sure you want to suspend "$name"?',
      confirmLabel: 'Suspend',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;
    try {
      await FirebaseFirestore.instance.collection('Restaurants').doc(id).update({'isActive': false, 'suspendedAt': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('activity_log').add({
        'text': 'Store "$name" suspended',
        'color': 'orange',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) context.showSuccess('$name suspended');
    } catch (e) {
      if (context.mounted) context.showError('Failed to suspend $name');
    }
  }
}

class _MapDoc {
  final Map<String, dynamic> _data;
  final String id;
  _MapDoc(this._data) : id = _data['id'] as String? ?? '';
  Map<String, dynamic> data() => _data;
}
