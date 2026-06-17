class UnitEconomics {
  final double orderTotal;
  final double deliveryFeeCharged;
  final double commissionPercent;
  final double commissionAmount;
  final double driverEarnings;
  final double platformFee;
  final double driverCost;
  final double platformCost;
  final double profit;
  final double margin;

  const UnitEconomics({
    required this.orderTotal,
    required this.deliveryFeeCharged,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.driverEarnings,
    required this.platformFee,
    required this.driverCost,
    required this.platformCost,
    required this.profit,
    required this.margin,
  });

  factory UnitEconomics.calculate({
    required double orderTotal,
    required double deliveryFeeCharged,
    double commissionPercent = 10.0,
    double driverCost = 12000.0,
    double platformCost = 2000.0,
  }) {
    final commissionAmount = orderTotal * commissionPercent / 100;
    final driverEarnings = deliveryFeeCharged * 0.8;
    final platformFee = deliveryFeeCharged * 0.2;
    final totalRevenue = commissionAmount + platformFee;
    final totalCost = driverCost + platformCost;
    final profit = totalRevenue - totalCost;
    final margin = orderTotal > 0 ? profit / orderTotal * 100 : 0.0;

    return UnitEconomics(
      orderTotal: orderTotal,
      deliveryFeeCharged: deliveryFeeCharged,
      commissionPercent: commissionPercent,
      commissionAmount: commissionAmount,
      driverEarnings: driverEarnings,
      platformFee: platformFee,
      driverCost: driverCost,
      platformCost: platformCost,
      profit: profit,
      margin: margin,
    );
  }

  bool get isProfitable => profit > 0;

  Map<String, dynamic> toMap() => {
        'orderTotal': orderTotal,
        'deliveryFeeCharged': deliveryFeeCharged,
        'commissionPercent': commissionPercent,
        'commissionAmount': commissionAmount,
        'driverEarnings': driverEarnings,
        'platformFee': platformFee,
        'driverCost': driverCost,
        'platformCost': platformCost,
        'profit': profit,
        'margin': margin,
      };

  @override
  String toString() =>
      'UnitEconomics(order: $orderTotal, commission: $commissionAmount, '
      'driver: $driverCost, platform: $platformCost, profit: $profit, '
      'margin: ${margin.toStringAsFixed(1)}%)';
}
