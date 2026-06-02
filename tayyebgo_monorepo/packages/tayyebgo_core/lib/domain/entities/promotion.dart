import '../value_objects/money.dart';

class Promotion {
  final String id;
  final String name;
  final String? description;
  final int discountPercent;
  final Money maxDiscount;
  final Money minOrder;
  final bool isActive;
  final int usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  const Promotion({
    required this.id,
    required this.name,
    this.description,
    required this.discountPercent,
    required this.maxDiscount,
    required this.minOrder,
    this.isActive = true,
    this.usageLimit = 100,
    this.usedCount = 0,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  bool get isValid =>
      isActive &&
      usedCount < usageLimit &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'discountPercent': discountPercent,
        'maxDiscount': maxDiscount.amountInCents,
        'minOrder': minOrder.amountInCents,
        'isActive': isActive,
        'usageLimit': usageLimit,
        'usedCount': usedCount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Promotion.fromMap(Map<String, dynamic> m, String docId) => Promotion(
        id: docId,
        name: m['name'] as String? ?? '',
        description: m['description'] as String?,
        discountPercent: (m['discountPercent'] as num?)?.toInt() ?? 0,
        maxDiscount: Money((m['maxDiscount'] as num?)?.toInt() ?? 0),
        minOrder: Money((m['minOrder'] as num?)?.toInt() ?? 0),
        isActive: m['isActive'] as bool? ?? true,
        usageLimit: (m['usageLimit'] as num?)?.toInt() ?? 100,
        usedCount: (m['usedCount'] as num?)?.toInt() ?? 0,
        startDate: DateTime.tryParse(m['startDate'] as String? ?? '') ??
            DateTime.now(),
        endDate: DateTime.tryParse(m['endDate'] as String? ?? '') ??
            DateTime.now(),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
