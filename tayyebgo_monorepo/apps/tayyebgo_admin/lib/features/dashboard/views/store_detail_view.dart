import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';
import 'business_type.dart';
import '../../../core/services/admin_firestore_service.dart';
import '../../../core/widgets/app_empty_state.dart' as empty;

class StoreDetailView extends StatefulWidget {
  final String storeId;
  final String storeName;
  const StoreDetailView({super.key, required this.storeId, required this.storeName});

  @override
  State<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends State<StoreDetailView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      showAppBar: false,
      title: widget.storeName,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: AdminFirestoreService.instance.watchStore(widget.storeId),
        builder: (context, snap) {
          if (snap.hasError) {
            return empty.AppEmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load store',
              subtitle: snap.error.toString(),
              actionLabel: 'Retry',
              onAction: () => setState(() {}),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 4);
          }
          final d = snap.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(context, d),
              const SizedBox(height: 20),
              _buildTabs(context),
              const SizedBox(height: 16),
              if (_tab == 0) _buildOverview(context, d),
              if (_tab == 1) _buildDesignCenter(context, d),
              if (_tab == 2) _buildProducts(context),
              if (_tab == 3) _buildCategories(context),
              if (_tab == 4) _buildOrders(context),
              if (_tab == 5) _buildDrivers(context),
              if (_tab == 6) _buildAnalytics(context),
              if (_tab == 7) _buildContracts(context),
            ],
          );
        },
      ),
    ));
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> d) {
    final name = d['name'] as String? ?? widget.storeName;
    final cuisine = d['cuisineType'] as String? ?? '';
    final active = d['isActive'] as bool? ?? true;
    final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
    final logoUrl = d['logoUrl'] as String?;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final status = BusinessStatus.fromValue(d['businessStatus'] as String?);
    final businessTypeId = d['businessType'] as String? ?? d['cuisineType'] as String? ?? '';
    final businessType = BusinessTypes.byId(businessTypeId);
    final package = BusinessPackage.fromValue(d['package'] as String?);
    final category = businessType.category;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Row(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: context.primaryColor.withValues(alpha: 0.1),
          child: hasLogo
              ? ClipOval(child: Image.network(d['logoUrl'] as String, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(businessIcon(businessType.iconKey), color: context.primaryColor)))
              : Icon(businessIcon(businessType.iconKey), size: 32, color: context.primaryColor),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<BusinessStatus>(
          tooltip: 'Update status',
          icon: Icon(Icons.more_vert, color: context.textSecondaryColor),
          onSelected: (s) async {
            try {
              await AdminFirestoreService.instance.updateStoreStatus(widget.storeId, s);
              if (mounted) context.showSuccess('Status updated to ${s.displayName}');
            } catch (e) {
              if (mounted) context.showError('Failed to update status');
            }
          },
          itemBuilder: (_) => BusinessStatus.values.map((s) {
            final color = statusColor(s.colorKey, context);
            return PopupMenuItem<BusinessStatus>(
              value: s,
              child: Row(children: [
                Icon(statusIcon(s.iconKey), size: 16, color: color),
                const SizedBox(width: 8),
                Text('Set ${s.displayName}'),
              ]),
            );
          }).toList(),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: AppTypography.heading2)),
              const SizedBox(width: 8),
              _buildStatusBadge(context, status),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(businessIcon(category.iconKey), size: 14, color: context.textSecondaryColor),
              const SizedBox(width: 4),
              Text('${category.displayName} • ${businessType.name}', style: TextStyle(color: context.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            if (cuisine.isNotEmpty) Text(cuisine, style: TextStyle(color: context.textMutedColor, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (active ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? AppColors.success : AppColors.error)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${commission.toStringAsFixed(0)}% Commission', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.premium.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.workspace_premium, size: 12, color: AppColors.premium),
                  const SizedBox(width: 3),
                  Text(package.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.premium)),
                ]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatusBadge(BuildContext context, BusinessStatus status) {
    final color = statusColor(status.colorKey, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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

  Widget _buildTabs(BuildContext context) {
    final tabs = ['Overview', 'Design', 'Products', 'Categories', 'Orders', 'Drivers', 'Analytics', 'Contracts'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: List.generate(tabs.length, (i) {
        final selected = _tab == i;
        return GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: selected ? context.primaryColor : Colors.transparent, width: 2)),
            ),
            child: Text(tabs[i], style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? context.primaryColor : context.textSecondaryColor,
              fontSize: 13,
            )),
          ),
        );
      })),
    );
  }

  Widget _buildDesignCenter(BuildContext context, Map<String, dynamic> d) {
    return Column(children: [
      _buildTemplatePicker(context, d),
      const SizedBox(height: 16),
      _designSection(context, 'Store Logo', Icons.image_outlined, 'Upload your store logo (recommended: 512x512px)', d['logoUrl'] as String?, d),
      const SizedBox(height: 16),
      _designSection(context, 'Banner Image', Icons.panorama_outlined, 'Upload your store banner (recommended: 1200x400px)', d['bannerUrl'] as String?, d),
      const SizedBox(height: 16),
      _brandColors(context, d),
      const SizedBox(height: 16),
      _featuredProducts(context, d),
    ]);
  }

  Widget _buildTemplatePicker(BuildContext context, Map<String, dynamic> d) {
    final currentId = d['designTemplate'] as String? ?? 'modern';
    final current = DesignTemplate.byId(currentId);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.dashboard_customize_outlined, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text('Storefront Template', style: AppTypography.heading3),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(businessIcon(current.iconKey), size: 14, color: context.primaryColor),
              const SizedBox(width: 4),
              Text('Current: ${current.name}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Choose how this store appears to customers in the app', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (ctx, c) {
          final perRow = c.maxWidth > 800 ? 3 : c.maxWidth > 500 ? 2 : 1;
          return Wrap(spacing: 12, runSpacing: 12, children: DesignTemplate.all.map((t) {
            final selected = currentId == t.id;
            final w = (c.maxWidth - (perRow - 1) * 12) / perRow;
            return GestureDetector(
              onTap: () async {
                try {
                  await AdminFirestoreService.instance.updateStore(widget.storeId, {'designTemplate': t.id});
                  if (mounted) context.showSuccess('Template set to ${t.name}');
                } catch (e) {
                  if (mounted) context.showError('Failed to update template');
                }
              },
              child: Container(
                width: w,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? context.primaryColor.withValues(alpha: 0.05) : context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? context.primaryColor : context.dividerColor, width: selected ? 1.5 : 1),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: (selected ? context.primaryColor : context.textMutedColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(businessIcon(t.iconKey), color: selected ? context.primaryColor : context.textMutedColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(t.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                    Text(t.description, style: TextStyle(fontSize: 11, color: context.textMutedColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  if (selected) Icon(Icons.check_circle, color: context.primaryColor, size: 18),
                ]),
              ),
            );
          }).toList());
        }),
      ]),
    );
  }

  Widget _designSection(BuildContext context, String title, IconData icon, String subtitle, String? existingUrl, Map<String, dynamic> d) {
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    final url = existingUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text(title, style: AppTypography.heading3),
          const Spacer(),
          if (hasExisting)
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.dividerColor.withValues(alpha: 0.3))),
              child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            ),
        ]),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showImageUploadDialog(context, title, d, widget.storeId),
          icon: const Icon(Icons.upload, size: 16),
          label: Text(hasExisting ? 'Replace' : 'Upload'),
          style: OutlinedButton.styleFrom(foregroundColor: context.primaryColor),
        ),
      ]),
    );
  }

  Widget _brandColors(BuildContext context, Map<String, dynamic> d) {
    final primary = d['brandColor'] as String? ?? '#2563EB';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.palette_outlined, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text('Brand Colors', style: AppTypography.heading3),
        ]),
        const SizedBox(height: 12),
        Text('Primary brand color used across store presence', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(int.parse(primary.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(8), border: Border.all(color: context.dividerColor))),
          const SizedBox(width: 12),
          Text(primary, style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
          const Spacer(),
          OutlinedButton(
            onPressed: () => _pickBrandColor(context, d, widget.storeId),
            child: const Text('Change'),
          ),
        ]),
      ]),
    );
  }

  Widget _featuredProducts(BuildContext context, Map<String, dynamic> d) {
    final featured = (d['featuredProducts'] as List<dynamic>?) ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.star_outlined, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text('Featured Products', style: AppTypography.heading3),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _pickFeaturedProducts(context, d, widget.storeId, featured),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ]),
        const SizedBox(height: 12),
        if (featured.isEmpty)
          Text('No featured products selected. Choose products to highlight on the store page.', style: TextStyle(fontSize: 12, color: context.textMutedColor))
        else
          ...featured.map((p) => ListTile(dense: true, title: Text(p.toString()), trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => {}))),
      ]),
    );
  }

  Widget _buildOverview(BuildContext context, Map<String, dynamic> d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Store Overview', style: AppTypography.heading3),
        const SizedBox(height: 16),
        _infoRow(context, 'Phone', d['phone'] as String? ?? '-'),
        _infoRow(context, 'Street', d['street'] as String? ?? '-'),
        _infoRow(context, 'City', d['city'] as String? ?? '-'),
        _infoRow(context, 'Owner ID', d['ownerId'] as String? ?? '-'),
        _infoRow(context, 'Created', d['createdAt'] != null ? _formatDate((d['createdAt'] as Timestamp).toDate()) : '-'),
      ]),
    );
  }

  Widget _buildProducts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchStoreProducts(widget.storeId, limit: 50),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              subtitle: 'Products added in the store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Products', style: AppTypography.heading3),
              const Spacer(),
              Text('${docs.length} items', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...docs.map((pd) {
              final name = pd['name'] as String? ?? 'Unnamed';
              final price = (pd['price'] as num?)?.toDouble() ?? 0;
              final available = pd['isAvailable'] as bool? ?? true;
              return ListTile(
                dense: true,
                leading: Icon(Icons.shopping_bag_outlined, color: context.primaryColor, size: 20),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('\$${price.toStringAsFixed(2)}', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (available ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(available ? 'In stock' : 'Out', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: available ? AppColors.success : AppColors.error)),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchStoreCategories(widget.storeId, limit: 50),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AppEmptyState(
              icon: Icons.category_outlined,
              title: 'No categories configured',
              subtitle: 'Menu categories added in the store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Menu Categories', style: AppTypography.heading3),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: docs.map((cd) {
              final name = cd['name'] as String? ?? 'Unnamed';
              return Chip(
                label: Text(name),
                backgroundColor: context.primaryColor.withValues(alpha: 0.08),
                side: BorderSide(color: context.primaryColor.withValues(alpha: 0.2)),
                labelStyle: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500, fontSize: 12),
              );
            }).toList()),
          ]);
        },
      ),
    );
  }

  Widget _buildOrders(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchOrdersRaw(filter: OrderFilter(storeId: widget.storeId), limit: 20),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders placed at this store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Recent Orders', style: AppTypography.heading3),
              const Spacer(),
              Text('${docs.length} total', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...docs.map((od) {
              final total = (od['total'] as num?)?.toDouble() ?? 0;
              final status = od['status'] as String? ?? 'unknown';
              final orderNum = od['orderNumber'] as String? ?? (od['id'] as String? ?? '').substring(0, 6);
              return ListTile(
                dense: true,
                leading: Icon(Icons.receipt_outlined, color: context.primaryColor, size: 20),
                title: Text('Order #$orderNum', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(status.toUpperCase(), style: TextStyle(color: context.textSecondaryColor, fontSize: 11)),
                trailing: Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
              );
            }),
          ]);
        },
      ),
    );
  }

  Widget _buildDrivers(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchDriverAssignments(widget.storeId, limit: 20),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AppEmptyState(
              icon: Icons.delivery_dining,
              title: 'No drivers assigned yet',
              subtitle: 'Drivers assigned to this store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assigned Drivers', style: AppTypography.heading3),
            const SizedBox(height: 12),
            ...docs.map((dd) {
              final name = dd['driverName'] as String? ?? 'Unknown';
              final active = dd['isActive'] as bool? ?? true;
              return ListTile(
                dense: true,
                leading: Icon(Icons.delivery_dining, color: context.primaryColor, size: 20),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (active ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? AppColors.success : AppColors.error)),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.watchOrdersRaw(filter: OrderFilter(storeId: widget.storeId), limit: 200),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const ShimmerLoading(itemCount: 3);
        }
        final orders = snap.data ?? const [];
        final totalRevenue = orders.fold<double>(0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
        final completed = orders.where((o) => o['status'] == 'delivered').length;
        final cancelled = orders.where((o) => o['status'] == 'cancelled').length;
        final avgOrder = orders.isEmpty ? 0.0 : totalRevenue / orders.length;
        return Column(children: [
          Row(children: [
            Expanded(child: _statTile(context, 'Total Revenue', '\$${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _statTile(context, 'Total Orders', '${orders.length}', Icons.receipt_long, context.primaryColor)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statTile(context, 'Completed', '$completed', Icons.check_circle, AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _statTile(context, 'Cancelled', '$cancelled', Icons.cancel, AppColors.error)),
          ]),
          const SizedBox(height: 12),
          _statTile(context, 'Average Order Value', '\$${avgOrder.toStringAsFixed(2)}', Icons.trending_up, AppColors.warning, wide: true),
        ]);
      },
    );
  }

  Widget _statTile(BuildContext context, String label, String value, IconData icon, Color color, {bool wide = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoBordered(context),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        ]),
      ]),
    );
  }

  Widget _buildContracts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchContractsForStore(widget.storeName, limit: 10),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 2);
          }
          final docs = snap.data ?? const [];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Contracts & Subscriptions', style: AppTypography.heading3),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Text('No contracts found for this store.', style: TextStyle(color: context.textMutedColor))
            else
              ...docs.map((cd) {
                final status = cd['isActive'] as bool? ?? false;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.description, color: context.primaryColor),
                  title: Text('Contract ${status ? '(Active)' : '(Inactive)'}', style: AppTypography.bodyBold),
                  trailing: Text(status ? 'Active' : 'Inactive', style: TextStyle(color: status ? AppColors.success : AppColors.error)),
                );
              }),
          ]);
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: context.textSecondaryColor))),
        Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: context.textPrimaryColor))),
      ]),
    );
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

void _showImageUploadDialog(
  BuildContext context,
  String title,
  Map<String, dynamic> d,
  String storeId,
) {
  final field = title == 'Store Logo' ? 'logoUrl' : 'bannerUrl';
  final urlCtrl = TextEditingController(text: d[field] as String? ?? '');
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title == 'Store Logo'
                  ? 'Recommended 512×512 px. PNG with transparent background looks best.'
                  : 'Recommended 1200×400 px landscape banner.',
              style: TextStyle(fontSize: 12, color: context.textMutedColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                hintText: 'https://…',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: upload via Firebase Console → Storage, then paste the public URL.',
              style: TextStyle(fontSize: 11, color: context.textMutedColor),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        if ((d[field] as String?)?.isNotEmpty == true)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.instance.updateStore(storeId, {field: FieldValue.delete()});
              if (context.mounted) context.showSuccess('$title removed');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: () async {
            final url = urlCtrl.text.trim();
            if (url.isEmpty) {
              if (ctx.mounted) context.showError('URL cannot be empty');
              return;
            }
            Navigator.pop(ctx);
            await AdminFirestoreService.instance.updateStore(storeId, {field: url});
            if (context.mounted) context.showSuccess('$title updated');
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _pickBrandColor(
  BuildContext context,
  Map<String, dynamic> d,
  String storeId,
) {
  const swatches = <(String, Color)>[
    ('#2563EB', Color(0xFF2563EB)),
    ('#10B981', Color(0xFF10B981)),
    ('#F59E0B', Color(0xFFF59E0B)),
    ('#EF4444', Color(0xFFEF4444)),
    ('#8B5CF6', Color(0xFF8B5CF6)),
    ('#EC4899', Color(0xFFEC4899)),
    ('#0EA5E9', Color(0xFF0EA5E9)),
    ('#F97316', Color(0xFFF97316)),
    ('#14B8A6', Color(0xFF14B8A6)),
    ('#84CC16', Color(0xFF84CC16)),
    ('#1F2937', Color(0xFF1F2937)),
    ('#F3F4F6', Color(0xFFF3F4F6)),
  ];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Pick brand color'),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in swatches)
              Semantics(
                button: true,
                label: s.$1,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await AdminFirestoreService.instance.updateStore(storeId, {'brandColor': s.$1});
                    if (context.mounted) context.showSuccess('Brand color set to ${s.$1}');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: s.$2,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor, width: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

void _pickFeaturedProducts(
  BuildContext context,
  Map<String, dynamic> d,
  String storeId,
  List<dynamic> current,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _FeaturedProductsDialog(
      storeId: storeId,
      initiallySelected: current.map((e) => e.toString()).toSet(),
    ),
  );
}

class _FeaturedProductsDialog extends StatefulWidget {
  final String storeId;
  final Set<String> initiallySelected;
  const _FeaturedProductsDialog({required this.storeId, required this.initiallySelected});

  @override
  State<_FeaturedProductsDialog> createState() => _FeaturedProductsDialogState();
}

class _FeaturedProductsDialogState extends State<_FeaturedProductsDialog> {
  late final Set<String> _selected = {...widget.initiallySelected};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Featured products'),
      content: SizedBox(
        width: 360,
        height: 360,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminFirestoreService.instance.watchStoreProducts(widget.storeId, limit: 50),
          builder: (c, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final docs = snap.data ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'This store has no products yet.\n\nAdd products in the store\'s menu to feature them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textMutedColor),
                  ),
                ),
              );
            }
            return ListView(
              children: [
                for (final doc in docs)
                  CheckboxListTile(
                    value: _selected.contains(doc['id'] as String? ?? ''),
                    dense: true,
                    title: Text(
                      (doc['name'] as String?) ?? 'Unnamed product',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onChanged: (v) => setState(() {
                      final id = doc['id'] as String? ?? '';
                      if (v == true) {
                        _selected.add(id);
                      } else {
                        _selected.remove(id);
                      }
                    }),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final ids = _selected.toList();
                  await AdminFirestoreService.instance.updateStore(widget.storeId, {'featuredProducts': ids});
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (context.mounted) {
                    context.showSuccess('${ids.length} featured product${ids.length == 1 ? '' : 's'} updated');
                  }
                },
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

