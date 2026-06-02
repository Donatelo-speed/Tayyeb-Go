enum PaymentMethod { cash, card, wallet }

enum PaymentStatus { pending, completed, refunded, failed }

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'amount': amount,
        'method': method.name,
        'status': status.name,
        if (transactionId != null) 'transactionId': transactionId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        amount: (json['amount'] as num).toDouble(),
        method: PaymentMethod.values.firstWhere(
            (e) => e.name == json['method'],
            orElse: () => PaymentMethod.cash),
        status: PaymentStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => PaymentStatus.pending),
        transactionId: json['transactionId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
