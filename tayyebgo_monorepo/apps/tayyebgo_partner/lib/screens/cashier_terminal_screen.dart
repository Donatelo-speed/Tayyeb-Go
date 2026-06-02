import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/offline_queue_provider.dart';
import '../providers/partner_role_controller.dart';

class CashierTerminalView extends StatefulWidget {
  const CashierTerminalView({super.key});

  @override
  State<CashierTerminalView> createState() => _CashierTerminalViewState();
}

class _CashierTerminalViewState extends State<CashierTerminalView> {
  @override
  void initState() {
    super.initState();
    context.read<OfflineQueueProvider>().load();
  }

  Future<void> _handleTransition({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    try {
      await OrderStateMachine.transition(
        orderId: orderId,
        newStatus: newStatus,
        actorId: actorId,
        latitude: latitude,
        longitude: longitude,
        note: note,
      );
    } catch (_) {
      if (!context.mounted) return;
      await context.read<OfflineQueueProvider>().enqueue(
        PendingOperation(
          id: '${orderId}_${DateTime.now().millisecondsSinceEpoch}',
          type: PendingOperationType.transitionOrder,
          orderId: orderId,
          newStatus: newStatus,
          actorId: actorId,
          location: latitude != null && longitude != null
              ? GeoLocation(latitude, longitude)
              : null,
          createdAt: DateTime.now(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No connection — queued to sync later')),
        );
      }
    }
  }

  Future<void> _handleReject({
    required String orderId,
    required String actorId,
    String? reason,
  }) async {
    try {
      await OrderStateMachine.rejectOrder(
        orderId: orderId,
        actorId: actorId,
        reason: reason,
      );
    } catch (_) {
      if (!context.mounted) return;
      await context.read<OfflineQueueProvider>().enqueue(
        PendingOperation(
          id: '${orderId}_${DateTime.now().millisecondsSinceEpoch}',
          type: PendingOperationType.rejectOrder,
          orderId: orderId,
          rejectionReason: reason,
          actorId: actorId,
          createdAt: DateTime.now(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No connection — queued to sync later')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<OfflineQueueProvider>().pendingCount;

    return Scaffold(
      backgroundColor: TayyebGoTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Incoming Orders'),
            if (pendingCount > 0) ...[
              const SizedBox(width: 10),
              Badge(
                label: Text('$pendingCount'),
                child: const Icon(Icons.sync_problem, size: 20),
              ),
            ],
          ],
        ),
        actions: [
          if (pendingCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$pendingCount pending sync',
                  style: TextStyle(
                    color: TayyebGoTheme.warningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout, color: TayyebGoTheme.errorColor),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: StreamScreenBuilder<QuerySnapshot>(
        stream: () {
          final restaurantId = context.read<PartnerRoleController>().restaurantId;
          var query = FirebaseFirestore.instance
              .collection('Orders')
              .where('status', whereIn: ['placed', 'accepted', 'preparing'] as List<Object?>);
          if (restaurantId != null) {
            query = query.where('restaurantId', isEqualTo: restaurantId);
          }
          return query.orderBy('createdAt', descending: true).snapshots();
        }(),
        onLoading: () => const ShimmerLoading(itemCount: 3, itemHeight: 180),
        onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
        onSuccess: (context, snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 80,
                      color: TayyebGoTheme.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No incoming orders',
                      style: TextStyle(
                          color: TayyebGoTheme.textMuted, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Waiting for new orders...', style: TayyebGoTheme.caption),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) => _OrderCard(
                doc: docs[i],
                onTransition: _handleTransition,
                onReject: _handleReject,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Future<void> Function({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    double? latitude,
    double? longitude,
    String? note,
  }) onTransition;
  final Future<void> Function({
    required String orderId,
    required String actorId,
    String? reason,
  }) onReject;

  const _OrderCard({
    required this.doc,
    required this.onTransition,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final status = OrderStatus.fromValue(d['status'] as String? ?? '');
    final fulfillment = d['fulfillmentType'] as String? ?? 'delivery';
    final isDelivery = fulfillment == 'delivery';
    final auth = context.read<AuthProvider>();
    final actorId = auth.user?.id ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: TayyebGoTheme.elevatedCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDelivery ? Colors.blue : Colors.amber)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDelivery
                            ? Icons.delivery_dining
                            : Icons.storefront,
                        size: 14,
                        color: isDelivery ? Colors.blue : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDelivery ? 'Delivery' : 'Pickup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDelivery ? Colors.blue : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _StatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    (d['customerName'] as String? ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                        color: TayyebGoTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['customerName'] as String? ?? 'Customer',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (d['customerPhone'] != null)
                        Text(d['customerPhone'] as String,
                            style: TextStyle(
                                color: TayyebGoTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if (status == OrderStatus.placed || status == OrderStatus.accepted ||
                status == OrderStatus.preparing || status == OrderStatus.ready)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (status == OrderStatus.placed) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onTransition(
                            orderId: doc.id,
                            newStatus: OrderStatus.accepted,
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
                          onPressed: () =>
                              _showRejectDialog(context, doc.id, actorId),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                    if (status == OrderStatus.accepted)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onTransition(
                            orderId: doc.id,
                            newStatus: OrderStatus.preparing,
                            actorId: actorId,
                          ),
                          icon: const Icon(Icons.restaurant, size: 18),
                          label: const Text('Start Preparing'),
                        ),
                      ),
                    if (status == OrderStatus.preparing)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onTransition(
                            orderId: doc.id,
                            newStatus: OrderStatus.ready,
                            actorId: actorId,
                          ),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Mark Ready'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (status == OrderStatus.ready)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onTransition(
                            orderId: doc.id,
                            newStatus: OrderStatus.readyForDriver,
                            actorId: actorId,
                          ),
                          icon: const Icon(Icons.delivery_dining, size: 18),
                          label: const Text('Available for Driver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, String orderId, String actorId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReject(
                orderId: orderId,
                actorId: actorId,
                reason:
                    reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null,
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

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    return OrderStatusBadge(status: status.value);
  }
}
