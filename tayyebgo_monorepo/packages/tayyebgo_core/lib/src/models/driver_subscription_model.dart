enum DriverSubscriptionPlan {
  basic,
  pro,
  premium,
}

enum DriverSubscriptionStatus {
  active,
  expired,
  cancelled,
}

class DriverSubscription {
  final String id;
  final String driverId;
  final DriverSubscriptionPlan planType;
  final DriverSubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;

  DriverSubscription({
    required this.id,
    required this.driverId,
    required this.planType,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.autoRenew = false,
  });

  bool get isActive =>
      status == DriverSubscriptionStatus.active &&
      DateTime.now().isBefore(endDate);

  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  DateTime get nextBillingDate => endDate;

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'driverId': driverId,
      'planType': planType.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'autoRenew': autoRenew,
    };
  }

  factory DriverSubscription.fromJSON(Map<String, dynamic> json) {
    return DriverSubscription(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      planType: DriverSubscriptionPlan.values.byName(json['planType'] as String),
      status: DriverSubscriptionStatus.values.byName(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      autoRenew: json['autoRenew'] as bool? ?? false,
    );
  }

  DriverSubscription copyWith({
    String? id,
    String? driverId,
    DriverSubscriptionPlan? planType,
    DriverSubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
  }) {
    return DriverSubscription(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }
}

class DriverSubscriptionPlanInfo {
  final DriverSubscriptionPlan plan;
  final String name;
  final int pricePerMonth;
  final int maxConcurrentDeliveries;
  final bool priorityDispatch;
  final bool batchedRoutes;
  final List<String> benefits;

  const DriverSubscriptionPlanInfo({
    required this.plan,
    required this.name,
    required this.pricePerMonth,
    required this.maxConcurrentDeliveries,
    this.priorityDispatch = false,
    this.batchedRoutes = false,
    required this.benefits,
  });
}
