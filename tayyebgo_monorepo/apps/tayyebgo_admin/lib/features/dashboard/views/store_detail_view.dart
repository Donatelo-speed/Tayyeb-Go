import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';
import '../../../core/services/admin_firestore_service.dart';
import '../../../core/widgets/app_empty_state.dart' as empty;
import 'widgets/store_header.dart';
import 'widgets/store_data_tabs.dart';
import 'widgets/store_analytics_tab.dart';
import 'widgets/store_design_tab.dart';

class StoreDetailView extends StatefulWidget {
  final String storeId, storeName;
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
            return empty.AdminEmptyState(
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
              StoreHeader(store: d, storeName: widget.storeName, storeId: widget.storeId),
              const SizedBox(height: 20),
              _buildTabs(context),
              const SizedBox(height: 16),
              _buildTabContent(context, d),
            ],
          );
        },
      ),
    ));
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

  Widget _buildTabContent(BuildContext context, Map<String, dynamic> d) {
    switch (_tab) {
      case 0: return StoreOverviewTab(store: d);
      case 1: return StoreDesignTab(store: d, storeId: widget.storeId);
      case 2: return StoreProductsTab(storeId: widget.storeId);
      case 3: return StoreCategoriesTab(storeId: widget.storeId);
      case 4: return StoreOrdersTab(storeId: widget.storeId);
      case 5: return StoreDriversTab(storeId: widget.storeId);
      case 6: return StoreAnalyticsTab(storeId: widget.storeId);
      case 7: return StoreContractsTab(storeName: widget.storeName);
      default: return const SizedBox.shrink();
    }
  }
}
