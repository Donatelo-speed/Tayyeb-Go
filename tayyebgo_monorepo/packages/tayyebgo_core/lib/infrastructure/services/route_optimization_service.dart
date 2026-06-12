import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/value_objects/geo_location.dart';

class OptimizedRoute {
  final List<RouteStop> stops;
  final double totalDistanceKm;
  final int totalEtaMinutes;
  final double fuelEstimate;

  const OptimizedRoute({
    required this.stops,
    required this.totalDistanceKm,
    required this.totalEtaMinutes,
    required this.fuelEstimate,
  });
}

class RouteStop {
  final String orderId;
  final String address;
  final GeoLocation location;
  final int sequenceNumber;
  final int etaFromPrevious;
  final String type;

  const RouteStop({
    required this.orderId,
    required this.address,
    required this.location,
    required this.sequenceNumber,
    required this.etaFromPrevious,
    required this.type,
  });
}

class RouteOptimizationService {
  final String? _googleApiKey;

  RouteOptimizationService({String? googleApiKey}) : _googleApiKey = googleApiKey;

  /// Optimize a multi-stop delivery route for a driver.
  Future<OptimizedRoute> optimizeRoute({
    required GeoLocation driverLocation,
    required List<Map<String, dynamic>> orders,
  }) async {
    if (orders.isEmpty) {
      return const OptimizedRoute(
        stops: [],
        totalDistanceKm: 0,
        totalEtaMinutes: 0,
        fuelEstimate: 0,
      );
    }

    final stops = orders.map((order) {
      final addr = order['deliveryAddress'] as Map<String, dynamic>?;
      final lat = (addr?['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (addr?['longitude'] as num?)?.toDouble() ?? 0.0;
      return _RawStop(
        orderId: order['id'] as String? ?? '',
        address: addr?['fullAddress'] as String? ?? '',
        location: GeoLocation(lat, lng),
        type: order['status'] as String? ?? 'pending',
      );
    }).toList();

    final optimized = _nearestNeighborOptimize(driverLocation, stops);

    if (_googleApiKey != null) {
      return await _enhanceWithGoogleDirections(driverLocation, optimized);
    }

    return _buildRouteFromDistances(driverLocation, optimized);
  }

  /// Nearest-neighbor heuristic for route optimization.
  List<_RawStop> _nearestNeighborOptimize(GeoLocation start, List<_RawStop> stops) {
    if (stops.length <= 1) return stops;

    final remaining = List<_RawStop>.from(stops);
    final optimized = <_RawStop>[];
    GeoLocation current = start;

    while (remaining.isNotEmpty) {
      int nearestIdx = 0;
      double nearestDist = double.infinity;
      for (int i = 0; i < remaining.length; i++) {
        final dist = current.distanceTo(remaining[i].location);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearestIdx = i;
        }
      }
      final nearest = remaining.removeAt(nearestIdx);
      optimized.add(nearest);
      current = nearest.location;
    }

    return optimized;
  }

  /// Enhance route with Google Directions API for real road distances.
  Future<OptimizedRoute> _enhanceWithGoogleDirections(
    GeoLocation driverLocation,
    List<_RawStop> stops,
  ) async {
    try {
      final waypoints = stops.map((s) => '${s.location.latitude},${s.location.longitude}').join('|');
      final origin = '${driverLocation.latitude},${driverLocation.longitude}';
      final destination = '${stops.last.location.latitude},${stops.last.location.longitude}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin&destination=$destination'
        '&waypoints=optimize:true|$waypoints'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return _buildRouteFromDistances(driverLocation, stops);
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        return _buildRouteFromDistances(driverLocation, stops);
      }

      final route = data['routes'][0];
      final leg = route['legs'] as List;
      final totalDistance = leg.fold<double>(0, (sum, l) => sum + ((l['distance']?['value'] ?? 0) as num).toDouble() / 1000);
      final totalTime = leg.fold<int>(0, (sum, l) => sum + ((l['duration']?['value'] ?? 0) as num).toInt() ~/ 60);

      final orderIdx = route['waypoint_order'] as List?;
      final reordered = orderIdx != null
          ? orderIdx.map((i) => stops[i as int]).toList()
          : stops;

      final routeStops = <RouteStop>[];
      for (int i = 0; i < reordered.length; i++) {
        final legEta = i < leg.length ? ((leg[i]['duration']?['value'] ?? 0) as num).toInt() ~/ 60 : 5;
        routeStops.add(RouteStop(
          orderId: reordered[i].orderId,
          address: reordered[i].address,
          location: reordered[i].location,
          sequenceNumber: i + 1,
          etaFromPrevious: legEta,
          type: reordered[i].type,
        ));
      }

      return OptimizedRoute(
        stops: routeStops,
        totalDistanceKm: totalDistance,
        totalEtaMinutes: totalTime,
        fuelEstimate: totalDistance * 0.15,
      );
    } catch (e) {
      return _buildRouteFromDistances(driverLocation, stops);
    }
  }

  /// Build route using straight-line distance estimation (no API).
  OptimizedRoute _buildRouteFromDistances(GeoLocation start, List<_RawStop> stops) {
    double totalDist = 0;
    int totalTime = 0;
    GeoLocation current = start;
    final routeStops = <RouteStop>[];

    for (int i = 0; i < stops.length; i++) {
      final dist = current.distanceTo(stops[i].location);
      final roadDist = dist * 1.3;
      final roadDistKm = roadDist / 1000;
      final timeMin = (roadDist / 250).ceil();

      totalDist += roadDistKm;
      totalTime += timeMin;

      routeStops.add(RouteStop(
        orderId: stops[i].orderId,
        address: stops[i].address,
        location: stops[i].location,
        sequenceNumber: i + 1,
        etaFromPrevious: timeMin,
        type: stops[i].type,
      ));

      current = stops[i].location;
    }

    return OptimizedRoute(
      stops: routeStops,
      totalDistanceKm: totalDist,
      totalEtaMinutes: totalTime,
      fuelEstimate: totalDist * 0.15,
    );
  }
}

class _RawStop {
  final String orderId;
  final String address;
  final GeoLocation location;
  final String type;

  const _RawStop({
    required this.orderId,
    required this.address,
    required this.location,
    required this.type,
  });
}
