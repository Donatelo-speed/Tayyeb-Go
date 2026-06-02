import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payout.dart';
import '../../domain/value_objects/money.dart';
import 'commission_calculator.dart';

DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class RevenueSummary {
  final int totalOrders;
  final Money grossRevenue;
  final Money totalCommission;
  final Money netRevenue;
  final double averageOrderValue;

  const RevenueSummary({
    required this.totalOrders,
    required this.grossRevenue,
    required this.totalCommission,
    required this.netRevenue,
    required this.averageOrderValue,
  });
}

class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CommissionCalculator _calculator = CommissionCalculator();

  Future<RevenueSummary> getRevenueSummary({
    String? restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _firestore.collection('Orders')
      .where('status', isEqualTo: 'delivered') as Query;
    if (restaurantId != null) {
      query = query.where('restaurantId', isEqualTo: restaurantId);
    }
    final snap = await query.get();
    final docs = snap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      if (startDate != null || endDate != null) {
        final createdAt = _parseTimestamp(d['createdAt']);
        if (createdAt != null) {
          if (startDate != null && createdAt.isBefore(startDate)) return false;
          if (endDate != null && createdAt.isAfter(endDate)) return false;
        }
      }
      return true;
    }).toList();

    int totalCents = 0;
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      totalCents += (d['totalAmount'] as num?)?.toInt() ?? 0;
    }

    double avgPercent = 15.0;
    if (restaurantId != null) {
      final restDoc = await _firestore.collection('Restaurants').doc(restaurantId).get();
      if (restDoc.exists) {
        avgPercent = (restDoc.data()?['commissionPercent'] as num?)?.toDouble() ?? 15.0;
      }
    }

    final gross = Money(totalCents);
    final commission = _calculator.calculate(gross, avgPercent);
    final net = _calculator.netAfterCommission(gross, avgPercent);

    return RevenueSummary(
      totalOrders: docs.length,
      grossRevenue: gross,
      totalCommission: commission,
      netRevenue: net,
      averageOrderValue: docs.isNotEmpty ? (totalCents / docs.length).toDouble() : 0,
    );
  }

  Future<void> generatePayout({
    required String restaurantId,
    required String restaurantName,
    required String periodStart,
    required String periodEnd,
  }) async {
    final summary = await getRevenueSummary(
      restaurantId: restaurantId,
      startDate: DateTime.tryParse(periodStart),
      endDate: DateTime.tryParse(periodEnd),
    );
    final payout = Payout(
      id: '',
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      grossAmount: summary.grossRevenue,
      commissionAmount: summary.totalCommission,
      netAmount: summary.netRevenue,
      periodStart: periodStart,
      periodEnd: periodEnd,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('payouts').doc().set(payout.toMap());
  }
}
