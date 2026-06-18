import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../../../../core/widgets/app_empty_state.dart' as empty;

class LiveMapCard extends StatelessWidget {
  const LiveMapCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public_rounded, size: 20, color: context.primaryColor),
              const SizedBox(width: 10),
              Text('Live Map', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
              const Spacer(),
              LiveMapLegend(),
            ],
          ),
          const SizedBox(height: 4),
          Text('Active stores plotted by location. Click a pin to view details.', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: SizedBox(
              height: 360,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AdminFirestoreService.instance.watchStoresRaw(limit: 200),
                builder: (c, snap) {
                  if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                    return Center(child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor));
                  }
                  final stores = (snap.data ?? const <Map<String, dynamic>>[])
                      .where((s) => s['latitude'] is num && s['longitude'] is num)
                      .toList();
                  if (stores.isEmpty) {
                    return empty.AdminEmptyState(
                      icon: Icons.map_outlined,
                      title: 'No stores on the map',
                      subtitle: 'Stores with a latitude and longitude will appear here.',
                    );
                  }
                  return _MapView(stores: stores);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveMapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 14, children: [
      _legendDot(context, context.successColor, 'Open'),
      _legendDot(context, context.warningColor, 'Busy'),
      _legendDot(context, context.errorColor, 'Closed'),
    ]);
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
    ]);
  }
}

class _MapView extends StatefulWidget {
  final List<Map<String, dynamic>> stores;
  const _MapView({required this.stores});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  late final List<Map<String, dynamic>> _stores = widget.stores;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final lats = _stores.map((s) => (s['latitude'] as num).toDouble()).toList();
    final lngs = _stores.map((s) => (s['longitude'] as num).toDouble()).toList();
    final centerLat = lats.isEmpty ? 33.5138 : lats.reduce((a, b) => a + b) / lats.length;
    final centerLng = lngs.isEmpty ? 36.2765 : lngs.reduce((a, b) => a + b) / lngs.length;
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 11,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tayyebgo.admin',
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _stores.length; i++)
                    Marker(
                      point: LatLng(
                        (_stores[i]['latitude'] as num).toDouble(),
                        (_stores[i]['longitude'] as num).toDouble(),
                      ),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Icon(Icons.location_on, color: _pinColor(context, _stores[i]), size: 32),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_selectedIndex != null && _selectedIndex! < _stores.length)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _MapInfoBubble(
              store: _stores[_selectedIndex!],
              onClose: () => setState(() => _selectedIndex = null),
            ),
          ),
      ],
    );
  }

  Color _pinColor(BuildContext context, Map<String, dynamic> s) {
    final active = s['isActive'] as bool? ?? true;
    if (!active) return context.errorColor;
    final orders = (s['openOrders'] as int?) ?? 0;
    if (orders > 10) return context.warningColor;
    return context.successColor;
  }
}

class _MapInfoBubble extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onClose;
  const _MapInfoBubble({required this.store, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final name = (store['name'] as String?) ?? 'Unnamed store';
    final city = (store['city'] as String?) ?? '—';
    final openOrders = (store['openOrders'] as int?) ?? 0;
    return Material(
      color: context.surfaceColor.withValues(alpha: 0.97),
      borderRadius: AppRadius.brMd,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(Icons.storefront_rounded, color: context.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$city  •  $openOrders open orders', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/dashboard?tab=3'),
              child: Text('Open', style: GoogleFonts.inter(color: context.primaryColor)),
            ),
            IconButton(
              tooltip: 'Close',
              icon: Icon(Icons.close, size: 18, color: context.textMutedColor),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
