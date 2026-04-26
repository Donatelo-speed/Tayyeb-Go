import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LiveTrackingMap extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> orders;
  final Map<String, dynamic>? selectedDriver;
  final Function(String driverId)? onDriverTap;
  final bool isAdmin;
  final double? currentLat;
  final double? currentLng;

  const LiveTrackingMap({
    super.key,
    required this.drivers,
    required this.orders,
    this.selectedDriver,
    this.onDriverTap,
    this.isAdmin = true,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isLoading = true;
  Position? _当前位置;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _当前位置 = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          child: _buildMapPlaceholder(),
        ),
        ...widget.drivers.map((driver) => _buildDriverMarker(driver)),
        ...widget.orders.map((order) => _buildOrderMarker(order)),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        _buildLegend(),
        if (widget.selectedDriver != null) _buildDriverInfo(widget.selectedDriver!),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return CustomPaint(
      painter: _MapGridPainter(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Live Tracking Map',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.drivers.length} drivers • ${widget.orders.length} active orders',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverMarker(Map<String, dynamic> driver) {
    final lat = driver['lat'] ?? 36.2;
    final lng = driver['lng'] ?? 37.15;
    final isOnline = driver['is_online'] ?? false;
    final hasOrder = driver['current_order_id'] != null;

    Color markerColor;
    IconData markerIcon;

    if (hasOrder) {
      markerColor = Colors.orange;
      markerIcon = Icons.local_shipping;
    } else if (isOnline) {
      markerColor = Colors.green;
      markerIcon = Icons.directions_bike;
    } else {
      markerColor = Colors.grey;
      markerIcon = Icons.pause_circle;
    }

    return Positioned(
      left: _lngToPixels(lng),
      top: _latToPixels(lat),
      child: GestureDetector(
        onTap: () => widget.onDriverTap?.call(driver['id']),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: isOnline ? 1 + (_pulseController.value * 0.1) : 1,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            ),
            child: Icon(
              markerIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderMarker(Map<String, dynamic> order) {
    final lat = order['lat'] ?? 36.2;
    final lng = order['lng'] ?? 37.15;

    return Positioned(
      left: _lngToPixels(lng),
      top: _latToPixels(lat),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.green, 'Available'),
            const SizedBox(height: 4),
            _buildLegendItem(Colors.orange, 'On Delivery'),
            const SizedBox(height: 4),
            _buildLegendItem(Colors.red, 'Pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDriverInfo(Map<String, dynamic> driver) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name'] ?? 'Driver',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(
                            ' ${driver['rating'] ?? 5.0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${driver['total_deliveries'] ?? 0} deliveries',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  driver['vehicle_type'] ?? 'Motorcycle',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _lngToPixels(double lng) {
    const minLng = 36.0;
    const maxLng = 38.0;
    const pixels = 300.0;
    return ((lng - minLng) / (maxLng - minLng) * pixels).clamp(0, pixels);
  }

  double _latToPixels(double lat) {
    const minLat = 35.0;
    const maxLat = 37.0;
    const pixels = 300.0;
    return ((maxLat - lat) / (maxLat - minLat) * pixels).clamp(0, pixels);
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 20.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DriverLocationTracker extends StatefulWidget {
  final String driverId;
  final Function(double lat, double lng)? onLocationUpdate;

  const DriverLocationTracker({
    super.key,
    required this.driverId,
    this.onLocationUpdate,
  });

  @override
  State<DriverLocationTracker> createState() => _DriverLocationTrackerState();
}

class _DriverLocationTrackerState extends State<DriverLocationTracker> {
  Timer? _locationTimer;
  Position? _当前位置;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        _当前位置 = await Geolocator.getCurrentPosition();
        widget.onLocationUpdate?.call(
          _当前位置!.latitude,
          _当前位置!.longitude,
        );
      } catch (e) {
        // Handle error
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class OrderLiveTracking extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> driver;
  final Map<String, dynamic> destination;
  final String status;

  const OrderLiveTracking({
    super.key,
    required this.orderId,
    required this.driver,
    required this.destination,
    required this.status,
  });

  @override
  State<OrderLiveTracking> createState() => _OrderLiveTrackingState();
}

class _OrderLiveTrackingState extends State<OrderLiveTracking> {
  @override
  Widget build(BuildContext context) {
    final progress = _getProgress();

    return Column(
      children: [
        _buildProgressBar(progress),
        const SizedBox(height: 16),
        _buildStatusCard(),
        const SizedBox(height: 16),
        _buildMapCard(),
      ],
    );
  }

  double _getProgress() {
    switch (widget.status) {
      case 'pending':
        return 0.1;
      case 'accepted':
        return 0.3;
      case 'picked_up':
        return 0.5;
      case 'in_transit':
        return 0.7;
      case 'delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Order Progress', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(''),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final steps = [
      {'status': 'pending', 'label': 'Order Placed', 'icon': Icons.shopping_cart},
      {'status': 'accepted', 'label': 'Accepted', 'icon': Icons.check},
      {'status': 'picked_up', 'label': 'Picked Up', 'icon': Icons.inventory},
      {'status': 'in_transit', 'label': 'On the Way', 'icon': Icons.local_shipping},
      {'status': 'delivered', 'label': 'Delivered', 'icon': Icons.home},
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = _getStepIndex(widget.status) >= index;
        final isCurrent = widget.status == step['status'];

        return Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  size: 14,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _getStepIndex(String status) {
    final steps = ['pending', 'accepted', 'picked_up', 'in_transit', 'delivered'];
    return steps.indexOf(status);
  }

  Widget _buildMapCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _RoutePainter(),
            child: const Center(
              child: Icon(Icons.map, size: 48, color: Colors.grey),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.status == 'in_transit' ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    widget.status == 'in_transit'
                        ? 'On the way'
                        : 'Driver assigned',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.driver.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.6,
        size.width * 0.5,
        size.height * 0.4,
        size.width * 0.8,
        size.height * 0.2,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}