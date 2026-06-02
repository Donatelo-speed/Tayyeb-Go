class PaymentMethod {
  final String id;
  final String userId;
  final String type;
  final String? lastFourDigits;
  final String? cardBrand;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.lastFourDigits,
    this.cardBrand,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'lastFourDigits': lastFourDigits,
        'cardBrand': cardBrand,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PaymentMethod.fromMap(Map<String, dynamic> m, String docId) =>
      PaymentMethod(
        id: docId,
        userId: m['userId'] as String? ?? '',
        type: m['type'] as String? ?? 'cash',
        lastFourDigits: m['lastFourDigits'] as String?,
        cardBrand: m['cardBrand'] as String?,
        isDefault: m['isDefault'] == true,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
