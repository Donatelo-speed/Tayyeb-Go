import '../enums/subscription_plan.dart';
import '../enums/subscription_status.dart';
import '../value_objects/money.dart';

class CustomerSubscription {
  final String id;
  final String userId;
  final SubscriptionPlanType plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime expiryDate;
  final Money pricePaid;
  final String? paymentTransactionId;
  final double totalSavings;
  final int ordersUsed;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const CustomerSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    this.status = SubscriptionStatus.pending,
    required this.startDate,
    required this.expiryDate,
    required this.pricePaid,
    this.paymentTransactionId,
    this.totalSavings = 0,
    this.ordersUsed = 0,
    required this.createdAt,
    this.cancelledAt,
    this.cancelReason,
  });

  bool get isActive =>
      status == SubscriptionStatus.active && DateTime.now().isBefore(expiryDate);
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  int get daysRemaining =>
      expiryDate.difference(DateTime.now()).inDays.clamp(0, 999);

  Money calculateDiscount(Money orderSubtotal) {
    if (!isActive) return const Money(0);
    final discountCents =
        (orderSubtotal.amountInCents * plan.discountPercent / 100).round();
    return Money(discountCents);
  }

  bool get hasFreeDelivery => isActive;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'plan': plan.value,
        'status': status.value,
        'startDate': startDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'pricePaid': pricePaid.amountInCents,
        'paymentTransactionId': paymentTransactionId,
        'totalSavings': totalSavings,
        'ordersUsed': ordersUsed,
        'createdAt': createdAt.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'cancelReason': cancelReason,
      };

  factory CustomerSubscription.fromMap(Map<String, dynamic> m, String docId) =>
      CustomerSubscription(
        id: docId,
        userId: m['userId'] as String? ?? '',
        plan: SubscriptionPlanType.fromValue(m['plan'] as String? ?? ''),
        status:
            SubscriptionStatus.fromValue(m['status'] as String? ?? ''),
        startDate: DateTime.tryParse(m['startDate'] as String? ?? '') ??
            DateTime.now(),
        expiryDate: DateTime.tryParse(m['expiryDate'] as String? ?? '') ??
            DateTime.now(),
        pricePaid: Money((m['pricePaid'] as num?)?.toInt() ?? 0),
        paymentTransactionId: m['paymentTransactionId'] as String?,
        totalSavings: (m['totalSavings'] as num?)?.toDouble() ?? 0,
        ordersUsed: (m['ordersUsed'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
        cancelledAt:
            DateTime.tryParse(m['cancelledAt'] as String? ?? ''),
        cancelReason: m['cancelReason'] as String?,
      );

  CustomerSubscription copyWith({
    SubscriptionStatus? status,
    DateTime? expiryDate,
    double? totalSavings,
    int? ordersUsed,
    DateTime? cancelledAt,
    String? cancelReason,
    String? paymentTransactionId,
  }) =>
      CustomerSubscription(
        id: id,
        userId: userId,
        plan: plan,
        status: status ?? this.status,
        startDate: startDate,
        expiryDate: expiryDate ?? this.expiryDate,
        pricePaid: pricePaid,
        paymentTransactionId:
            paymentTransactionId ?? this.paymentTransactionId,
        totalSavings: totalSavings ?? this.totalSavings,
        ordersUsed: ordersUsed ?? this.ordersUsed,
        createdAt: createdAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        cancelReason: cancelReason ?? this.cancelReason,
      );
}
