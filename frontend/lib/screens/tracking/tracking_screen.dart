import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/tayyebgo_theme.dart';
import 'chat_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, this.orderId = ''});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  double _driverLat = 24.7136;
  double _driverLng = 46.6753;
  double _destLat = 24.7500;
  double _destLng = 46.7000;
  int _etaMinutes = 15;
  String _status = 'pending';
  String _driverName = 'Driver';
  StreamSubscription? _orderSub;

  @override
  void initState() {
    super.initState();
    _streamOrder();
  }

  void _streamOrder() {
    final orderId = widget.orderId.isNotEmpty ? widget.orderId : 'demo-order';
    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final d = doc.data()!;
      setState(() {
        _driverLat = (d['driverLat'] as num?)?.toDouble() ?? _driverLat;
        _driverLng = (d['driverLng'] as num?)?.toDouble() ?? _driverLng;
        _status = d['status'] as String? ?? _status;
        _driverName = d['driverName'] as String? ?? _driverName;
        final addr = d['deliveryAddress'] as Map<String, dynamic>? ?? {};
        _destLat = (addr['latitude'] as num?)?.toDouble() ?? _destLat;
        _destLng = (addr['longitude'] as num?)?.toDouble() ?? _destLng;
        _etaMinutes = _calcEta(_driverLat, _driverLng, _destLat, _destLng);
      });
    }, onError: (_) {});
  }

  int _calcEta(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final km = R * c;
    return (km / 0.5).round().clamp(1, 120);
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _status == 'delivered'
        ? 1.0
        : _status == 'picked_up' || _status == 'en_route'
            ? 0.8
            : _status == 'ready_for_driver'
                ? 0.6
                : _status == 'preparing'
                    ? 0.4
                    : 0.2;

    final driverPos = LatLng(_driverLat, _driverLng);
    final destPos = LatLng(_destLat, _destLng);
    final center = LatLng(
      (_driverLat + _destLat) / 2,
      (_driverLng + _destLng) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  orderId: widget.orderId.isNotEmpty ? widget.orderId : 'demo-order',
                  driverName: _driverName,
                ),
              ),
            ),
            tooltip: 'Chat with Driver',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.tayyebgo.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: driverPos,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.near_me, color: Colors.blue, size: 36),
                            ),
                            Marker(
                              point: destPos,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TayyebGoTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('$_etaMinutes min',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.near_me, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on, color: Colors.red, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Progress',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: _status == 'delivered' ? Colors.green : TayyebGoTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _status == 'delivered' ? Colors.green : TayyebGoTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatusRow(
                    icon: Icons.check_circle,
                    label: 'Order Confirmed',
                    done: _status != 'pending',
                    active: _status == 'accepted' || _status == 'pending',
                  ),
                  _StatusRow(
                    icon: Icons.restaurant,
                    label: 'Preparing',
                    done: _status == 'preparing' || _status == 'ready_for_driver' ||
                          _status == 'picked_up' || _status == 'en_route' || _status == 'delivered',
                    active: _status == 'preparing',
                  ),
                  _StatusRow(
                    icon: Icons.delivery_dining,
                    label: 'Out for Delivery',
                    done: _status == 'picked_up' || _status == 'en_route' || _status == 'delivered',
                    active: _status == 'picked_up' || _status == 'en_route',
                  ),
                  _StatusRow(
                    icon: Icons.check_circle_outline,
                    label: 'Delivered',
                    done: _status == 'delivered',
                    active: _status == 'delivered',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: TayyebGoTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_driverName - Driver',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('ETA: $_etaMinutes min',
                            style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          orderId: widget.orderId.isNotEmpty ? widget.orderId : 'demo-order',
                          driverName: _driverName,
                        ),
                      ),
                    ),
                    child: const Text('Chat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;
  const _StatusRow({required this.icon, required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? Colors.green
        : active
            ? TayyebGoTheme.primaryColor
            : TayyebGoTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
