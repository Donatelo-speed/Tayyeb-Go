import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/offline_queue_provider.dart';

class KitchenModeScreen extends StatefulWidget {
  final String restaurantId;
  const KitchenModeScreen({super.key, required this.restaurantId});
  @override
  State<KitchenModeScreen> createState() => _KitchenModeScreenState();
}

class _KitchenModeScreenState extends State<KitchenModeScreen> {
  @override
  Widget build(BuildContext context) {
    final actorId = context.watch<AuthProvider>().user?.id ?? '';
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Kitchen Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.textMutedColor),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<PartnerHomeProvider>().watchKitchenOrders(widget.restaurantId),
        builder: (context, snap) {
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
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator(color: context.warningColor));
          }

          final docs = snap.data!;
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
                    child: Icon(Icons.kitchen_rounded, size: 36, color: context.textMutedColor),
                  ),
                  const SizedBox(height: 16),
                  Text('No active orders', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Orders will appear here when they come in', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: docs.length,
            itemBuilder: (_, idx) {
              final d = docs[idx];
              final s = d['status'] as String? ?? '';
              final statusIsAccepted = s == 'accepted';
              final items = (d['items'] as List<dynamic>?)?.map((it) => it as Map<String, dynamic>).toList() ?? [];
              final customerName = d['customerName'] as String? ?? 'Guest';
              final orderId = d['id'] as String;

              return Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.brCard,
                  border: Border.all(
                    color: statusIsAccepted
                        ? context.warningColor.withValues(alpha: 0.2)
                        : context.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: statusIsAccepted ? context.warningColor : context.primaryColor,
                              borderRadius: AppRadius.brMd,
                            ),
                            child: Center(
                              child: Text('${idx + 1}', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(customerName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusIsAccepted ? context.warningColor.withValues(alpha: 0.1) : context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Text(
                              statusIsAccepted ? 'New' : 'Prep',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusIsAccepted ? context.warningColor : context.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: context.borderColor, height: 1)),
                      Expanded(
                        child: ListView(
                          children: items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${item['quantity']}x ${item['name']}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            final nextStatus = statusIsAccepted ? 'preparing' : 'ready_for_driver';
                            try {
                              await OrderStateMachine.transition(
                                orderId: orderId,
                                newStatus: OrderStatus.fromValue(nextStatus),
                                actorId: actorId,
                                note: statusIsAccepted ? 'Started preparing' : 'Order ready',
                              );
                            } catch (_) {
                              await context.read<OfflineQueueProvider>().enqueue(
                                PendingOperation(
                                  id: '${orderId}_${DateTime.now().millisecondsSinceEpoch}',
                                  type: PendingOperationType.transitionOrder,
                                  orderId: orderId,
                                  newStatus: OrderStatus.fromValue(nextStatus),
                                  actorId: actorId,
                                  createdAt: DateTime.now(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusIsAccepted ? context.warningColor : context.successColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                            elevation: 0,
                          ),
                          child: Text(
                            statusIsAccepted ? 'Start Prep' : 'Mark Ready',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
