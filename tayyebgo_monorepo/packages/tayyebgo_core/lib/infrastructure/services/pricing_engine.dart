import 'dart:math';
import '../../domain/entities/zone.dart';
import '../../domain/value_objects/geo_location.dart';

/// Result of a pricing calculation
class PricingResult {
  final double subtotal;
  final double deliveryFee;
  final double distanceFee;
  final double zoneFee;
  final double nightSurcharge;
  final double tax;
  final double discount;
  final double grandTotal;
  final String? zoneName;
  final int? estimatedMinutes;

  const PricingResult({
    required this.subtotal,
    required this.deliveryFee,
    this.distanceFee = 0,
    this.zoneFee = 0,
    this.nightSurcharge = 0,
    required this.tax,
    this.discount = 0,
    required this.grandTotal,
    this.zoneName,
    this.estimatedMinutes,
  });
}

/// Configurable pricing rules
class PricingRules {
  final double baseDeliveryFee;
  final double perKmFee;
  final double freeDeliveryThreshold;
  final double taxRate;
  final double nightSurchargeFee;
  final int nightStartHour; // 22 = 10 PM
  final int nightEndHour;   // 6 = 6 AM
  final double maxDeliveryDistanceKm;

  const PricingRules({
    this.baseDeliveryFee = 5.0,
    this.perKmFee = 0.5,
    this.freeDeliveryThreshold = 50.0,
    this.taxRate = 0.08,
    this.nightSurchargeFee = 1.0,
    this.nightStartHour = 22,
    this.nightEndHour = 6,
    this.maxDeliveryDistanceKm = 15.0,
  });

  static const defaultRules = PricingRules();
}

/// Core pricing engine — calculates all fees for an order
class PricingEngine {
  final PricingRules rules;

  const PricingEngine({this.rules = PricingRules.defaultRules});

  /// Calculate full pricing for an order
  PricingResult calculate({
    required double subtotal,
    required GeoLocation restaurantLocation,
    required GeoLocation deliveryLocation,
    ZoneModel? zone,
    double discount = 0,
    bool isSubscriber = false,
  }) {
    // 1. Zone fee
    double zoneFee = zone?.deliveryFee ?? rules.baseDeliveryFee;

    // 2. Distance fee
    double distanceKm = _haversineKm(
      restaurantLocation.latitude,
      restaurantLocation.longitude,
      deliveryLocation.latitude,
      deliveryLocation.longitude,
    );
    double distanceFee = zone?.perKmFee != null
        ? (zone!.perKmFee! * distanceKm)
        : (rules.perKmFee * distanceKm);

    // 3. Night surcharge
    double nightSurcharge = 0;
    final hour = DateTime.now().hour;
    if (hour >= rules.nightStartHour || hour < rules.nightEndHour) {
      nightSurcharge = rules.nightSurchargeFee;
    }

    // 4. Free delivery for subscribers or high subtotal
    double totalDeliveryFee = zoneFee + distanceFee + nightSurcharge;
    if (isSubscriber || subtotal >= rules.freeDeliveryThreshold) {
      totalDeliveryFee = 0;
    }

    // 5. Tax (on subtotal only, not delivery)
    double tax = subtotal * rules.taxRate;

    // 6. Grand total
    double grandTotal = (subtotal + totalDeliveryFee + tax - discount).clamp(0.0, double.infinity);

    return PricingResult(
      subtotal: subtotal,
      deliveryFee: totalDeliveryFee,
      distanceFee: distanceFee,
      zoneFee: zoneFee,
      nightSurcharge: nightSurcharge,
      tax: tax,
      discount: discount,
      grandTotal: grandTotal,
      zoneName: zone?.name,
      estimatedMinutes: zone?.estimatedDeliveryMinutes,
    );
  }

  /// Simple flat-fee calculation (backward compatible with old behavior)
  double flatDeliveryFee(double subtotal) {
    return subtotal >= rules.freeDeliveryThreshold ? 0.0 : rules.baseDeliveryFee;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
