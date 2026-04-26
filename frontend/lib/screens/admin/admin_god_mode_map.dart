import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminGodModeMap extends StatefulWidget {
  const AdminGodModeMap({super.key});

  @override
  State<AdminGodModeMap> createState() => _AdminGodModeMapState();
}

class _AdminGodModeMapState extends State<AdminGodModeMap> {
  GoogleMapController? _mapController;
  
  // Demo drivers with live locations
  final List<Map<String, dynamic>> _drivers = [
    {'id': 1, 'name': 'Ahmed D.', 'lat': 24.7136, 'lng': 46.6753, 'status': 'delivering', 'orders': 3},
    {'id': 2, 'name': 'Sarah M.', 'lat': 24.7200, 'lng': 46.6800, 'status': 'available', 'orders': 0},
    {'id': 3, 'name': 'Mohammed K.', 'lat': 24.7100, 'lng': 46.6700, 'status': 'idle', 'orders': 0},
    {'id': 4, 'name': 'Ali R.', 'lat': 24.7180, 'lng': 46.6850, 'status': 'delivering', 'orders': 2},
    {'id': 5, 'name': 'Omar S.', 'lat': 24.7050, 'lng': 46.6600, 'status': 'stuck', 'orders': 1, 'trafficTime': 15},
  ];

  // Pending deliveries
  final List<Map<String, dynamic>> _pendingDeliveries = [
    {'id': 101, 'lat': 24.7150, 'lng': 46.6720, 'customer': 'Ahmed K.'},
    {'id': 102, 'lat': 24.7220, 'lng': 46.6780, 'customer': 'Sarah M.'},
    {'id': 103, 'lat': 24.7080, 'lng': 46.6650, 'customer': 'Mohammed A.'},
  ];

  Timer? _refreshTimer;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    // Simulate real-time driver movement
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        // Move drivers slightly to simulate movement
        for (var i = 0; i < _drivers.length; i++) {
          if (_drivers[i]['status'] != 'idle') {
            _drivers[i]['lat'] = _drivers[i]['lat'] + (i % 2 == 0 ? 0.001 : -0.001);
            _drivers[i]['lng'] = _drivers[i]['lng'] + (i % 3 == 0 ? 0.001 : -0.001);
          }
        }
        _updateMarkers();
      }
    });
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        // Driver markers
        ..._drivers.map((driver) => Marker(
          markerId: MarkerId('driver_${driver['id']}'),
          position: LatLng(driver['lat'], driver['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getDriverHue(driver['status'])),
          infoWindow: InfoWindow(
            title: driver['name'],
            snippet: _getDriverStatusText(driver),
          ),
          onTap: () => _showDriverDetails(driver),
        )),
        
        // Delivery drop markers
        ..._pendingDeliveries.map((delivery) => Marker(
          markerId: MarkerId('delivery_${delivery['id']}'),
          position: LatLng(delivery['lat'], delivery['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Drop #${delivery['id']}',
            snippet: delivery['customer'],
          ),
        )),
      };
    });
  }

  double _getDriverHue(String status) {
    switch (status) {
      case 'delivering': return BitmapDescriptor.hueGreen;
      case 'available': return BitmapDescriptor.hueAzure;
      case 'idle': return BitmapDescriptor.hueYellow;
      case 'stuck': return BitmapDescriptor.hueRed;
      default: return BitmapDescriptor.hueViolet;
    }
  }

  String _getDriverStatusText(Map<String, dynamic> driver) {
    switch (driver['status']) {
      case 'delivering': return 'Delivering ${driver['orders']} orders';
      case 'available': return 'Available';
      case 'idle': return 'Idle';
      case 'stuck': return 'Stuck in traffic (${driver['trafficTime']}min)';
      default: return 'Unknown';
    }
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(_getDriverHue(driver['status']).toColor()),
                  child: Text(driver['name'][0], style: const TextStyle(color: Colors.white, fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(_getDriverStatusText(driver), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(driver['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    driver['status'].toString().toUpperCase(),
                    style: TextStyle(color: _getStatusColor(driver['status']), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatCard(label: 'Orders Today', value: '${driver['orders']}'),
                const SizedBox(width: 12),
                _StatCard(label: 'Rating', value: '4.8'),
                const SizedBox(width: 12),
                _StatCard(label: 'Distance', value: '2.5km'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
            if (driver['status'] == 'stuck') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Driver stuck in traffic for ${driver['trafficTime']} minutes. Consider reassigning.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivering': return Colors.green;
      case 'available': return Colors.blue;
      case 'idle': return Colors.orange;
      case 'stuck': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('God Mode'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.center_focus_strong), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(24.7136, 46.6753), // Riyadh
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Stats overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildStatsBar(),
          ),

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final availableDrivers = _drivers.where((d) => d['status'] == 'available').length;
    final deliveringDrivers = _drivers.where((d) => d['status'] == 'delivering').length;
    final stuckDrivers = _drivers.where((d) => d['status'] == 'stuck').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LiveStat(label: 'Available', value: '$availableDrivers', color: Colors.blue),
          _LiveStat(label: 'Delivering', value: '$deliveringDrivers', color: Colors.green),
          _LiveStat(label: 'Stuck', value: '$stuckDrivers', color: stuckDrivers > 0 ? Colors.red : Colors.grey),
          _LiveStat(label: 'Pending', value: '${_pendingDeliveries.length}', color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          _LegendItem(color: Colors.green, label: 'Delivering'),
          _LegendItem(color: Colors.blue, label: 'Available'),
          _LegendItem(color: Colors.orange, label: 'Idle'),
          _LegendItem(color: Colors.red, label: 'Stuck'),
          _LegendItem(color: Colors.orange, label: 'Pending Drop'),
        ],
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LiveStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

extension on double {
  Color toColor() {
    return Color.fromARGB(255, ((this * 360) % 360).toInt(), 255, 200);
  }
}