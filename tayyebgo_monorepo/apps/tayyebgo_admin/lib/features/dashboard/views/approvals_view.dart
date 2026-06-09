import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

const _purple = Color(0xFF8B5CF6);

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
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Approval Center', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelColor: context.primaryColor,
            unselectedLabelColor: context.textMutedColor,
            indicatorColor: context.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.store_rounded, size: 18), text: 'Stores'),
              Tab(icon: Icon(Icons.delivery_dining_rounded, size: 18), text: 'Drivers'),
              Tab(icon: Icon(Icons.description_rounded, size: 18), text: 'Documents'),
              Tab(icon: Icon(Icons.handshake_rounded, size: 18), text: 'Contracts'),
              Tab(icon: Icon(Icons.subscriptions_rounded, size: 18), text: 'Subscriptions'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildStoreApprovals(context),
            _buildDriverApprovals(context),
            _buildDocumentApprovals(context),
            _buildContractApprovals(context),
            _buildSubscriptionApprovals(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreApprovals(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').where('status', isEqualTo: 'pending').limit(100).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
        final docs = snap.data?.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'pending' || data['isActive'] == false;
        }).toList() ?? [];
        if (docs.isEmpty) return _emptyState(context, Icons.store_outlined, 'No pending store requests', 'New store applications appear here for review.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _storeCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildDriverApprovals(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').where('status', isEqualTo: 'pending').limit(100).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(context, Icons.delivery_dining_outlined, 'No pending drivers', 'New driver sign-ups appear here for review.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _driverCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildDocumentApprovals(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('documents').where('status', isEqualTo: 'pending').limit(100).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(context, Icons.description_outlined, 'No documents to review', 'Driver and store documents appear here for verification.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _documentCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildContractApprovals(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('contracts').where('status', isEqualTo: 'pending_renewal').limit(100).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(context, Icons.handshake_outlined, 'No contracts pending', 'Store contracts needing renewal appear here.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _contractCard(context, docs[i]),
        );
      },
    );
  }

  Widget _buildSubscriptionApprovals(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subscriptions').where('status', isEqualTo: 'pending_renewal').limit(50).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState(context, Icons.subscriptions_outlined, 'No subscriptions pending', 'Subscription renewals appear here.');
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
      icon: Icons.store_rounded,
      iconColor: context.primaryColor,
      meta: _formatTimestamp(d['createdAt']),
      onApprove: () => _updateStatus('restaurants', doc.id, {'status': 'active', 'isActive': true}),
      onReject: () => _updateStatus('restaurants', doc.id, {'status': 'rejected'}),
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
      icon: Icons.delivery_dining_rounded,
      iconColor: _purple,
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
      icon: Icons.description_rounded,
      iconColor: context.warningColor,
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
      icon: Icons.handshake_rounded,
      iconColor: context.successColor,
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
      icon: Icons.subscriptions_rounded,
      iconColor: context.primaryColor,
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
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
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
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                const SizedBox(height: 2),
                Text(meta, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onReject,
            icon: Icon(Icons.close_rounded, color: context.errorColor),
            tooltip: 'Reject',
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: context.textPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, IconData icon, String title, String description) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: context.borderColor),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
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
          SnackBar(content: Text('Updated $collection', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e', style: GoogleFonts.inter()), backgroundColor: context.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    }
  }
}
