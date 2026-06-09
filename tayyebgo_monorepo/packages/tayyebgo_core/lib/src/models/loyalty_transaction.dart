import 'package:cloud_firestore/cloud_firestore.dart';

enum LoyaltyTransactionType {
  earned,
  redeemed,
  expired,
  bonus,
  referral,
  streak;

  static LoyaltyTransactionType fromString(String? v) => switch (v) {
        'earned' => LoyaltyTransactionType.earned,
        'redeemed' => LoyaltyTransactionType.redeemed,
        'expired' => LoyaltyTransactionType.expired,
        'bonus' => LoyaltyTransactionType.bonus,
        'referral' => LoyaltyTransactionType.referral,
        'streak' => LoyaltyTransactionType.streak,
        _ => LoyaltyTransactionType.earned,
      };

  String get firestoreValue => name;
}

class LoyaltyTransaction {
  final String id;
  final String userId;
  final int points;
  final LoyaltyTransactionType type;
  final String description;
  final String? orderId;
  final String? referralId;
  final int? streakDay;
  final DateTime? createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    this.description = '',
    this.orderId,
    this.referralId,
    this.streakDay,
    this.createdAt,
  });

  factory LoyaltyTransaction.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return LoyaltyTransaction._fromMap(doc.id, d);
  }

  factory LoyaltyTransaction.fromMap(String id, Map<String, dynamic> d) =>
      LoyaltyTransaction._fromMap(id, d);

  factory LoyaltyTransaction._fromMap(String id, Map<String, dynamic> d) {
    return LoyaltyTransaction(
      id: id,
      userId: d['userId'] as String? ?? '',
      points: (d['points'] as num?)?.toInt() ?? 0,
      type: LoyaltyTransactionType.fromString(d['type'] as String?),
      description: d['description'] as String? ?? '',
      orderId: d['orderId'] as String?,
      referralId: d['referralId'] as String?,
      streakDay: (d['streakDay'] as num?)?.toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'points': points,
        'type': type.firestoreValue,
        'description': description,
        if (orderId != null) 'orderId': orderId,
        if (referralId != null) 'referralId': referralId,
        if (streakDay != null) 'streakDay': streakDay,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
