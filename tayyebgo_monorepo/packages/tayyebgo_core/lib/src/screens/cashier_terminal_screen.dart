import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_typography.dart';
import '../../infrastructure/services/order_state_machine.dart';
import '../../domain/enums/order_status.dart';
import '../providers/auth_provider.dart';

class CashierTerminalView extends StatelessWidget {
  const CashierTerminalView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final actorId = auth.user?.id ?? '';
    final restaurantId = auth.user?.vendorId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: const Text('Incoming Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: restaurantId == null || restaurantId.isEmpty
          ? _NoRestaurantAssigned(actorEmail: auth.user?.email ?? '')
          : _OrderStream(restaurantId: restaurantId, actorId: actorId),
    );
  }
}

class _NoRestaurantAssigned extends StatelessWidget {
  final String actorEmail;
  const _NoRestaurantAssigned({required this.actorEmail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 72, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('No Restaurant Assigned', style: AppTypography.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Your account ($actorEmail) has no restaurantId in Firestore.\n'
              'Ask a Super Admin to assign you to a restaurant.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStream extends StatelessWidget {
  final String restaurantId;
  final String actorId;

  const _OrderStream({required this.restaurantId, required this.actorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: ['pending', 'accepted', 'preparing'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _QueryErrorView(error: snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyInbox();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) => _OrderCard(
            doc: docs[i],
            actorId: actorId,
          ),
        );
      },
    );
  }
}

class _QueryErrorView extends StatelessWidget {
  final String error;
  const _QueryErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final isIndexError = error.contains('failed-precondition') ||
        error.contains('index') ||
        error.contains('requires an index');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isIndexError ? Icons.data_usage_outlined : Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(isIndexError ? 'Firestore Index Missing' : 'Query Error', style: AppTypography.heading2),
            const SizedBox(height: 8),
            Text(
              isIndexError
                  ? 'Create a composite index:\n'
                      'Collection: Orders\n'
                      'restaurantId ASC \u00B7 status ASC \u00B7 createdAt DESC'
                  : error,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text('No incoming orders', style: TextStyle(color: AppColors.textMuted, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Waiting for new orders...', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final String actorId;
  const _OrderCard({required this.doc, required this.actorId});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final status = d['status'] as String? ?? 'pending';
    final fulfillment = d['fulfillmentType'] as String? ?? 'delivery';
    final isDelivery = fulfillment == 'delivery';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FulfillmentBadge(isDelivery: isDelivery),
                const Spacer(),
                _StatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (d['customerName'] as String? ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['customerName'] as String? ?? 'Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (d['customerPhone'] != null)
                        Text(d['customerPhone'] as String,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '\$${((d['totalAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            if (d['items'] is List && (d['items'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _buildItemsSummary(d['items'] as List),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (status == 'pending' || status == 'accepted' || status == 'preparing')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ActionButtons(
                  status: status,
                  orderId: doc.id,
                  actorId: actorId,
                  context: context,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildItemsSummary(List items) {
    return items
        .take(3)
        .map((i) {
          final item = i as Map<String, dynamic>;
          final qty = item['quantity'] ?? 1;
          final name = item['name'] ?? '';
          return '${qty}\u00D7 $name';
        })
        .join(' \u00B7 ');
  }
}

class _ActionButtons extends StatelessWidget {
  final String status;
  final String orderId;
  final String actorId;
  final BuildContext context;

  const _ActionButtons({
    required this.status,
    required this.orderId,
    required this.actorId,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return switch (status) {
      'pending' => Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => OrderStateMachine.transition(
                  orderId: orderId,
                  newStatus: OrderStatus.fromValue('accepted'),
                  actorId: actorId,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context, orderId, actorId),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      'accepted' => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => OrderStateMachine.transition(
              orderId: orderId,
              newStatus: OrderStatus.fromValue('preparing'),
              actorId: actorId,
            ),
            icon: const Icon(Icons.restaurant, size: 18),
            label: const Text('Start Preparing'),
          ),
        ),
      'preparing' => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => OrderStateMachine.transition(
              orderId: orderId,
              newStatus: OrderStatus.fromValue('ready_for_driver'),
              actorId: actorId,
            ),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Mark Ready for Driver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  void _showRejectDialog(BuildContext ctx, String orderId, String actorId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(hintText: 'Reason for rejection (optional)'),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              OrderStateMachine.rejectOrder(
                orderId: orderId,
                actorId: actorId,
                reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _FulfillmentBadge extends StatelessWidget {
  final bool isDelivery;
  const _FulfillmentBadge({required this.isDelivery});

  @override
  Widget build(BuildContext context) {
    final color = isDelivery ? Colors.blue : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDelivery ? Icons.delivery_dining : Icons.storefront, size: 14, color: color),
          const SizedBox(width: 4),
          Text(isDelivery ? 'Delivery' : 'Pickup',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${label[0].toUpperCase()}${label.substring(1)}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'pending' => Colors.orange,
        'accepted' => Colors.green,
        'preparing' => Colors.blue,
        'ready_for_driver' => Colors.purple,
        'picked_up' => Colors.teal,
        'delivered' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.grey,
      };
}
