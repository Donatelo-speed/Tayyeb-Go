import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(context, child: AppScaffold(
      title: 'Approval Center',
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.dividerColor.withValues(alpha: 0.3))),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: context.primaryColor,
              unselectedLabelColor: context.textSecondaryColor,
              indicatorColor: context.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.store, size: 18), text: 'Stores'),
                Tab(icon: Icon(Icons.delivery_dining, size: 18), text: 'Drivers'),
                Tab(icon: Icon(Icons.description, size: 18), text: 'Documents'),
                Tab(icon: Icon(Icons.handshake, size: 18), text: 'Contracts'),
                Tab(icon: Icon(Icons.subscriptions, size: 18), text: 'Subscriptions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildStoreApprovals(),
                _buildDriverApprovals(),
                _buildDocumentApprovals(),
                _buildContractApprovals(),
                _buildSubscriptionApprovals(),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStoreApprovals() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Restaurants')
          .where('status', isEqualTo: 'pending')
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'pending' || data['isActive'] == false;
        }).toList();
        if (docs.isEmpty) return _emptyState('No pending store requests', 'New store applications appear here for review.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _storeCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildDriverApprovals() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'driver')
          .where('status', isEqualTo: 'pending')
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyState('No pending driver applications', 'New driver sign-ups appear here for review.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _driverCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildDocumentApprovals() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('status', isEqualTo: 'pending')
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyState('No documents to review', 'Driver and store documents appear here for verification.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _documentCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildContractApprovals() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contracts')
          .where('status', isEqualTo: 'pending_renewal')
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyState('No contracts pending renewal', 'Store contracts needing renewal appear here.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _contractCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildSubscriptionApprovals() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .where('status', isEqualTo: 'pending_renewal')
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const ShimmerLoading(itemCount: 4, itemHeight: 100);
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyState('No subscriptions pending renewal', 'Subscription renewals appear here.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _subscriptionCard(context, docs[i]),
        );
      },
    );
  }

  Widget _storeCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? 'Unnamed';
    final cuisine = d['cuisineType'] as String? ?? 'N/A';
    final phone = d['phone'] as String? ?? '—';
    return _approvalCard(
      context: context,
      title: name,
      subtitle: '$cuisine · $phone',
      icon: Icons.store,
      iconColor: context.primaryColor,
      meta: _formatTimestamp(d['createdAt']),
      onApprove: () => _updateStatus('Restaurants', doc.id, {'status': 'active', 'isActive': true}),
      onReject: () => _updateStatus('Restaurants', doc.id, {'status': 'rejected'}),
    );
  }

  Widget _driverCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['displayName'] as String? ?? d['name'] as String? ?? 'Unnamed';
    final phone = d['phone'] as String? ?? '—';
    final vehicle = d['vehicleType'] as String? ?? 'N/A';
    return _approvalCard(
      context: context,
      title: name,
      subtitle: '$vehicle · $phone',
      icon: Icons.delivery_dining,
      iconColor: AppColors.info,
      meta: _formatTimestamp(d['createdAt']),
      onApprove: () => _updateStatus('Users', doc.id, {'status': 'active', 'isVerified': true}),
      onReject: () => _updateStatus('Users', doc.id, {'status': 'rejected'}),
    );
  }

  Widget _documentCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final type = d['type'] as String? ?? 'Document';
    final name = d['name'] as String? ?? 'Unknown';
    return _approvalCard(
      context: context,
      title: name,
      subtitle: type,
      icon: Icons.description,
      iconColor: AppColors.warning,
      meta: _formatTimestamp(d['createdAt']),
      onApprove: () => _updateStatus('documents', doc.id, {'status': 'approved', 'verifiedAt': FieldValue.serverTimestamp()}),
      onReject: () => _updateStatus('documents', doc.id, {'status': 'rejected'}),
    );
  }

  Widget _contractCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final storeName = d['storeName'] as String? ?? d['restaurantId'] as String? ?? 'Store';
    final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 0;
    return _approvalCard(
      context: context,
      title: storeName,
      subtitle: 'Commission: ${commission.toStringAsFixed(0)}%',
      icon: Icons.handshake,
      iconColor: AppColors.success,
      meta: 'Expires: ${_formatTimestamp(d['expiresAt'])}',
      onApprove: () => _updateStatus('contracts', doc.id, {'status': 'active'}),
      onReject: () => _updateStatus('contracts', doc.id, {'status': 'cancelled'}),
    );
  }

  Widget _subscriptionCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final plan = d['plan'] as String? ?? 'Plan';
    final storeName = d['storeName'] as String? ?? 'Store';
    return _approvalCard(
      context: context,
      title: '$storeName — $plan',
      subtitle: 'Monthly subscription',
      icon: Icons.subscriptions,
      iconColor: AppColors.primary,
      meta: 'Renews: ${_formatTimestamp(d['renewsAt'])}',
      onApprove: () => _updateStatus('subscriptions', doc.id, {'status': 'active', 'renewsAt': FieldValue.serverTimestamp()}),
      onReject: () => _updateStatus('subscriptions', doc.id, {'status': 'expired'}),
    );
  }

  Widget _approvalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String meta,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoBordered(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onReject,
            icon: Icon(Icons.close, color: AppColors.error.withValues(alpha: 0.8)),
            tooltip: 'Reject',
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: context.textMutedColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: context.textMutedColor, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '—';
  }

  Future<void> _updateStatus(String collection, String id, Map<String, dynamic> updates) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated $collection'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
