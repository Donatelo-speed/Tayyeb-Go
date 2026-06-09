import 'package:flutter/foundation.dart';
import '../models/loyalty_transaction.dart';
import '../models/user_model.dart';
import '../di/app_locator.dart';

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

      final data = await AppLocator.instance.loyalty.getTransactions(userId);
      _transactions = data.map((d) => LoyaltyTransaction.fromMap(d['id'] as String, d)).toList();

      final streakData = await AppLocator.instance.loyalty.getStreakData(userId);
      _currentStreak = streakData['currentStreak'] ?? 0;
      _bestStreak = streakData['bestStreak'] ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> awardOrderPoints(UserModel user, int points, String orderId) async {
    try {
      final success = await AppLocator.instance.loyalty.awardPoints(
        userId: user.id,
        points: points,
        type: LoyaltyTransactionType.earned.firestoreValue,
        description: 'Points for order',
        orderId: orderId,
      );
      if (success) await loadTransactions(user.id);
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> awardReferralPoints(String userId, int points, String referralId) async {
    try {
      return await AppLocator.instance.loyalty.awardPoints(
        userId: userId,
        points: points,
        type: LoyaltyTransactionType.referral.firestoreValue,
        description: 'Referral bonus',
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> awardStreakBonus(String userId, int streakDay) async {
    try {
      final points = streakDay * 10;
      final success = await AppLocator.instance.loyalty.awardPoints(
        userId: userId,
        points: points,
        type: LoyaltyTransactionType.streak.firestoreValue,
        description: '$streakDay-day streak bonus',
      );
      if (success) {
        _currentStreak = streakDay;
        if (streakDay > _bestStreak) _bestStreak = streakDay;
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> redeemPoints(String userId, int points, String description) async {
    try {
      final success = await AppLocator.instance.loyalty.redeemPoints(
        userId: userId,
        points: points,
        description: description,
      );
      if (success) await loadTransactions(userId);
      return success;
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
