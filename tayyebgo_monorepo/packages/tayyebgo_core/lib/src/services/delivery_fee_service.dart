enum DeliveryZone {
  downtown,
  suburban,
  outskirts,
  university,
  industrial,
}

class DeliveryEstimate {
  final int fee;
  final int estimatedTimeMinutes;
  final bool freeDeliveryEligible;
  final DeliveryZone zone;

  DeliveryEstimate({
    required this.fee,
    required this.estimatedTimeMinutes,
    required this.freeDeliveryEligible,
    required this.zone,
  });
}

class DeliveryFeeService {
  static const int baseFee = 500;
  static const double perKmRate = 200;
  static const double peakHourSurcharge = 1.5;
  static const double maxDemandSurcharge = 2.0;
  static const int freeDeliveryThreshold = 50000;
  static const int minimumFee = 300;
  static const int maximumFee = 5000;

  static const Map<DeliveryZone, double> zoneRates = {
    DeliveryZone.downtown: 1.0,
    DeliveryZone.suburban: 1.2,
    DeliveryZone.outskirts: 1.5,
    DeliveryZone.university: 0.9,
    DeliveryZone.industrial: 1.3,
  };

  static const Map<DeliveryZone, int> zoneBaseTimes = {
    DeliveryZone.downtown: 15,
    DeliveryZone.suburban: 25,
    DeliveryZone.outskirts: 40,
    DeliveryZone.university: 20,
    DeliveryZone.industrial: 30,
  };

  static const int peakHourStart = 18;
  static const int peakHourEnd = 21;

  int calculateDeliveryFee({
    required double distance,
    required DeliveryZone zone,
    required int timeOfDay,
    required double demand,
  }) {
    double fee = baseFee.toDouble();
    fee += distance * perKmRate;

    final zoneMultiplier = zoneRates[zone] ?? 1.0;
    fee *= zoneMultiplier;

    if (timeOfDay >= peakHourStart && timeOfDay < peakHourEnd) {
      fee *= peakHourSurcharge;
    }

    if (demand > 1.0) {
      final demandSurcharge = 1.0 + ((demand - 1.0) * (maxDemandSurcharge - 1.0));
      fee *= demandSurcharge.clamp(1.0, maxDemandSurcharge);
    }

    return fee.round().clamp(minimumFee, maximumFee);
  }

  DeliveryEstimate getDeliveryEstimate({
    required double distance,
    required DeliveryZone zone,
    int? timeOfDay,
    double? demand,
  }) {
    final hour = timeOfDay ?? DateTime.now().hour;
    final demandLevel = demand ?? 1.0;

    final fee = calculateDeliveryFee(
      distance: distance,
      zone: zone,
      timeOfDay: hour,
      demand: demandLevel,
    );

    final baseTime = zoneBaseTimes[zone] ?? 25;
    final estimatedTime = baseTime + (distance * 3).round();
    final isFreeDelivery = fee == 0;

    return DeliveryEstimate(
      fee: fee,
      estimatedTimeMinutes: estimatedTime,
      freeDeliveryEligible: isFreeDelivery,
      zone: zone,
    );
  }

  bool isFreeDelivery(int orderTotal) {
    return orderTotal >= freeDeliveryThreshold;
  }

  int getZoneMultiplierPercent(DeliveryZone zone) {
    final rate = zoneRates[zone] ?? 1.0;
    return ((rate - 1.0) * 100).round();
  }
}
