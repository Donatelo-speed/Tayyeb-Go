import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          SnackBar(
            content: Text(
              'No connection — queued to sync later',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: context.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
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
          SnackBar(
            content: Text(
              'No connection — queued to sync later',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: context.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<OfflineQueueProvider>().pendingCount;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.partnerAccent, Color(0xFFFCD34D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.brMd,
              ),
              child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Cashier Terminal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: context.textPrimaryColor,
              ),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.warningColor,
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(
                  '$pendingCount pending',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: context.textMutedColor),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: () {
          final restaurantId = context.read<PartnerRoleController>().restaurantId;
          var query = FirebaseFirestore.instance
              .collection('orders')
              .where('status', whereIn: ['placed', 'accepted', 'preparing'] as List<Object?>);
          if (restaurantId != null) {
            query = query.where('restaurantId', isEqualTo: restaurantId);
          }
          return query.orderBy('createdAt', descending: true).snapshots();
        }(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.partnerAccent),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: context.errorColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded, size: 32, color: context.errorColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please check your connection',
                    style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.partnerAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 36,
                      color: AppColors.partnerAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No incoming orders',
                    style: GoogleFonts.inter(
                      color: context.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Waiting for new orders...',
                    style: GoogleFonts.inter(
                      color: context.textMutedColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.partnerAccent,
            backgroundColor: context.surfaceColor,
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
    final customerName = d['customerName'] as String? ?? 'Customer';
    final items = d['items'] as List? ?? [];
    final itemCount = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));
    final totalAmount = (d['totalAmount'] as num?)?.toDouble() ?? 0;

    final statusColor = switch (status) {
      OrderStatus.placed => context.warningColor,
      OrderStatus.accepted => AppColors.driverAccent,
      OrderStatus.preparing => AppColors.primary,
      _ => context.textMutedColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDelivery ? AppColors.primary : context.warningColor).withValues(alpha: 0.1),
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded,
                      size: 12,
                      color: isDelivery ? AppColors.primary : context.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDelivery ? 'Delivery' : 'Pickup',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDelivery ? AppColors.primary : context.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(
                  status.value.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.partnerAccent.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                ),
                child: Center(
                  child: Text(
                    customerName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.partnerAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'} • \$${totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: context.textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons based on status
          if (status == OrderStatus.placed) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => onTransition(
                        orderId: doc.id,
                        newStatus: OrderStatus.accepted,
                        actorId: actorId,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context, doc.id, actorId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.errorColor,
                        side: BorderSide(color: context.errorColor.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status == OrderStatus.accepted)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => onTransition(
                  orderId: doc.id,
                  newStatus: OrderStatus.preparing,
                  actorId: actorId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  elevation: 0,
                ),
                child: Text(
                  'Start Preparing',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          if (status == OrderStatus.preparing)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => onTransition(
                  orderId: doc.id,
                  newStatus: OrderStatus.ready,
                  actorId: actorId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.successColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  elevation: 0,
                ),
                child: Text(
                  'Mark Ready',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          if (status == OrderStatus.ready)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => onTransition(
                  orderId: doc.id,
                  newStatus: OrderStatus.readyForDriver,
                  actorId: actorId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.partnerAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  elevation: 0,
                ),
                child: Text(
                  'Available for Driver',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String orderId, String actorId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
        title: Text(
          'Reject Order',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor),
        ),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: GoogleFonts.inter(color: context.textMutedColor),
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.errorColor),
            ),
            filled: true,
            fillColor: context.backgroundColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReject(
                orderId: orderId,
                actorId: actorId,
                reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null,
              );
            },
            child: Text(
              'Reject',
              style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
