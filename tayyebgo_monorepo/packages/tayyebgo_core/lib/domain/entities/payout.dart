import '../value_objects/money.dart';

class Payout {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final Money grossAmount;
  final Money commissionAmount;
  final Money netAmount;
  final String status;
  final String periodStart;
  final String periodEnd;
  final String? notes;
  final DateTime createdAt;
  final DateTime? paidAt;

  const Payout({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    this.status = 'pending',
    required this.periodStart,
    required this.periodEnd,
    this.notes,
    required this.createdAt,
    this.paidAt,
  });

  Map<String, dynamic> toMap() => {
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'grossAmountInCents': grossAmount.amountInCents,
        'commissionAmountInCents': commissionAmount.amountInCents,
        'netAmountInCents': netAmount.amountInCents,
        'status': status,
        'periodStart': periodStart,
        'periodEnd': periodEnd,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      };

  factory Payout.fromMap(Map<String, dynamic> m, String docId) => Payout(
        id: docId,
        restaurantId: m['restaurantId'] as String? ?? '',
        restaurantName: m['restaurantName'] as String? ?? '',
        grossAmount: Money((m['grossAmountInCents'] as num?)?.toInt() ?? 0),
        commissionAmount: Money((m['commissionAmountInCents'] as num?)?.toInt() ?? 0),
        netAmount: Money((m['netAmountInCents'] as num?)?.toInt() ?? 0),
        status: m['status'] as String? ?? 'pending',
        periodStart: m['periodStart'] as String? ?? '',
        periodEnd: m['periodEnd'] as String? ?? '',
        notes: m['notes'] as String?,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        paidAt: DateTime.tryParse(m['paidAt'] as String? ?? ''),
      );
}
