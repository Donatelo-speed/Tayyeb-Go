import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config.dart';
import '../theme/omni_theme.dart';

class LiveMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> markers;
  final LatLng? initialPosition;
  final bool isDark;
  final Function(Map<String, dynamic>)? onMarkerTap;

  const LiveMapWidget({
    super.key,
    required this.markers,
    this.initialPosition,
    this.isDark = true,
    this.onMarkerTap,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _controller;

  static final LatLng _defaultPosition = const LatLng(40.7128, -74.0060);

  @override
  Widget build(BuildContext context) {
    final apiKey = Config.googleMapsApiKey;
    
    if (apiKey.isEmpty || apiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      return _buildPlaceholder();
    }

    return _buildGoogleMap(apiKey);
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
              const Text('Live Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              PulseBadge(label: '${widget.markers.length} Active', color: Colors.green),
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
                      Icon(Icons.map, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('Add Google Maps API Key', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('in lib/config.dart', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(String apiKey) {
    final isDark = widget.isDark;
    final darkMapStyle = '''[
      {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c2c2c"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
    ]''';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition ?? _defaultPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _controller = controller;
          if (isDark) {
            controller.setMapStyle(darkMapStyle);
          }
        },
        markers: _buildMarkers(),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return widget.markers.map((marker) {
      final location = marker['current_location'];
      if (location == null) return null;
      
      final lat = location['lat'] as double?;
      final lng = location['lng'] as double?;
      if (lat == null || lng == null) return null;

      return Marker(
        markerId: MarkerId(marker['id'].toString()),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          marker['status'] == 'active' 
            ? BitmapDescriptor.hueGreen 
            : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: marker['name'] ?? 'Driver',
          snippet: marker['status'] ?? 'Active',
        ),
        onTap: () => widget.onMarkerTap?.call(marker),
      );
    }).whereType<Marker>().toSet();
  }

  void moveCamera(LatLng position) {
    _controller?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class DeliveryMapScreen extends StatefulWidget {
  final Map<String, dynamic>? order;
  final bool isDark;

  const DeliveryMapScreen({
    super.key,
    this.order,
    this.isDark = true,
  });

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  GoogleMapController? _controller;
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final apiKey = Config.googleMapsApiKey;
    
    if (apiKey.isEmpty || apiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      return _buildPlaceholder();
    }

    return Stack(
      children: [
        _buildGoogleMap(apiKey),
        if (_showDetails) _buildDetailsOverlay(),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Google Maps API Key Required',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add key in lib/config.dart',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(String apiKey) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(40.7128, -74.0060),
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        if (widget.isDark) {
          controller.setMapStyle('''[{"elementType": "geometry", "stylers": [{"color": "#212121"}]}]''');
        }
      },
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildDetailsOverlay() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: GlassEffect(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.order?['customer_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(widget.order?['customer_phone'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showDetails = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.order?['shipping_address'] ?? 'Address',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassEffect extends StatelessWidget {
  final Widget child;
  final double blur;

  const GlassEffect({super.key, required this.child, this.blur = 10});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}