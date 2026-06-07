import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/loyalty_transaction.dart';
import '../models/user_model.dart';

class LoyaltyProvider extends ChangeNotifier {
  List<LoyaltyTransaction> _transactions = [];
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _isLoading = false;
  String? _error;

  List<LoyaltyTransaction> get transactions => _transactions;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snap = await FirebaseFirestore.instance
          .collection('loyalty_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _transactions = snap.docs
          .map((d) => LoyaltyTransaction.fromFirestore(d))
          .toList();

      _computeStreaks(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _computeStreaks(String userId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('loyalty_transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'streak')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        _currentStreak = (d['streakDay'] as num?)?.toInt() ?? 0;
        _bestStreak = (d['bestStreak'] as num?)?.toInt() ?? _currentStreak;
      }
    } catch (_) {}
  }

  Future<bool> awardOrderPoints(UserModel user, int points, String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('loyalty_transactions').add({
        'userId': user.id,
        'points': points,
        'type': LoyaltyTransactionType.earned.firestoreValue,
        'description': 'Points for order',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'loyaltyPoints': FieldValue.increment(points),
      });

      await loadTransactions(user.id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> awardReferralPoints(String userId, int points, String referralId) async {
    try {
      await FirebaseFirestore.instance.collection('loyalty_transactions').add({
        'userId': userId,
        'points': points,
        'type': LoyaltyTransactionType.referral.firestoreValue,
        'description': 'Referral bonus',
        'referralId': referralId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(points),
      });

      await loadTransactions(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> awardStreakBonus(String userId, int streakDay) async {
    try {
      final points = streakDay * 10;
      await FirebaseFirestore.instance.collection('loyalty_transactions').add({
        'userId': userId,
        'points': points,
        'type': LoyaltyTransactionType.streak.firestoreValue,
        'description': '$streakDay-day streak bonus',
        'streakDay': streakDay,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(points),
      });

      _currentStreak = streakDay;
      if (streakDay > _bestStreak) _bestStreak = streakDay;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> redeemPoints(String userId, int points, String description) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final currentPoints = (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;

      if (currentPoints < points) return false;

      await FirebaseFirestore.instance.collection('loyalty_transactions').add({
        'userId': userId,
        'points': -points,
        'type': LoyaltyTransactionType.redeemed.firestoreValue,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(-points),
      });

      await loadTransactions(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  int get pointsForNextReward {
    if (_currentStreak < 3) return 50;
    if (_currentStreak < 7) return 100;
    if (_currentStreak < 14) return 200;
    return 500;
  }

  void clear() {
    _transactions = [];
    _currentStreak = 0;
    _bestStreak = 0;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
