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
          location: latitude != null && longitude != null ? GeoLocation(latitude, longitude) : null,
          createdAt: DateTime.now(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No connection — queued to sync later', style: GoogleFonts.inter()), backgroundColor: context.warningColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
      await OrderStateMachine.rejectOrder(orderId: orderId, actorId: actorId, reason: reason);
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
          SnackBar(content: Text('No connection — queued to sync later', style: GoogleFonts.inter()), backgroundColor: context.warningColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
            Text('Incoming Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            if (pendingCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.warningColor, borderRadius: BorderRadius.circular(10)),
                child: Text('$pendingCount', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
            return Center(child: CircularProgressIndicator(color: context.warningColor));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text('Error loading orders', style: GoogleFonts.inter(color: context.textMutedColor)),
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
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Icon(Icons.inbox_outlined, size: 36, color: context.textMutedColor),
                  ),
                  const SizedBox(height: 16),
                  Text('No incoming orders', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Waiting for new orders...', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: context.warningColor,
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
  final Future<void> Function({required String orderId, required OrderStatus newStatus, required String actorId, double? latitude, double? longitude, String? note}) onTransition;
  final Future<void> Function({required String orderId, required String actorId, String? reason}) onReject;

  const _OrderCard({required this.doc, required this.onTransition, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final status = OrderStatus.fromValue(d['status'] as String? ?? '');
    final fulfillment = d['fulfillmentType'] as String? ?? 'delivery';
    final isDelivery = fulfillment == 'delivery';
    final auth = context.read<AuthProvider>();
    final actorId = auth.user?.id ?? '';

    final statusColor = switch (status) {
      OrderStatus.placed => context.warningColor,
      OrderStatus.accepted => context.primaryColor,
      OrderStatus.preparing => context.primaryColor,
      _ => context.textMutedColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDelivery ? context.primaryColor : context.warningColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded, size: 12, color: isDelivery ? context.primaryColor : context.warningColor),
                    const SizedBox(width: 4),
                    Text(isDelivery ? 'Delivery' : 'Pickup', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDelivery ? context.primaryColor : context.warningColor)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.value.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text((d['customerName'] as String? ?? '?')[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['customerName'] as String? ?? 'Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                    if (d['customerPhone'] != null)
                      Text(d['customerPhone'] as String, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (status == OrderStatus.placed) ...[
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => onTransition(orderId: doc.id, newStatus: OrderStatus.accepted, actorId: actorId),
                      style: ElevatedButton.styleFrom(backgroundColor: context.successColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: Text('Accept', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context, doc.id, actorId),
                      style: OutlinedButton.styleFrom(foregroundColor: context.errorColor, side: BorderSide(color: context.errorColor.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ),
              ],
              if (status == OrderStatus.accepted)
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => onTransition(orderId: doc.id, newStatus: OrderStatus.preparing, actorId: actorId),
                      style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: Text('Start Preparing', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
              if (status == OrderStatus.preparing)
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => onTransition(orderId: doc.id, newStatus: OrderStatus.ready, actorId: actorId),
                      style: ElevatedButton.styleFrom(backgroundColor: context.successColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: Text('Mark Ready', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
              if (status == OrderStatus.ready)
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => onTransition(orderId: doc.id, newStatus: OrderStatus.readyForDriver, actorId: actorId),
                      style: ElevatedButton.styleFrom(backgroundColor: context.warningColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: Text('Available for Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Order', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Reason for rejection (optional)',
            hintStyle: GoogleFonts.inter(color: context.textMutedColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.errorColor)),
            filled: true,
            fillColor: context.backgroundColor,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReject(orderId: orderId, actorId: actorId, reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null);
            },
            child: Text('Reject', style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
