import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverLiveMapScreen extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final double restaurantLat;
  final double restaurantLng;
  final String customerAddress;
  final double customerLat;
  final double customerLng;
  final double deliveryFee;
  final String? dispatchId;
  final String? currentStatus;

  const DriverLiveMapScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.customerAddress,
    required this.customerLat,
    required this.customerLng,
    required this.deliveryFee,
    this.dispatchId,
    this.currentStatus,
  });

  @override
  State<DriverLiveMapScreen> createState() => _DriverLiveMapScreenState();
}

class _DriverLiveMapScreenState extends State<DriverLiveMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  bool _hasLocated = false;

  static const double _pickupThreshold = 150; // meters
  static const double _deliveryThreshold = 150; // meters

  LatLng get _pickup => LatLng(widget.restaurantLat, widget.restaurantLng);
  LatLng get _delivery => LatLng(widget.customerLat, widget.customerLng);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      if (!_hasLocated) {
        _hasLocated = true;
        _fitBounds();
      }
    });

    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() => _currentPosition = pos);
    if (!_hasLocated) {
      _hasLocated = true;
      _fitBounds();
    }
  }

  void _fitBounds() {
    final points = <LatLng>[_pickup, _delivery];
    if (_currentPosition != null) {
      points.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    final latPadding = (bounds.north - bounds.south) * 0.25;
    final lngPadding = (bounds.east - bounds.west) * 0.25;
    final padded = LatLngBounds(
      LatLng(bounds.south - latPadding, bounds.west - lngPadding),
      LatLng(bounds.north + latPadding, bounds.east + lngPadding),
    );
    _mapController.fitCamera(CameraFit.bounds(bounds: padded));
  }

  void _recenter() {
    if (_currentPosition == null) return;
    final driverPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final points = [driverPos, _pickup, _delivery];
    final bounds = LatLngBounds.fromPoints(points);
    final latPadding = (bounds.north - bounds.south) * 0.25;
    final lngPadding = (bounds.east - bounds.west) * 0.25;
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(bounds.south - latPadding, bounds.west - lngPadding),
        LatLng(bounds.north + latPadding, bounds.east + lngPadding),
      ),
    ));
  }

  double? _distanceTo(LatLng point) {
    if (_currentPosition == null) return null;
    final driver = GeoLocation(_currentPosition!.latitude, _currentPosition!.longitude);
    final dest = GeoLocation(point.latitude, point.longitude);
    return driver.distanceTo(dest);
  }

  int _estimateEta(LatLng destination) {
    final distanceM = _distanceTo(destination);
    if (distanceM == null) return 0;
    const speedMps = 8.0;
    return (distanceM / (speedMps * 60)).round().clamp(0, 120);
  }

  bool get _isAtPickup {
    final d = _distanceTo(_pickup);
    return d != null && d < _pickupThreshold;
  }

  bool get _isAtDelivery {
    final d = _distanceTo(_delivery);
    return d != null && d < _deliveryThreshold;
  }

  Future<void> _openNavigation(LatLng destination) async {
    final origin = _currentPosition != null
        ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
        : '';
    final dest = '${destination.latitude},${destination.longitude}';
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest',
    );
    if (!mounted) return;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHeadingToPickup = widget.currentStatus == 'accepted' || widget.currentStatus == 'enRoute';
    final isHeadingToDelivery = widget.currentStatus == 'pickedUp';

    final destination = isHeadingToDelivery ? _delivery : _pickup;
    final etaMinutes = _estimateEta(destination);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickup,
              initialZoom: 14,
              onMapReady: () {
                if (_hasLocated) _fitBounds();
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tayyebgo.driver',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_pickup, _delivery],
                    color: context.primaryColor.withValues(alpha: 0.5),
                    strokeWidth: 3,
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // ── Back button ──────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // ── Recenter button ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _CircleButton(
              icon: Icons.my_location_rounded,
              onTap: _recenter,
            ),
          ),

          // ── Bottom info bar ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _InfoBar(
              restaurantName: widget.restaurantName,
              customerAddress: widget.customerAddress,
              etaMinutes: etaMinutes,
              deliveryFee: widget.deliveryFee,
              isHeadingToPickup: isHeadingToPickup,
              isHeadingToDelivery: isHeadingToDelivery,
              isAtPickup: _isAtPickup,
              isAtDelivery: _isAtDelivery,
              onNavigate: () => _openNavigation(destination),
              onArrived: () => Navigator.of(context).pop(
                _ArrivalResult(
                  isPickup: isHeadingToPickup,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      // ── Restaurant pickup (green) ──
      Marker(
        point: _pickup,
        width: 52,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.restaurantName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.store_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),

      // ── Customer delivery (amber) ──
      Marker(
        point: _delivery,
        width: 52,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Customer',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    ];

    // ── Driver location (blue pulsing dot) ──
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }
}

// ── Circle Button ────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: context.textPrimaryColor, size: 22),
      ),
    );
  }
}

// ── Info Bar ────────────────────────────────────────────────────────
class _InfoBar extends StatelessWidget {
  final String restaurantName;
  final String customerAddress;
  final int etaMinutes;
  final double deliveryFee;
  final bool isHeadingToPickup;
  final bool isHeadingToDelivery;
  final bool isAtPickup;
  final bool isAtDelivery;
  final VoidCallback onNavigate;
  final VoidCallback onArrived;

  const _InfoBar({
    required this.restaurantName,
    required this.customerAddress,
    required this.etaMinutes,
    required this.deliveryFee,
    required this.isHeadingToPickup,
    required this.isHeadingToDelivery,
    required this.isAtPickup,
    required this.isAtDelivery,
    required this.onNavigate,
    required this.onArrived,
  });

  @override
  Widget build(BuildContext context) {
    final String arrivedLabel;
    final bool canArrive;
    if (isAtPickup) {
      arrivedLabel = 'Arrived at Pickup';
      canArrive = true;
    } else if (isAtDelivery) {
      arrivedLabel = 'Arrived at Destination';
      canArrive = true;
    } else {
      arrivedLabel = isHeadingToPickup ? 'Arrived at Pickup' : 'Arrived at Destination';
      canArrive = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Route: Restaurant → Customer
              Row(
                children: [
                  // Pickup dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      restaurantName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Dashed line connector
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  width: 2,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: context.borderColor,
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  // Delivery dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      customerAddress,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ETA + Fee row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: context.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'ETA ${_formatEta(etaMinutes)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.delivery_dining_rounded, size: 18, color: context.successColor),
                    const SizedBox(width: 8),
                    Text(
                      'SYP ${deliveryFee.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.successColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Action buttons row
              Row(
                children: [
                  // Navigate button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: Text(
                          'Navigate',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Arrived button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: canArrive ? onArrived : null,
                        icon: Icon(
                          isAtPickup ? Icons.store_rounded : Icons.home_rounded,
                          size: 18,
                        ),
                        label: Text(
                          arrivedLabel,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canArrive
                              ? (isAtPickup ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                              : context.surfaceAltColor,
                          foregroundColor: canArrive ? Colors.white : context.textMutedColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          disabledBackgroundColor: context.surfaceAltColor,
                          disabledForegroundColor: context.textMutedColor,
                        ),
                      ),
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

  String _formatEta(int minutes) {
    if (minutes <= 0) return '< 1 min';
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }
}

// ── Result passed back when driver taps "Arrived" ───────────────────
class _ArrivalResult {
  final bool isPickup;
  const _ArrivalResult({required this.isPickup});
}
