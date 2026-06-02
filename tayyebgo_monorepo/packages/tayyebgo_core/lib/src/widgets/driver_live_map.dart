import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../infrastructure/services/driver_location_service.dart';
import '../theme/tayyebgo_theme.dart';

class DriverLiveMap extends StatefulWidget {
  final double height;
  final bool showDriverMarkers;
  final bool showRestaurantMarkers;
  final bool showOrderMarkers;
  final String? restaurantId;
  final String? driverId;
  final Map<String, dynamic>? highlightOrder;

  const DriverLiveMap({
    super.key,
    this.height = 300,
    this.showDriverMarkers = true,
    this.showRestaurantMarkers = false,
    this.showOrderMarkers = false,
    this.restaurantId,
    this.driverId,
    this.highlightOrder,
  });

  @override
  State<DriverLiveMap> createState() => _DriverLiveMapState();
}

class _DriverLiveMapState extends State<DriverLiveMap> {
  final DriverLocationService _locationService = DriverLocationService();

  @override
  void initState() {
    super.initState();
    if (widget.driverId != null) {
      _locationService.start(widget.driverId!);
    }
  }

  @override
  void dispose() {
    _locationService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('driver_locations').limit(500).snapshots(),
      builder: (context, driverSnap) {
        final drivers = driverSnap.hasData ? driverSnap.data!.docs : <QueryDocumentSnapshot>[];
        return StreamBuilder<QuerySnapshot>(
          stream: widget.showRestaurantMarkers
              ? FirebaseFirestore.instance.collection('Restaurants').limit(500).snapshots()
              : null,
          builder: (context, restaurantSnap) {
            final restaurants = restaurantSnap.hasData ? restaurantSnap.data!.docs : <QueryDocumentSnapshot>[];
            return StreamBuilder<QuerySnapshot>(
              stream: widget.showOrderMarkers
                  ? FirebaseFirestore.instance.collection('Orders').where('status', whereIn: [
                      'ready', 'ready_for_driver', 'dispatched', 'picked_up',
                    ]).limit(500).snapshots()
                  : null,
              builder: (context, orderSnap) {
                final orders = orderSnap.hasData ? orderSnap.data!.docs : <QueryDocumentSnapshot>[];
                return _buildMap(drivers, restaurants, orders);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMap(
    List<QueryDocumentSnapshot> drivers,
    List<QueryDocumentSnapshot> restaurants,
    List<QueryDocumentSnapshot> orders,
  ) {
    final markers = <Marker>[];
    final polylines = <Polyline>[];
    LatLng? centerLatLng;

    if (drivers.isEmpty && restaurants.isEmpty && orders.isEmpty && widget.highlightOrder == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: TayyebGoTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TayyebGoTheme.dividerColor),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 40, color: TayyebGoTheme.textMuted),
              const SizedBox(height: 8),
              Text('No activity on the map', style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    for (final doc in drivers) {
      final d = doc.data() as Map<String, dynamic>;
      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final name = d['name'] as String? ?? d['displayName'] as String? ?? 'Driver';
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 120,
            height: 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                  ),
                  child: Text(name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                Icon(Icons.delivery_dining, color: TayyebGoTheme.primaryColor, size: 28),
              ],
            ),
          ),
        );
        if (centerLatLng == null) centerLatLng = LatLng(lat, lng);
      }
    }

    for (final doc in restaurants) {
      final r = doc.data() as Map<String, dynamic>;
      if (widget.restaurantId != null && doc.id != widget.restaurantId) continue;
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: const Icon(Icons.store, color: Colors.orange, size: 32),
          ),
        );
        if (centerLatLng == null) centerLatLng = LatLng(lat, lng);
      }
    }

    for (final doc in orders) {
      final o = doc.data() as Map<String, dynamic>;
      final pickupLat = (o['pickupLatitude'] as num?)?.toDouble();
      final pickupLng = (o['pickupLongitude'] as num?)?.toDouble();
      final dropLat = (o['dropoffLatitude'] as num?)?.toDouble();
      final dropLng = (o['dropoffLongitude'] as num?)?.toDouble();
      if (pickupLat != null && pickupLng != null) {
        markers.add(
          Marker(
            point: LatLng(pickupLat, pickupLng),
            width: 32, height: 32,
            child: const Icon(Icons.storefront, color: Colors.amber, size: 28),
          ),
        );
        if (centerLatLng == null) centerLatLng = LatLng(pickupLat, pickupLng);
      }
      if (dropLat != null && dropLng != null) {
        markers.add(
          Marker(
            point: LatLng(dropLat, dropLng),
            width: 32, height: 32,
            child: const Icon(Icons.location_on, color: Colors.red, size: 28),
          ),
        );
        if (centerLatLng == null) centerLatLng = LatLng(dropLat, dropLng);
      }
      if (pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
        polylines.add(
          Polyline(
            points: [LatLng(pickupLat, pickupLng), LatLng(dropLat, dropLng)],
            color: Colors.amber.withValues(alpha: 0.6),
            strokeWidth: 2,
          ),
        );
      }
    }

    if (widget.highlightOrder != null) {
      final order = widget.highlightOrder!;
      final pickupLat = (order['pickupLatitude'] as num?)?.toDouble();
      final pickupLng = (order['pickupLongitude'] as num?)?.toDouble();
      if (pickupLat != null && pickupLng != null) {
        centerLatLng = LatLng(pickupLat, pickupLng);
        markers.add(
          Marker(
            point: LatLng(pickupLat, pickupLng),
            width: 40, height: 40,
            child: const Icon(Icons.store, color: Colors.orange, size: 32),
          ),
        );
        final dropLat = (order['dropoffLatitude'] as num?)?.toDouble();
        final dropLng = (order['dropoffLongitude'] as num?)?.toDouble();
        if (dropLat != null && dropLng != null) {
          markers.add(
            Marker(
              point: LatLng(dropLat, dropLng),
              width: 40, height: 40,
              child: const Icon(Icons.location_on, color: Colors.red, size: 32),
            ),
          );
          polylines.add(
            Polyline(
              points: [LatLng(pickupLat, pickupLng), LatLng(dropLat, dropLng)],
              color: Colors.amber,
              strokeWidth: 3,
            ),
          );
        }
      }
    }

    if (centerLatLng == null) centerLatLng = const LatLng(25.2048, 55.2708);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TayyebGoTheme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: centerLatLng,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.tayyebgo.admin',
          ),
          PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
