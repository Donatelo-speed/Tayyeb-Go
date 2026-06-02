import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverLevel {
  bronze,
  silver,
  gold,
  elite;

  static DriverLevel fromString(String? v) => switch (v) {
        'bronze' => DriverLevel.bronze,
        'silver' => DriverLevel.silver,
        'gold' => DriverLevel.gold,
        'elite' => DriverLevel.elite,
        _ => DriverLevel.bronze,
      };

  String get firestoreValue => name;

  String get displayName => switch (this) {
        DriverLevel.bronze => 'Bronze',
        DriverLevel.silver => 'Silver',
        DriverLevel.gold => 'Gold',
        DriverLevel.elite => 'Elite',
      };

  int get minDeliveries => switch (this) {
        DriverLevel.bronze => 0,
        DriverLevel.silver => 50,
        DriverLevel.gold => 200,
        DriverLevel.elite => 500,
      };

  double get minRating => switch (this) {
        DriverLevel.bronze => 0,
        DriverLevel.silver => 4.0,
        DriverLevel.gold => 4.3,
        DriverLevel.elite => 4.5,
      };

  double get commissionDiscount => switch (this) {
        DriverLevel.bronze => 0,
        DriverLevel.silver => 0.05,
        DriverLevel.gold => 0.10,
        DriverLevel.elite => 0.15,
      };

  int get priorityScore => switch (this) {
        DriverLevel.bronze => 1,
        DriverLevel.silver => 2,
        DriverLevel.gold => 3,
        DriverLevel.elite => 5,
      };

  int get bonusPerDelivery => switch (this) {
        DriverLevel.bronze => 0,
        DriverLevel.silver => 50,
        DriverLevel.gold => 100,
        DriverLevel.elite => 200,
      };
}

class DriverWalletModel {
  final String driverId;
  final double balance;
  final double pendingPayout;
  final double totalEarned;
  final double totalWithdrawn;
  final DriverLevel level;
  final int totalDeliveries;
  final double averageRating;
  final int currentStreak;
  final int bestStreak;
  final bool isSubscribed;
  final DateTime? subscriptionExpiry;
  final String? subscriptionPlan;
  final DateTime? lastPayoutDate;
  final DateTime? updatedAt;

  const DriverWalletModel({
    required this.driverId,
    this.balance = 0,
    this.pendingPayout = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    this.level = DriverLevel.bronze,
    this.totalDeliveries = 0,
    this.averageRating = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isSubscribed = false,
    this.subscriptionExpiry,
    this.subscriptionPlan,
    this.lastPayoutDate,
    this.updatedAt,
  });

  double get availableBalance => balance - pendingPayout;

  bool get isElite => level == DriverLevel.elite;
  bool get canWithdraw => availableBalance > 0;

  DriverLevel get nextLevel => switch (level) {
        DriverLevel.bronze => DriverLevel.silver,
        DriverLevel.silver => DriverLevel.gold,
        DriverLevel.gold => DriverLevel.elite,
        DriverLevel.elite => DriverLevel.elite,
      };

  int get deliveriesToNextLevel {
    if (level == DriverLevel.elite) return 0;
    return nextLevel.minDeliveries - totalDeliveries;
  }

  factory DriverWalletModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return DriverWalletModel(
      driverId: doc.id,
      balance: (d['balance'] as num?)?.toDouble() ?? 0,
      pendingPayout: (d['pendingPayout'] as num?)?.toDouble() ?? 0,
      totalEarned: (d['totalEarned'] as num?)?.toDouble() ?? 0,
      totalWithdrawn: (d['totalWithdrawn'] as num?)?.toDouble() ?? 0,
      level: DriverLevel.fromString(d['level'] as String?),
      totalDeliveries: (d['totalDeliveries'] as num?)?.toInt() ?? 0,
      averageRating: (d['averageRating'] as num?)?.toDouble() ?? 0,
      currentStreak: (d['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (d['bestStreak'] as num?)?.toInt() ?? 0,
      isSubscribed: d['isSubscribed'] as bool? ?? false,
      subscriptionExpiry: (d['subscriptionExpiry'] as Timestamp?)?.toDate(),
      subscriptionPlan: d['subscriptionPlan'] as String?,
      lastPayoutDate: (d['lastPayoutDate'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'balance': balance,
        'pendingPayout': pendingPayout,
        'totalEarned': totalEarned,
        'totalWithdrawn': totalWithdrawn,
        'level': level.firestoreValue,
        'totalDeliveries': totalDeliveries,
        'averageRating': averageRating,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'isSubscribed': isSubscribed,
        if (subscriptionExpiry != null)
          'subscriptionExpiry': Timestamp.fromDate(subscriptionExpiry!),
        if (subscriptionPlan != null) 'subscriptionPlan': subscriptionPlan,
        if (lastPayoutDate != null)
          'lastPayoutDate': Timestamp.fromDate(lastPayoutDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
