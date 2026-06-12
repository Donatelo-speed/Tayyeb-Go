import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});
  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Delivery History', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(child: Text('Not signed in', style: GoogleFonts.inter(color: context.textMutedColor))),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Delivery History', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dispatch_requests')
                  .where('driverId', isEqualTo: user.id)
                  .where('status', isEqualTo: 'delivered')
                  .orderBy('completedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: context.successColor));
                }
                if (snapshot.hasError) {
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
                          child: Icon(Icons.error_outline_rounded, size: 36, color: context.errorColor),
                        ),
                        const SizedBox(height: 16),
                        Text('Something went wrong', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Pull down to retry', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final completedAt = data['completedAt'];
                  if (completedAt == null) return false;
                  DateTime date;
                  if (completedAt is Timestamp) {
                    date = completedAt.toDate();
                  } else if (completedAt is String) {
                    date = DateTime.tryParse(completedAt) ?? DateTime(2000);
                  } else {
                    return false;
                  }
                  final now = DateTime.now();
                  if (_selectedFilter == 1) {
                    return date.year == now.year && date.month == now.month && date.day == now.day;
                  } else if (_selectedFilter == 2) {
                    final weekAgo = now.subtract(const Duration(days: 7));
                    return date.isAfter(weekAgo);
                  } else if (_selectedFilter == 3) {
                    return date.year == now.year && date.month == now.month;
                  }
                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: context.successColor,
                  backgroundColor: context.surfaceColor,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _DeliveryCard(data: data);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Today', 'This Week', 'This Month'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? context.successColor.withValues(alpha: 0.15) : context.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? context.successColor.withValues(alpha: 0.3) : context.borderColor,
                  ),
                ),
                child: Text(
                  filters[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? context.successColor : context.textMutedColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(Icons.history_rounded, size: 36, color: context.textMutedColor),
          ),
          const SizedBox(height: 16),
          Text('No deliveries yet', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Completed deliveries will appear here', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DeliveryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final restaurantName = data['restaurantName'] as String? ?? 'Restaurant';
    final customerAddress = data['customerAddress'] as String? ?? data['dropoffAddress'] as String? ?? 'Address not available';
    final deliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final completedAt = data['completedAt'];
    final rating = (data['rating'] as num?)?.toDouble();
    final pickupLat = (data['pickupLat'] as num?)?.toDouble();
    final pickupLon = (data['pickupLon'] as num?)?.toDouble();
    final dropoffLat = (data['dropoffLat'] as num?)?.toDouble();
    final dropoffLon = (data['dropoffLon'] as num?)?.toDouble();

    DateTime? date;
    if (completedAt is Timestamp) {
      date = completedAt.toDate();
    } else if (completedAt is String) {
      date = DateTime.tryParse(completedAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pickupLat != null && pickupLon != null && dropoffLat != null && dropoffLon != null)
            _buildMapPreview(context, pickupLat, pickupLon, dropoffLat, dropoffLon),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.check_circle_rounded, color: context.successColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(restaurantName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
                    ),
                    if (rating != null) _buildRatingBadge(context, rating),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: context.textMutedColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(customerAddress, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: context.borderColor)),
                Row(
                  children: [
                    Text(
                      'SYP ${deliveryFee.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.successColor),
                    ),
                    const Spacer(),
                    if (date != null)
                      Text(
                        _formatDate(date),
                        style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context, double pickupLat, double pickupLon, double dropoffLat, double dropoffLon) {
    final pickup = LatLng(pickupLat, pickupLon);
    final dropoff = LatLng(dropoffLat, dropoffLon);
    final center = LatLng(
      (pickup.latitude + dropoff.latitude) / 2,
      (pickup.longitude + dropoff.longitude) / 2,
    );

    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: context.surfaceAltColor,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tayyebgo.driver',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pickup,
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                    ),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 14),
                  ),
                ),
                Marker(
                  point: dropoff,
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.warningColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                    ),
                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [pickup, dropoff],
                  color: context.successColor.withValues(alpha: 0.6),
                  strokeWidth: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context, double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: context.warningColor),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: context.warningColor)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
