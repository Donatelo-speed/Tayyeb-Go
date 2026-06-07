import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryEarningsService {
  static final DeliveryEarningsService instance = DeliveryEarningsService._();
  DeliveryEarningsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double _defaultCommissionPercent = 15.0;
  static const double _defaultDeliveryFee = 5000.0;

  Future<void> creditEarnings({
    required String driverId,
    required String orderId,
    required double totalAmount,
    double? deliveryFee,
    double? commissionPercent,
  }) async {
    final fee = deliveryFee ?? _defaultDeliveryFee;
    final commission = commissionPercent ?? _defaultCommissionPercent;
    final earnings = fee * (1 - commission / 100);

    final walletRef =
        _firestore.collection('driver_wallets').doc(driverId);

    final existingTxns = await walletRef
        .collection('transactions')
        .where('orderId', isEqualTo: orderId)
        .where('type', isEqualTo: 'earning')
        .limit(1)
        .get();

    if (existingTxns.docs.isNotEmpty) return;

    await _firestore.runTransaction((txn) async {
      final doc = await txn.get(walletRef);

      if (!doc.exists) {
        txn.set(walletRef, {
          'driverId': driverId,
          'balance': earnings,
          'pendingPayout': 0,
          'totalEarned': earnings,
          'totalWithdrawn': 0,
          'level': 'bronze',
          'totalDeliveries': 1,
          'averageRating': 0,
          'currentStreak': 0,
          'bestStreak': 0,
          'isSubscribed': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.update(walletRef, {
          'balance': FieldValue.increment(earnings),
          'totalEarned': FieldValue.increment(earnings),
          'totalDeliveries': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final txnRef = walletRef.collection('transactions').doc();
      txn.set(txnRef, {
        'type': 'earning',
        'amount': earnings,
        'orderId': orderId,
        'description': 'Delivery fee after commission',
        'deliveryFee': fee,
        'commission': fee * commission / 100,
        'commissionPercent': commission,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
