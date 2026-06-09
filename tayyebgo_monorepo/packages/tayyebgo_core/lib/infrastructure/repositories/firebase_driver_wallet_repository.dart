import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_driver_wallet_repository.dart';

class FirebaseDriverWalletRepository implements IDriverWalletRepository {
  static final FirebaseDriverWalletRepository instance = FirebaseDriverWalletRepository._();
  FirebaseDriverWalletRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getWallet(String driverId) async {
    final doc = await _firestore.collection('driver_wallets').doc(driverId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTransactions(String driverId) =>
      _firestore
          .collection('driver_wallets')
          .doc(driverId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map((d) {
                final data = d.data();
                data['id'] = d.id;
                return data;
              }).toList());

  @override
  Future<bool> creditEarnings({
    required String driverId,
    required String orderId,
    required double amount,
    required String description,
  }) async {
    try {
      final walletRef = _firestore.collection('driver_wallets').doc(driverId);

      final existingTxns = await walletRef
          .collection('transactions')
          .where('orderId', isEqualTo: orderId)
          .where('type', isEqualTo: 'earning')
          .limit(1)
          .get();
      if (existingTxns.docs.isNotEmpty) return true;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(walletRef);
        if (!doc.exists) {
          transaction.set(walletRef, {
            'driverId': driverId,
            'balance': amount,
            'pendingPayout': 0,
            'totalEarned': amount,
            'totalWithdrawn': 0,
            'totalDeliveries': 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(walletRef, {
            'balance': FieldValue.increment(amount),
            'totalEarned': FieldValue.increment(amount),
            'totalDeliveries': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final txnRef = walletRef.collection('transactions').doc();
        transaction.set(txnRef, {
          'type': 'earning',
          'amount': amount,
          'orderId': orderId,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPayout({
    required String driverId,
    required double amount,
  }) async {
    try {
      final walletRef = _firestore.collection('driver_wallets').doc(driverId);

      await _firestore.runTransaction((transaction) async {
        transaction.update(walletRef, {
          'balance': FieldValue.increment(-amount),
          'pendingPayout': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final txnRef = walletRef.collection('transactions').doc();
        transaction.set(txnRef, {
          'type': 'payout_request',
          'amount': amount,
          'status': 'pending',
          'description': 'Payout request',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateLevel(String driverId, String level) async {
    await _firestore
        .collection('driver_wallets')
        .doc(driverId)
        .update({'level': level});
  }
}
