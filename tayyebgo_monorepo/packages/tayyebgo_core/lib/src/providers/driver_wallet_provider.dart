import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/driver_wallet_model.dart';

class DriverWalletProvider extends ChangeNotifier {
  DriverWalletModel? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _error;

  DriverWalletModel? get wallet => _wallet;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWallet(String driverId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await FirebaseFirestore.instance
          .collection('driver_wallets')
          .doc(driverId)
          .get();

      if (doc.exists) {
        _wallet = DriverWalletModel.fromFirestore(doc);
      }

      final txnSnap = await FirebaseFirestore.instance
          .collection('driver_wallets')
          .doc(driverId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _transactions = txnSnap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEarnings(String driverId, double amount, String orderId, String description) async {
    try {
      final walletRef = FirebaseFirestore.instance.collection('driver_wallets').doc(driverId);

      final existingTxns = await walletRef
          .collection('transactions')
          .where('orderId', isEqualTo: orderId)
          .where('type', isEqualTo: 'earning')
          .limit(1)
          .get();
      if (existingTxns.docs.isNotEmpty) return true;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
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

      await loadWallet(driverId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPayout(String driverId, double amount) async {
    try {
      if (_wallet == null || _wallet!.balance < amount) return false;

      final walletRef = FirebaseFirestore.instance.collection('driver_wallets').doc(driverId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
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

      await loadWallet(driverId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  DriverLevel _calculateLevel(int deliveries, double rating) {
    if (rating >= 4.5 && deliveries >= 500) return DriverLevel.elite;
    if (rating >= 4.3 && deliveries >= 200) return DriverLevel.gold;
    if (rating >= 4.0 && deliveries >= 50) return DriverLevel.silver;
    return DriverLevel.bronze;
  }

  Future<void> checkLevelUp(String driverId) async {
    if (_wallet == null) return;
    final newLevel = _calculateLevel(_wallet!.totalDeliveries, _wallet!.averageRating);
    if (newLevel != _wallet!.level) {
      await FirebaseFirestore.instance
          .collection('driver_wallets')
          .doc(driverId)
          .update({'level': newLevel.firestoreValue});
      _wallet = _wallet!.copyWith(level: newLevel);
      notifyListeners();
    }
  }

  void clear() {
    _wallet = null;
    _transactions = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

extension DriverWalletModelCopy on DriverWalletModel {
  DriverWalletModel copyWith({
    DriverLevel? level,
  }) =>
      DriverWalletModel(
        driverId: driverId,
        balance: balance,
        pendingPayout: pendingPayout,
        totalEarned: totalEarned,
        totalWithdrawn: totalWithdrawn,
        level: level ?? this.level,
        totalDeliveries: totalDeliveries,
        averageRating: averageRating,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        isSubscribed: isSubscribed,
        subscriptionExpiry: subscriptionExpiry,
        subscriptionPlan: subscriptionPlan,
        lastPayoutDate: lastPayoutDate,
        updatedAt: updatedAt,
      );
}
