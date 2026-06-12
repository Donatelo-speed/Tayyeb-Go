import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: context.read<CustomerHomeProvider>().watchOrderRaw(orderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text('Failed to load order', style: GoogleFonts.inter(color: context.textMutedColor)),
                ],
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }
          final d = snap.data;
          if (d == null || !snap.hasData) {
            return Center(child: Text('Order not found', style: GoogleFonts.inter(color: context.textMutedColor)));
          }

          final currentStatusString = d['status'] as String? ?? 'placed';
          final currentStatus = OrderStatus.values.firstWhere(
            (s) => s.value == currentStatusString,
            orElse: () => OrderStatus.placed,
          );
          final driverId = d['driverId'] as String?;
          final dropLat = (d['dropoffLatitude'] as num?)?.toDouble();
          final dropLng = (d['dropoffLongitude'] as num?)?.toDouble();
          final cancellable = currentStatus == OrderStatus.placed || currentStatus == OrderStatus.accepted;
          final isDelivered = currentStatus == OrderStatus.delivered;
          final rated = d['customerRating'] != null;

          return Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  color: context.surfaceColor,
                  child: _LiveMapSection(
                    orderId: orderId,
                    driverId: driverId,
                    dropLat: dropLat,
                    dropLng: dropLng,
                    currentStatus: currentStatus,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
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
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _statusIconColor(context, currentStatus).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_statusIcon(currentStatus), size: 24, color: _statusIconColor(context, currentStatus)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_statusTitle(currentStatus), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
                                Text('Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (currentStatusString == 'dispatched' && driverId != null && dropLat != null && dropLng != null)
                        _EtaCard(driverId: driverId, destination: GeoLocation(dropLat, dropLng)),
                      if (driverId != null) _DriverContactCard(driverId: driverId),
                      if ((currentStatusString == 'dispatched' || currentStatusString == 'pickedUp') && d['deliveryPin'] != null)
                        _DeliveryPinCard(pin: d['deliveryPin'] as String),
                      _buildTimeline(context, currentStatus),
                      const SizedBox(height: 12),
                      _buildOrderDetails(context, d),
                      if (isDelivered && !rated) ...[
                        const SizedBox(height: 12),
                        OrderRating(orderId: orderId, restaurantId: d['restaurantId'] as String? ?? ''),
                      ],
                      if (cancellable) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _confirmCancel(context, d),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.errorColor,
                              side: BorderSide(color: context.errorColor.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel Order', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, OrderStatus currentStatus) {
    return Column(
      children: List.generate(6, (i) {
        final step = OrderStateMachine.buildTimeline(currentStatus, i);
        final isActive = step.isCompleted || step.isCurrent;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(width: 2, color: step.isCompleted ? context.successColor : context.borderColor),
                      )
                    else
                      const Expanded(child: SizedBox()),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: step.isCurrent ? 14 : 10,
                      height: step.isCurrent ? 14 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCompleted
                            ? context.successColor
                            : step.isCurrent
                                ? context.primaryColor
                                : context.borderColor,
                        border: step.isCurrent
                            ? Border.all(color: context.primaryColor.withValues(alpha: 0.3), width: 3)
                            : null,
                      ),
                    ),
                    if (i < 5)
                      Expanded(
                        child: Container(width: 2, color: step.isCompleted ? context.successColor : context.borderColor),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: step.isCurrent ? context.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.label,
                          style: GoogleFonts.inter(
                            fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                            color: isActive ? context.textPrimaryColor : context.textMutedColor,
                          ),
                        ),
                      ),
                      if (step.isCompleted)
                        Icon(Icons.check_circle, color: context.successColor, size: 16),
                      if (step.isCurrent)
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderDetails(BuildContext context, Map<String, dynamic> d) {
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
          Text('Order Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
          const SizedBox(height: 8),
          _detailRow(context, 'Type', d['fulfillmentType'] as String? ?? 'delivery'),
          _detailRow(context, 'Total', '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0.0}'),
          if (d['deliveryAddress'] is Map)
            _detailRow(context, 'Address', (d['deliveryAddress'] as Map)['fullAddress'] as String? ?? '—'),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: Text('Are you sure you want to cancel this order?', style: GoogleFonts.inter(color: context.textMutedColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Order', style: GoogleFonts.inter(color: context.textMutedColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await OrderStateMachine.transition(
                  orderId: orderId,
                  newStatus: OrderStatus.cancelled,
                  actorId: context.read<AuthProvider>().user?.id ?? '',
                  note: 'Cancelled by customer',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order cancelled', style: GoogleFonts.inter()),
                      backgroundColor: context.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel', style: GoogleFonts.inter()),
                      backgroundColor: context.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            child: Text('Cancel Order', style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.pending:
        return Icons.receipt_long_rounded;
      case OrderStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.ready:
      case OrderStatus.readyForDriver:
        return Icons.delivery_dining_rounded;
      case OrderStatus.dispatched:
      case OrderStatus.pickedUp:
        return Icons.pedal_bike_rounded;
      case OrderStatus.delivered:
      case OrderStatus.refunded:
        return Icons.verified_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  Color _statusIconColor(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return context.successColor;
      case OrderStatus.cancelled:
        return context.errorColor;
      case OrderStatus.placed:
        return context.warningColor;
      default:
        return context.primaryColor;
    }
  }

  String _statusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Being Prepared';
      case OrderStatus.ready:
      case OrderStatus.readyForDriver:
        return 'Out for Delivery';
      case OrderStatus.dispatched:
      case OrderStatus.pickedUp:
        return 'On the Way';
      case OrderStatus.delivered:
      case OrderStatus.refunded:
        return 'Delivered!';
      case OrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }
}

class _EtaCard extends StatelessWidget {
  final String driverId;
  final GeoLocation destination;

  const _EtaCard({required this.driverId, required this.destination});

  @override
  Widget build(BuildContext context) {
    final etaService = EtaService();
    return StreamBuilder<int>(
      stream: etaService.watchEtaMinutes(driverId: driverId, destination: destination),
      builder: (context, snap) {
        final eta = snap.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delivery_dining_rounded, color: context.primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Arrival', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                    const SizedBox(height: 2),
                    if (eta == null || eta < 0)
                      Text('Calculating...', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor))
                    else ...[
                      Text(
                        '$eta min',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: context.textPrimaryColor),
                      ),
                      Text(
                        eta <= 2 ? 'Almost there!' : 'Driver is on the way',
                        style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverContactCard extends StatelessWidget {
  final String driverId;

  const _DriverContactCard({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(driverId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final driverData = snap.data!.data() as Map<String, dynamic>?;
        final driverName = driverData?['displayName'] as String? ?? 'Driver';
        final driverPhone = driverData?['phoneNumber'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person_rounded, color: context.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Driver', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(driverName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: driverPhone != null ? () => _launchCall(driverPhone) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: driverPhone != null ? context.successColor : context.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call_rounded, color: driverPhone != null ? context.successColor : context.textMutedColor, size: 20),
                            const SizedBox(width: 8),
                            Text('Call', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: driverPhone != null ? context.successColor : context.textMutedColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: driverPhone != null ? () => _launchMessage(driverPhone) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: driverPhone != null ? context.primaryColor : context.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_rounded, color: driverPhone != null ? context.primaryColor : context.textMutedColor, size: 20),
                            const SizedBox(width: 8),
                            Text('Message', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: driverPhone != null ? context.primaryColor : context.textMutedColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchCall(String phone) async {
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Failed to launch call: $e');
    }
  }

  Future<void> _launchMessage(String phone) async {
    try {
      final uri = Uri(scheme: 'sms', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Failed to launch message: $e');
    }
  }
}

class _DeliveryPinCard extends StatelessWidget {
  final String pin;
  const _DeliveryPinCard({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.primaryColor.withValues(alpha: 0.15), context.primaryColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.pin_rounded, color: context.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery PIN', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textMutedColor)),
                const SizedBox(height: 4),
                Text(
                  pin,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 28, color: context.primaryColor, letterSpacing: 8),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Share with driver', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: context.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _LiveMapSection extends StatelessWidget {
  final String orderId;
  final String? driverId;
  final double? dropLat;
  final double? dropLng;
  final OrderStatus currentStatus;

  const _LiveMapSection({
    required this.orderId,
    required this.driverId,
    required this.dropLat,
    required this.dropLng,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    // If no driver assigned or no destination, show placeholder
    if (driverId == null || dropLat == null || dropLng == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(currentStatus), size: 48, color: _statusIconColor(context, currentStatus)),
            const SizedBox(height: 12),
            Text('Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              currentStatus == OrderStatus.placed || currentStatus == OrderStatus.accepted
                  ? 'Waiting for driver assignment...'
                  : 'Driver will be assigned soon',
              style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Show live map when driver is assigned
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('driver_locations').doc(driverId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 48, color: context.textMutedColor),
                const SizedBox(height: 12),
                Text('Map unavailable', style: GoogleFonts.inter(color: context.textMutedColor)),
              ],
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_searching_rounded, size: 48, color: context.primaryColor),
                const SizedBox(height: 12),
                Text('Locating driver...', style: GoogleFonts.inter(color: context.textMutedColor)),
                const SizedBox(height: 16),
                SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor)),
              ],
            ),
          );
        }

        final driverData = snap.data!.data() as Map<String, dynamic>?;
        final driverLat = (driverData?['latitude'] as num?)?.toDouble();
        final driverLng = (driverData?['longitude'] as num?)?.toDouble();

        if (driverLat == null || driverLng == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_searching_rounded, size: 48, color: context.primaryColor),
                const SizedBox(height: 12),
                Text('Waiting for driver location...', style: GoogleFonts.inter(color: context.textMutedColor)),
                const SizedBox(height: 16),
                SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor)),
              ],
            ),
          );
        }

        return FlutterMap(
          options: MapOptions(
            initialCenter: LatLng((driverLat + (dropLat ?? driverLat)) / 2, (driverLng + (dropLng ?? driverLng)) / 2),
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tayyebgo.customer',
            ),
            MarkerLayer(
              markers: [
                // Driver marker
                Marker(
                  point: LatLng(driverLat, driverLng),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.directions_bike_rounded, color: Colors.white, size: 20),
                  ),
                ),
                // Destination marker
                if (dropLat != null && dropLng != null)
                Marker(
                  point: LatLng(dropLat!, dropLng!),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.successColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.successColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            PolylineLayer(
              polylines: [
                if (dropLat != null && dropLng != null)
                Polyline(
                  points: [
                    LatLng(driverLat, driverLng),
                    LatLng(dropLat!, dropLng!),
                  ],
                  strokeWidth: 3.0,
                  color: context.primaryColor,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.pending:
        return Icons.receipt_long_rounded;
      case OrderStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.ready:
      case OrderStatus.readyForDriver:
        return Icons.delivery_dining_rounded;
      case OrderStatus.dispatched:
      case OrderStatus.pickedUp:
        return Icons.pedal_bike_rounded;
      case OrderStatus.delivered:
      case OrderStatus.refunded:
        return Icons.verified_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  Color _statusIconColor(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return context.successColor;
      case OrderStatus.cancelled:
        return context.errorColor;
      case OrderStatus.placed:
        return context.warningColor;
      default:
        return context.primaryColor;
    }
  }
}
