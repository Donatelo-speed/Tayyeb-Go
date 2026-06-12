import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class OperationsCenterView extends StatefulWidget {
  const OperationsCenterView({super.key});
  @override
  State<OperationsCenterView> createState() => _OperationsCenterViewState();
}

class _OperationsCenterViewState extends State<OperationsCenterView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) return _buildWideLayout();
            return _buildNarrowLayout();
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildMapSection()),
        const SizedBox(width: 16),
        SizedBox(
          width: 420,
          child: _buildSidePanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        SizedBox(height: 350, child: _buildMapSection()),
        const SizedBox(height: 16),
        Expanded(child: _buildSidePanel()),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(34.7369, 36.7131),
              initialZoom: 12,
              onMapReady: () {},
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tayyebgo.admin',
              ),
              _DriverMarkerLayer(),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _MapOverlayBadge(
              icon: Icons.delivery_dining_rounded,
              stream: FirebaseFirestore.instance
                  .collection('driver_locations')
                  .where('isOnline', isEqualTo: true)
                  .snapshots(),
              label: 'Online Drivers',
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _MapOverlayBadge(
              icon: Icons.receipt_long_rounded,
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', whereIn: ['placed', 'accepted', 'preparing', 'ready', 'dispatched'])
                  .snapshots(),
              label: 'Active Orders',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Column(
      children: [
        _SectionHeader(title: 'Delayed Orders', icon: Icons.warning_amber_rounded),
        const SizedBox(height: 8),
        Expanded(flex: 2, child: _DelayedOrdersList()),
        const SizedBox(height: 12),
        _SectionHeader(title: 'Fraud Alerts', icon: Icons.shield_rounded),
        const SizedBox(height: 8),
        Expanded(flex: 2, child: _FraudAlertsList()),
        const SizedBox(height: 12),
        _SectionHeader(title: 'Failed Payments', icon: Icons.payment_rounded),
        const SizedBox(height: 8),
        Expanded(child: _FailedPaymentsList()),
      ],
    );
  }
}

// ─── Driver Map Markers ──────────────────────────────────────────────

class _DriverMarkerLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('driver_locations')
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        return MarkerLayer(
          markers: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final lat = (data['latitude'] as num?)?.toDouble() ?? 0;
            final lng = (data['longitude'] as num?)?.toDouble() ?? 0;
            final name = data['driverName'] as String? ?? 'Driver';
            final status = data['status'] as String? ?? 'online';
            final color = status == 'delivering' ? Colors.orange : Colors.green;
            return Marker(
              point: LatLng(lat, lng),
              width: 36,
              height: 36,
              child: Tooltip(
                message: '$name ($status)',
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 18),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Map Overlay Badge ───────────────────────────────────────────────

class _MapOverlayBadge extends StatelessWidget {
  final IconData icon;
  final Stream<QuerySnapshot> stream;
  final String label;

  const _MapOverlayBadge({
    required this.icon,
    required this.stream,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.surfaceColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: context.primaryColor),
              const SizedBox(width: 6),
              Text(
                '$count $label',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.primaryColor),
        const SizedBox(width: 6),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
      ],
    );
  }
}

// ─── Delayed Orders ──────────────────────────────────────────────────

class _DelayedOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['placed', 'accepted', 'preparing', 'ready', 'dispatched'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyCard(message: 'No active orders');
        }
        final now = DateTime.now();
        final delayed = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt == null) return false;
          return now.difference(createdAt).inMinutes > 30;
        }).toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            return (aTime?.toDate() ?? DateTime.now()).compareTo(bTime?.toDate() ?? DateTime.now());
          });
        if (delayed.isEmpty) {
          return _EmptyCard(message: 'All orders on time');
        }
        return ListView.builder(
          itemCount: delayed.length,
          itemBuilder: (context, index) => _DelayedOrderCard(doc: delayed[index]),
        );
      },
    );
  }
}

class _DelayedOrderCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _DelayedOrderCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final restaurant = data['restaurantName'] as String? ?? 'Unknown';
    final status = data['status'] as String? ?? 'unknown';
    final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final delay = createdAt != null ? DateTime.now().difference(createdAt).inMinutes : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.access_time_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text('$status • \$${amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${delay}m late', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Fraud Alerts ────────────────────────────────────────────────────

class _FraudAlertsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fraud_alerts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyCard(message: 'No fraud alerts');
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] as String? ?? 'unknown';
            final userId = data['userId'] as String? ?? 'unknown';
            final risk = (data['riskScore'] as num?)?.toDouble() ?? 0;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.red)),
                        const SizedBox(height: 2),
                        Text('User: ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}...', style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _RiskBadge(score: risk),
                      if (createdAt != null)
                        Text(_fmtTime(createdAt), style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _RiskBadge extends StatelessWidget {
  final double score;
  const _RiskBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0.7 ? Colors.red : score > 0.4 ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('${(score * 100).toInt()}%', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: color)),
    );
  }
}

// ─── Failed Payments ─────────────────────────────────────────────────

class _FailedPaymentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('paymentStatus', isEqualTo: 'failed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyCard(message: 'No failed payments');
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final restaurant = data['restaurantName'] as String? ?? 'Unknown';
            final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
            final method = data['paymentMethodType'] as String? ?? 'unknown';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payment_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                        const SizedBox(height: 2),
                        Text('\$${amount.toStringAsFixed(2)} • $method', style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
                      ],
                    ),
                  ),
                  Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Empty Card ──────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Center(
        child: Text(message, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
      ),
    );
  }
}
