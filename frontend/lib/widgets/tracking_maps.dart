import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config.dart';
import '../theme/omni_theme.dart';

class AdminLiveMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> orders;
  final bool isDark;

  const AdminLiveMapWidget({
    super.key,
    required this.drivers,
    required this.orders,
    this.isDark = true,
  });

  @override
  State<AdminLiveMapWidget> createState() => _AdminLiveMapWidgetState();
}

class _AdminLiveMapWidgetState extends State<AdminLiveMapWidget> {
  GoogleMapController? _controller;
  Map<String, dynamic>? _selectedDriver;

  @override
  Widget build(BuildContext context) {
    if (Config.googleMapsApiKey.isEmpty) {
      return _buildPlaceholder();
    }
    return _buildGoogleMap();
  }

  Widget _buildPlaceholder() {
    final isDark = widget.isDark;
    final activeDrivers = widget.drivers.where((d) => d['status'] == 'active').toList();
    
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Driver Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              PulseBadge(label: '${activeDrivers.length} Active', color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('${activeDrivers.length} drivers active', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('Add Google Maps API Key', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeDrivers.length,
              itemBuilder: (context, index) {
                final driver = activeDrivers[index];
                final order = widget.orders.where((o) => o['assigned_driver_id'] == driver['id'] && o['status'] == 'shipped').firstOrNull;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDriver = driver),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedDriver == driver ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedDriver == driver ? Theme.of(context).colorScheme.primary : Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping, size: 16, color: Colors.green),
                            const Spacer(),
                            if (order != null) Icon(Icons.navigation, size: 12, color: Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(driver['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (order != null)
                          Text('→ ${order['shipping_address'] ?? 'Destination'}', style: TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    final isDark = widget.isDark;
    final darkMapStyle = '''[{"elementType": "geometry", "stylers": [{"color": "#212121"}]}]''';

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Driver Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              PulseBadge(label: '${widget.drivers.where((d) => d['status'] == 'active').length} Active', color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(40.7128, -74.0060), zoom: 12),
                onMapCreated: (controller) {
                  _controller = controller;
                  if (isDark) controller.setMapStyle(darkMapStyle);
                },
                markers: _buildMarkers(),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    for (final driver in widget.drivers) {
      final location = driver['current_location'];
      if (location == null) continue;
      
      final lat = location['lat'] as double?;
      final lng = location['lng'] as double?;
      if (lat == null || lng == null) continue;

      final order = widget.orders.where((o) => o['assigned_driver_id'] == driver['id'] && o['status'] == 'shipped').firstOrNull;
      
      markers.add(Marker(
        markerId: MarkerId(driver['id'].toString()),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: driver['name'],
          snippet: order != null ? 'En route to: ${order['shipping_address']}' : 'Available',
        ),
      ));

      if (order != null && order['current_location'] != null) {
        final destLat = order['current_location']['lat'] as double?;
        final destLng = order['current_location']['lng'] as double?;
        if (destLat != null && destLng != null) {
          markers.add(Marker(
            markerId: MarkerId('dest_${driver['id']}'),
            position: LatLng(destLat, destLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: 'Delivery Address'),
          ));
        }
      }
    }
    
    return markers;
  }
}

class DeliveryMapWidget extends StatefulWidget {
  final Map<String, dynamic>? currentOrder;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final double? customerLat;
  final double? customerLng;
  final bool isDark;

  const DeliveryMapWidget({
    super.key,
    this.currentOrder,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    this.customerLat,
    this.customerLng,
    this.isDark = true,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    if (Config.googleMapsApiKey.isEmpty) {
      return _buildPlaceholder();
    }
    return _buildGoogleMap();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(widget.customerName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.shippingAddress, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              color: const Color(0xFF252542),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(widget.customerPhone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.shippingAddress, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    final isDark = widget.isDark;
    final target = widget.customerLat != null && widget.customerLng != null
        ? LatLng(widget.customerLat!, widget.customerLng!)
        : const LatLng(40.7128, -74.0060);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 15),
          onMapCreated: (controller) {
            _controller = controller;
            if (isDark) controller.setMapStyle('''[{"elementType": "geometry", "stylers": [{"color": "#212121"}]}]''');
          },
          markers: {
            Marker(
              markerId: const MarkerId('customer'),
              position: target,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(title: 'Delivery Address'),
            ),
          },
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            color: isDark ? const Color(0xFF252542) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(widget.customerPhone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.shippingAddress, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(icon: const Icon(Icons.phone), label: const Text('Call'), onPressed: () {}),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(icon: const Icon(Icons.navigation), label: const Text('Navigate'), onPressed: () {}),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomerOrderTrackingWidget extends StatefulWidget {
  final Map<String, dynamic>? order;
  final String? driverName;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;
  final String? estimatedTime;
  final String? status;
  final bool isDark;

  const CustomerOrderTrackingWidget({
    super.key,
    this.order,
    this.driverName,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
    this.estimatedTime,
    this.status,
    this.isDark = false,
  });

  @override
  State<CustomerOrderTrackingWidget> createState() => _CustomerOrderTrackingWidgetState();
}

class _CustomerOrderTrackingWidgetState extends State<CustomerOrderTrackingWidget> {
  GoogleMapController? _controller;

  String get _statusText {
    switch (widget.status) {
      case 'processing': return 'Preparing your order';
      case 'picked_up': return 'Driver picked up your order';
      case 'shipped': return 'On the way';
      case 'out_for_delivery': return 'Almost there!';
      case 'delivered': return 'Delivered';
      default: return 'Order placed';
    }
  }

  int get _statusStep {
    switch (widget.status) {
      case 'processing': return 0;
      case 'picked_up': return 1;
      case 'shipped': return 2;
      case 'out_for_delivery': return 3;
      case 'delivered': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Config.googleMapsApiKey.isEmpty || widget.driverLat == null) {
      return _buildPlaceholder();
    }
    return _buildGoogleMap();
  }

  Widget _buildPlaceholder() {
    final isDark = widget.isDark;
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Track Your Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              if (widget.estimatedTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(widget.estimatedTime!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (i) {
              final isCompleted = i <= _statusStep;
              final isCurrent = i == _statusStep;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        border: isCurrent ? Border.all(color: Colors.green, width: 2) : null,
                      ),
                      child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    if (i < 4) Expanded(
                      child: Container(height: 2, color: isCompleted && i < _statusStep ? Colors.green : Colors.grey[300]),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('Shipped', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('Delivered', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_statusText, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (widget.driverName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: Colors.green, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.driverName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Your delivery driver', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (widget.driverPhone != null)
                  IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              color: isDark ? Colors.black : Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Driver location', style: TextStyle(color: Colors.grey[600])),
                    Text('Add Google Maps API Key for live tracking', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    final isDark = widget.isDark;
    final driverLocation = widget.driverLat != null && widget.driverLng != null
        ? LatLng(widget.driverLat!, widget.driverLng!)
        : const LatLng(40.7128, -74.0060);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: driverLocation, zoom: 14),
              onMapCreated: (controller) {
                _controller = controller;
                if (isDark) controller.setMapStyle('''[{"elementType": "geometry", "stylers": [{"color": "#212121"}]}]''');
              },
              markers: {
                if (widget.driverLat != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: driverLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(title: widget.driverName ?? 'Driver'),
                  ),
              },
              myLocationButtonEnabled: true,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(5, (i) {
            final isCompleted = i <= _statusStep;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.green : Colors.grey[300],
                    ),
                    child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  if (i < 4) Container(height: 2, color: isCompleted && i < _statusStep ? Colors.green : Colors.grey[300]),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Placed', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Shipped', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Done', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.driverName != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: Colors.green, child: const Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.driverName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_statusText, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (widget.estimatedTime != null)
                          Text('ETA: ${widget.estimatedTime}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (widget.driverPhone != null)
                    IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
                ],
              ),
            ),
          ),
      ],
    );
  }
}