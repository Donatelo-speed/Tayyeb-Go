import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderHeatmapPoint {
  final double latitude;
  final double longitude;
  final int orderCount;
  final double avgRevenue;

  const OrderHeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.orderCount,
    this.avgRevenue = 0,
  });
}

class OrderHeatmap extends StatefulWidget {
  final DateTimeRange? dateRange;
  final String? restaurantId;
  final double initialZoom;
  final LatLng? initialCenter;

  const OrderHeatmap({
    super.key,
    this.dateRange,
    this.restaurantId,
    this.initialZoom = 12,
    this.initialCenter,
  });

  @override
  State<OrderHeatmap> createState() => _OrderHeatmapState();
}

class _OrderHeatmapState extends State<OrderHeatmap> {
  List<OrderHeatmapPoint> _points = [];
  bool _isLoading = true;
  int _maxOrders = 1;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  @override
  void didUpdateWidget(OrderHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange ||
        oldWidget.restaurantId != widget.restaurantId) {
      _loadHeatmapData();
    }
  }

  Future<void> _loadHeatmapData() async {
    setState(() => _isLoading = true);
    try {
      Query query = FirebaseFirestore.instance.collection('orders');

      if (widget.restaurantId != null) {
        query = query.where('restaurantId', isEqualTo: widget.restaurantId);
      }

      if (widget.dateRange != null) {
        query = query.where('createdAt',
            isGreaterThan: Timestamp.fromDate(widget.dateRange!.start));
        query = query.where('createdAt',
            isLessThan: Timestamp.fromDate(widget.dateRange!.end));
      }

      final snap = await query.limit(1000).get();

      final pointMap = <String, _HeatmapAccumulator>{};
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final addr = data['deliveryAddress'] as Map<String, dynamic>?;
        final lat = addr?['latitude'] as num? ??
            (data['latitude'] as num?);
        final lng = addr?['longitude'] as num? ??
            (data['longitude'] as num?);
        if (lat == null || lng == null) continue;

        final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
        if (!pointMap.containsKey(key)) {
          pointMap[key] = _HeatmapAccumulator(lat.toDouble(), lng.toDouble());
        }
        final acc = pointMap[key]!;
        acc.count++;
        acc.totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      final points = pointMap.values.map((acc) => OrderHeatmapPoint(
        latitude: acc.lat,
        longitude: acc.lng,
        orderCount: acc.count,
        avgRevenue: acc.count > 0 ? acc.totalRevenue / acc.count : 0,
      )).toList();

      final maxOrders = points.fold<int>(0, (max, p) => p.orderCount > max ? p.orderCount : max);

      setState(() {
        _points = points;
        _maxOrders = maxOrders > 0 ? maxOrders : 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_points.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No order data for this period', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final center = widget.initialCenter ??
        LatLng(
          _points.map((p) => p.latitude).reduce((a, b) => a + b) / _points.length,
          _points.map((p) => p.longitude).reduce((a, b) => a + b) / _points.length,
        );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: widget.initialZoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tayyebgo.app',
        ),
        CircleLayer(
          circles: _points.map((point) {
            final intensity = point.orderCount / _maxOrders;
            return CircleMarker(
              point: LatLng(point.latitude, point.longitude),
              radius: 200 + (intensity * 800),
              color: _heatColor(intensity).withValues(alpha: 0.5),
              borderColor: _heatColor(intensity),
              borderStrokeWidth: 1,
            );
          }).toList(),
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  Color _heatColor(double intensity) {
    if (intensity > 0.75) return const Color(0xFFEF4444);
    if (intensity > 0.5) return const Color(0xFFF97316);
    if (intensity > 0.25) return const Color(0xFFFBBF24);
    return const Color(0xFF34D399);
  }
}

class _HeatmapAccumulator {
  final double lat;
  final double lng;
  int count = 0;
  double totalRevenue = 0;
  _HeatmapAccumulator(this.lat, this.lng);
}
