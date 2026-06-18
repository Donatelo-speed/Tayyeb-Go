import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverHeatMapScreen extends StatefulWidget {
  const DriverHeatMapScreen({super.key});

  @override
  State<DriverHeatMapScreen> createState() => _DriverHeatMapScreenState();
}

class _DriverHeatMapScreenState extends State<DriverHeatMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(34.7369, 36.7131); // Homs default
  bool _loading = true;
  List<_DemandPoint> _demandPoints = [];
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadDemandData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _center = LatLng(pos.latitude, pos.longitude));
        }
      }
    } catch (_) {}
  }

  Future<void> _loadDemandData() async {
    try {
      final now = DateTime.now();
      DateTime since;
      switch (_selectedPeriod) {
        case 'Today':
          since = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          since = now.subtract(const Duration(days: 7));
          break;
        case 'This Month':
          since = DateTime(now.year, now.month, 1);
          break;
        default:
          since = now.subtract(const Duration(hours: 6));
      }

      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
          .where('status', whereIn: ['placed', 'accepted', 'preparing', 'ready'])
          .get();

      final Map<String, int> locationCounts = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final lat = (data['deliveryLatitude'] as num?)?.toDouble();
        final lng = (data['deliveryLongitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
          locationCounts[key] = (locationCounts[key] ?? 0) + 1;
          _demandPoints.add(_DemandPoint(LatLng(lat, lng), locationCounts[key]!));
        }
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getDemandColor(int count) {
    if (count >= 5) return const Color(0xFFEF4444);
    if (count >= 3) return const Color(0xFFF97316);
    if (count >= 2) return const Color(0xFFFBBF24);
    return const Color(0xFF22C55E);
  }

  double _getDemandRadius(int count) {
    if (count >= 5) return 120;
    if (count >= 3) return 90;
    if (count >= 2) return 70;
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AnimatedPressScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded, color: context.textPrimaryColor, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Demand Zones', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor, letterSpacing: 0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['Live', 'Today', 'This Week', 'This Month'].map((p) {
                  final sel = _selectedPeriod == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedPressScale(
                      onTap: () {
                        setState(() { _selectedPeriod = p; _loading = true; _demandPoints.clear(); });
                        _loadDemandData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.driverAccent : context.surfaceColor,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(color: sel ? AppColors.driverAccent : context.borderColor.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(p, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: sel ? Colors.white : context.textMutedColor)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.driverAccent))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(initialCenter: _center, initialZoom: 13),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.tayyebgo.driver',
                            ),
                            CircleLayer(
                              circles: _demandPoints.map((p) => CircleMarker(
                                point: p.location,
                                radius: _getDemandRadius(p.count),
                                color: _getDemandColor(p.count).withValues(alpha: 0.3),
                                borderColor: _getDemandColor(p.count),
                                borderStrokeWidth: 2,
                              )).toList(),
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _center,
                                  width: 16, height: 16,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: context.surfaceColor.withValues(alpha: 0.95), borderRadius: AppRadius.brMd, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text('Demand', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor)),
                              const SizedBox(height: 8),
                              _legendItem(context, 'High', const Color(0xFFEF4444)),
                              const SizedBox(height: 3),
                              _legendItem(context, 'Medium', const Color(0xFFF97316)),
                              const SizedBox(height: 3),
                              _legendItem(context, 'Low', const Color(0xFF22C55E)),
                            ]),
                          ),
                        ),
                        Positioned(
                          bottom: 12, left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: context.surfaceColor.withValues(alpha: 0.95), borderRadius: AppRadius.brMd),
                            child: Text('${_demandPoints.length} active zone${_demandPoints.length == 1 ? '' : 's'}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.driverAccent)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: AppRadius.brSm)),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
    ]);
  }
}

class _DemandPoint {
  final LatLng location;
  final int count;
  _DemandPoint(this.location, this.count);
}
