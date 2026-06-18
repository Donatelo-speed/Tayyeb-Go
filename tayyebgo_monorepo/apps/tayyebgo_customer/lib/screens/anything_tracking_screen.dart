import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:url_launcher/url_launcher.dart';

class AnythingTrackingScreen extends StatelessWidget {
  final String requestId;
  const AnythingTrackingScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Anything Request', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: context.read<AnythingProvider>().streamRequest(requestId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Failed to load request', style: GoogleFonts.inter(color: context.textMutedColor)));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }
          final d = snap.data;
          if (d == null || !snap.hasData) {
            return Center(child: Text('Request not found', style: GoogleFonts.inter(color: context.textMutedColor)));
          }
          final status = AnythingRequestStatus.fromString(d['status'] as String?);
          final driverName = d['driverName'] as String?;
          final driverId = d['driverId'] as String?;
          final driverLat = (d['driverLatitude'] as num?)?.toDouble();
          final driverLng = (d['driverLongitude'] as num?)?.toDouble();
          final storeName = d['storeName'] as String? ?? 'Store';
          final items = (d['items'] as List<dynamic>?)?.map((i) => i as Map<String, dynamic>).toList() ?? [];
          final instructions = d['instructions'] as String? ?? '';
          final budget = (d['budget'] as num?)?.toDouble() ?? 0;
          final isCancellable = status == AnythingRequestStatus.pending;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBanner(status: status, isCancellable: isCancellable, requestId: requestId),
              const SizedBox(height: 16),
              _InfoCard(storeName: storeName, items: items, instructions: instructions, budget: budget),
              if (driverName != null) ...[
                const SizedBox(height: 12),
                _DriverCard(driverName: driverName, driverId: driverId, hasLocation: driverLat != null && driverLng != null),
              ],
              if (driverLat != null && driverLng != null) ...[
                const SizedBox(height: 12),
                _MapCard(lat: driverLat, lng: driverLng),
              ],
              const SizedBox(height: 16),
              _Timeline(status: status),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final AnythingRequestStatus status;
  final bool isCancellable;
  final String requestId;

  const _StatusBanner({required this.status, required this.isCancellable, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (status) {
      AnythingRequestStatus.pending => (Icons.hourglass_empty_rounded, context.warningColor, 'Looking for a driver'),
      AnythingRequestStatus.accepted => (Icons.check_circle_rounded, context.primaryColor, 'Driver accepted'),
      AnythingRequestStatus.shopping => (Icons.shopping_cart_rounded, AppColors.adminAccent, 'Driver is shopping'),
      AnythingRequestStatus.enRoute => (Icons.delivery_dining_rounded, context.primaryColor, 'On the way'),
      AnythingRequestStatus.delivered => (Icons.check_circle_rounded, context.successColor, 'Delivered'),
      AnythingRequestStatus.cancelled => (Icons.cancel_rounded, context.errorColor, 'Cancelled'),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
          ),
          if (isCancellable)
            TextButton(
              onPressed: () {
                context.read<AnythingProvider>().cancelRequest(requestId);
                context.go('/home');
              },
              child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.errorColor)),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String storeName;
  final List<Map<String, dynamic>> items;
  final String instructions;
  final double budget;

  const _InfoCard({required this.storeName, required this.items, required this.instructions, required this.budget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_rounded, size: 20, color: context.primaryColor),
              const SizedBox(width: 8),
              Text(storeName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          Divider(height: 24, color: context.borderColor),
          ...items.map((i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text('${i['quantity']}x ${i['name']}', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14)),
          )),
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Note: $instructions', style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: context.textMutedColor, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, size: 16, color: context.primaryColor),
              const SizedBox(width: 6),
              Text('Budget: SYP ${budget.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final String driverName;
  final String? driverId;
  final bool hasLocation;

  const _DriverCard({required this.driverName, this.driverId, required this.hasLocation});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: driverId != null
          ? FirebaseFirestore.instance.collection('users').doc(driverId).snapshots()
          : const Stream.empty(),
      builder: (context, snap) {
        final driverPhone = (snap.data?.data() as Map<String, dynamic>?)?['phoneNumber'] as String?;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: AppRadius.brMd,
                ),
                child: Center(
                  child: Text(driverName.isNotEmpty ? driverName[0].toUpperCase() : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: context.textPrimaryColor)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driverName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                    if (hasLocation)
                      Text('Live location available', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.message_rounded, color: driverPhone != null ? context.primaryColor : context.textMutedColor, size: 20),
                onPressed: driverPhone != null ? () => _launchMessage(driverPhone) : null,
              ),
              IconButton(
                icon: Icon(Icons.phone_rounded, color: driverPhone != null ? context.primaryColor : context.textMutedColor, size: 20),
                onPressed: driverPhone != null ? () => _launchCall(driverPhone) : null,
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

class _MapCard extends StatelessWidget {
  final double lat;
  final double lng;

  const _MapCard({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, size: 48, color: context.surfaceAltColor),
            const SizedBox(height: 10),
            Text('Driver location: $lat, $lng', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
            const SizedBox(height: 4),
            Text('(Live map placeholder)', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final AnythingRequestStatus status;

  const _Timeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (status: AnythingRequestStatus.pending, icon: Icons.hourglass_empty_rounded, label: 'Request Sent'),
      (status: AnythingRequestStatus.accepted, icon: Icons.check_circle_rounded, label: 'Driver Accepted'),
      (status: AnythingRequestStatus.shopping, icon: Icons.shopping_cart_rounded, label: 'Shopping'),
      (status: AnythingRequestStatus.enRoute, icon: Icons.delivery_dining_rounded, label: 'On the Way'),
      (status: AnythingRequestStatus.delivered, icon: Icons.check_circle_rounded, label: 'Delivered'),
    ];
    final currentIndex = steps.indexWhere((s) => s.status == status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isComplete = i <= currentIndex;
            final isCurrent = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(step.icon, size: 20, color: isComplete ? context.primaryColor : context.textMutedColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(step.label, style: GoogleFonts.inter(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isComplete ? context.primaryColor : context.textMutedColor,
                    )),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brXl,
                      ),
                      child: Text('Current', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, color: context.primaryColor)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
