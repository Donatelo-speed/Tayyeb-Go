enum PayoutStatus { pending, processing, completed, failed }

class Payout {
  final String id;
  final String vendorId;
  final String vendorName;
  final double amount;
  final double fee;
  final double netAmount;
  final PayoutStatus status;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;

  const Payout({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.amount,
    required this.fee,
    required this.netAmount,
    this.status = PayoutStatus.pending,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'vendorId': vendorId,
        'vendorName': vendorName,
        'amount': amount,
        'fee': fee,
        'netAmount': netAmount,
        'status': status.name,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payout.fromMap(Map<String, dynamic> m, String docId) => Payout(
        id: docId,
        vendorId: m['vendorId'] as String? ?? '',
        vendorName: m['vendorName'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        fee: (m['fee'] as num?)?.toDouble() ?? 0,
        netAmount: (m['netAmount'] as num?)?.toDouble() ?? 0,
        status: PayoutStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => PayoutStatus.pending,
        ),
        periodStart: DateTime.tryParse(m['periodStart'] as String? ?? '') ?? DateTime.now(),
        periodEnd: DateTime.tryParse(m['periodEnd'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
