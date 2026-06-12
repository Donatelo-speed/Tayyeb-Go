import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'driver_live_map_screen.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  final String requestId;
  final String? deliveryType;
  const ActiveDeliveryScreen({
    super.key,
    required this.requestId,
    this.deliveryType,
  });

  bool get _isFoodOrder => deliveryType == 'food';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(_isFoodOrder ? 'Food Delivery' : 'Anything Delivery', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isFoodOrder
          ? _FoodDeliveryView(requestId: requestId)
          : _AnythingDeliveryView(requestId: requestId),
    );
  }
}

class _FoodDeliveryView extends StatelessWidget {
  final String requestId;
  const _FoodDeliveryView({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('dispatch_requests').doc(requestId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.successColor));
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.inter(color: context.textMutedColor)));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Center(child: Text('Delivery not found', style: GoogleFonts.inter(color: context.textMutedColor)));
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final orderId = d['orderId'] as String? ?? '';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
          builder: (ctx, orderSnap) {
            final orderData = orderSnap.hasData && orderSnap.data!.exists
                ? orderSnap.data!.data() as Map<String, dynamic>
                : <String, dynamic>{};

            final restaurantName = orderData['restaurantName'] as String? ?? d['restaurantName'] as String? ?? '';
            final dispatchStatus = d['status'] as String? ?? '';

            final dispatchLat = (d['pickupLat'] as num?)?.toDouble() ?? 0.0;
            final dispatchLng = (d['pickupLon'] as num?)?.toDouble() ?? 0.0;
            final dropoffLat = (d['dropoffLat'] as num?)?.toDouble() ?? 0.0;
            final dropoffLng = (d['dropoffLon'] as num?)?.toDouble() ?? 0.0;

            final restLat = dispatchLat != 0 ? dispatchLat : ((orderData['pickupLatitude'] as num?)?.toDouble() ?? 0.0);
            final restLng = dispatchLng != 0 ? dispatchLng : ((orderData['pickupLongitude'] as num?)?.toDouble() ?? 0.0);

            final custLat = dropoffLat != 0 ? dropoffLat : ((orderData['dropoffLatitude'] as num?)?.toDouble() ?? 0.0);
            final custLng = dropoffLng != 0 ? dropoffLng : ((orderData['dropoffLongitude'] as num?)?.toDouble() ?? 0.0);

            final deliveryAddr = orderData['deliveryAddress'] is Map
                ? (orderData['deliveryAddress'] as Map<String, dynamic>)['address'] as String? ?? ''
                : orderData['deliveryAddress'] as String? ?? '';
            final deliveryFee = (orderData['deliveryFee'] as num?)?.toDouble() ?? 0.0;

            final hasCoords = restLat != 0 && restLng != 0 && custLat != 0 && custLng != 0;

            return Column(
              children: [
                Expanded(
                  flex: 6,
                  child: hasCoords
                      ? DriverLiveMapScreen(
                          orderId: orderId,
                          restaurantName: restaurantName,
                          restaurantLat: restLat,
                          restaurantLng: restLng,
                          customerAddress: deliveryAddr,
                          customerLat: custLat,
                          customerLng: custLng,
                          deliveryFee: deliveryFee,
                          dispatchId: requestId,
                          currentStatus: dispatchStatus,
                        )
                      : Container(
                          color: context.surfaceColor,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, size: 48, color: context.successColor),
                                const SizedBox(height: 12),
                                Text('Location unavailable', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      children: [
                        Center(
                          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusHeader(ctx, dispatchStatus),
                        const SizedBox(height: 16),
                        _buildStepIndicator(ctx, dispatchStatus),
                        const SizedBox(height: 16),
                        _buildOrderCard(ctx, restaurantName, orderData),
                        const SizedBox(height: 16),
                        _buildActionButtons(ctx, dispatchStatus, requestId, orderId),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusHeader(BuildContext context, String status) {
    final (icon, color, text) = switch (status) {
      'accepted' => (Icons.check_circle_rounded, context.primaryColor, 'Heading to restaurant'),
      'pickedUp' => (Icons.delivery_dining_rounded, context.successColor, 'On the way to customer'),
      'delivered' => (Icons.verified_rounded, context.successColor, 'Delivered'),
      _ => (Icons.info_rounded, context.textMutedColor, 'Status: $status'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, String status) {
    int currentStep = 0;
    if (status == 'accepted') currentStep = 0;
    else if (status == 'enRoute') currentStep = 1;
    else if (status == 'pickedUp') currentStep = 3;
    else if (status == 'delivered') currentStep = 4;

    return Row(
      children: List.generate(5, (i) {
        final isCompleted = i < currentStep;
        final isCurrent = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? context.successColor
                      : isCurrent
                          ? context.primaryColor
                          : context.borderColor,
                ),
              ),
              if (i < 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? context.successColor : context.borderColor,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, String restaurantName, Map<String, dynamic> orderData) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_rounded, size: 18, color: context.successColor),
              const SizedBox(width: 8),
              Expanded(child: Text(restaurantName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor))),
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: context.borderColor)),
          if (orderData['items'] != null)
            ...(orderData['items'] as List<dynamic>).map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${i['quantity'] ?? 1}x ${i['name'] ?? ''}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
            )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext ctx, String status, String dispatchId, String orderId) {
    if (status == 'delivered') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => ctx.go('/dashboard'),
          style: ElevatedButton.styleFrom(backgroundColor: ctx.successColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: Text('Back to Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
    }

    if (status == 'pickedUp') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _confirmDelivery(ctx, dispatchId, orderId),
          style: ElevatedButton.styleFrom(backgroundColor: ctx.successColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: Text('Mark Delivered', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
    }

    if (status == 'accepted' || status == 'enRoute') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () async {
            final prov = ctx.read<DispatchProvider>();
            try {
              await prov.markPickedUp(dispatchId, orderId);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Marked as picked up!')),
                );
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed to mark pickup: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: ctx.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: Text('Picked Up from Restaurant', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirmDelivery(BuildContext ctx, String dispatchId, String orderId) async {
    // Step 1: Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: ctx.successColor, size: 24),
            const SizedBox(width: 10),
            Text('Confirm Delivery', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to mark this delivery as complete? This action cannot be undone.',
          style: GoogleFonts.inter(color: ctx.textSecondaryColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: ctx.textMutedColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: ctx.successColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !ctx.mounted) return;

    // Step 2: Verify delivery PIN
    final pinVerified = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryPinVerificationSheet(
        orderId: orderId,
        onVerified: () {},
      ),
    );

    if (pinVerified != true || !ctx.mounted) return;

    // Step 3: Check if COD order — show COD verification sheet
    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final orderData = orderDoc.data();
      final paymentMethod = orderData?['paymentMethod'] as String? ?? '';
      final orderTotal = (orderData?['totalAmount'] as num?)?.toDouble() ?? 0.0;

      if (paymentMethod == 'cash' && ctx.mounted) {
        final codConfirmed = await showModalBottomSheet<bool>(
          context: ctx,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CodVerificationSheet(
            orderId: orderId,
            orderTotal: orderTotal,
            driverId: ctx.read<AuthProvider>().user?.id ?? '',
          ),
        );

        if (codConfirmed != true || !ctx.mounted) return;
      }

      // Step 4: Complete the delivery
      final prov = ctx.read<DispatchProvider>();
      await prov.completeDelivery(dispatchId, orderId);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Delivery completed successfully!')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to complete delivery: $e')),
        );
      }
    }
  }
}

class _AnythingDeliveryView extends StatelessWidget {
  final String requestId;
  const _AnythingDeliveryView({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('anything_requests').doc(requestId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.successColor));
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.inter(color: context.textMutedColor)));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Center(child: Text('Request not found', style: GoogleFonts.inter(color: context.textMutedColor)));
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final status = AnythingRequestStatus.fromString(d['status'] as String?);
        final storeName = d['storeName'] as String? ?? '';
        final items = (d['items'] as List<dynamic>?)?.map((i) => i as Map<String, dynamic>).toList() ?? [];
        final instructions = d['instructions'] as String? ?? '';
        final dropoffAddress = d['dropoffAddress'] as String? ?? '';
        final customerName = d['customerName'] as String? ?? '';
        final storeLat = (d['storeLatitude'] as num?)?.toDouble() ?? 0.0;
        final storeLng = (d['storeLongitude'] as num?)?.toDouble() ?? 0.0;
        final dropLat = (d['dropoffLatitude'] as num?)?.toDouble() ?? 0.0;
        final dropLng = (d['dropoffLongitude'] as num?)?.toDouble() ?? 0.0;
        final deliveryFee = (d['deliveryFee'] as num?)?.toDouble() ?? 0.0;

        final hasCoords = storeLat != 0 && storeLng != 0 && dropLat != 0 && dropLng != 0;

        final statusStr = switch (status) {
          AnythingRequestStatus.accepted => 'accepted',
          AnythingRequestStatus.shopping => 'shopping',
          AnythingRequestStatus.enRoute => 'pickedUp',
          AnythingRequestStatus.delivered => 'delivered',
          _ => '',
        };

        return Column(
          children: [
            Expanded(
              flex: 6,
              child: hasCoords
                  ? DriverLiveMapScreen(
                      orderId: requestId,
                      restaurantName: storeName,
                      restaurantLat: storeLat,
                      restaurantLng: storeLng,
                      customerAddress: dropoffAddress.isNotEmpty ? dropoffAddress : customerName,
                      customerLat: dropLat,
                      customerLng: dropLng,
                      deliveryFee: deliveryFee,
                      dispatchId: requestId,
                      currentStatus: statusStr,
                    )
                  : Container(
                      color: context.surfaceColor,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 48, color: context.successColor),
                            const SizedBox(height: 12),
                            Text('Location unavailable', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusHeader(context, status),
                    const SizedBox(height: 16),
                    _buildOrderCard(context, storeName, items, instructions),
                    const SizedBox(height: 12),
                    _buildCustomerCard(context, customerName, dropoffAddress),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, status, requestId),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusHeader(BuildContext context, AnythingRequestStatus status) {
    final (icon, color, text) = switch (status) {
      AnythingRequestStatus.accepted => (Icons.check_circle_rounded, context.primaryColor, 'Heading to store'),
      AnythingRequestStatus.shopping => (Icons.shopping_cart_rounded, context.warningColor, 'Shopping'),
      AnythingRequestStatus.enRoute => (Icons.delivery_dining_rounded, context.successColor, 'On the way to customer'),
      AnythingRequestStatus.delivered => (Icons.verified_rounded, context.successColor, 'Delivered'),
      _ => (Icons.info_rounded, context.textMutedColor, 'Status: ${status.firestoreValue}'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String storeName, List<Map<String, dynamic>> items, String instructions) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_rounded, size: 18, color: context.successColor),
              const SizedBox(width: 8),
              Expanded(child: Text(storeName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor))),
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: context.borderColor)),
          ...items.map((i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${i['quantity']}x ${i['name']}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
          )),
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: $instructions', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, String customerName, String dropoffAddress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.person_rounded, size: 18, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deliver to: $customerName', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                Text(dropoffAddress, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext ctx, AnythingRequestStatus status, String requestId) {
    final text = switch (status) {
      AnythingRequestStatus.accepted => 'I arrived at store',
      AnythingRequestStatus.shopping => 'Purchased — on the way',
      AnythingRequestStatus.enRoute => 'Mark Delivered',
      _ => '',
    };
    final icon = switch (status) {
      AnythingRequestStatus.accepted => Icons.shopping_cart_rounded,
      AnythingRequestStatus.shopping => Icons.delivery_dining_rounded,
      AnythingRequestStatus.enRoute => Icons.check_circle_rounded,
      _ => Icons.check_circle_rounded,
    };
    final nextStatus = switch (status) {
      AnythingRequestStatus.accepted => AnythingRequestStatus.shopping,
      AnythingRequestStatus.shopping => AnythingRequestStatus.enRoute,
      AnythingRequestStatus.enRoute => AnythingRequestStatus.delivered,
      _ => AnythingRequestStatus.delivered,
    };

    if (status == AnythingRequestStatus.delivered) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => ctx.go('/dashboard'),
          style: ElevatedButton.styleFrom(backgroundColor: ctx.successColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          child: Text('Back to Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await ctx.read<AnythingProvider>().updateStatus(requestId, nextStatus);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Status updated')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Failed to update status: $e')),
              );
            }
          }
        },
        icon: Icon(icon, size: 20),
        label: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ctx.successColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
