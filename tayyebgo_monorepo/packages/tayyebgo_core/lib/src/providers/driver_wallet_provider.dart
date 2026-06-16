import 'package:flutter/foundation.dart';
import '../models/driver_wallet_model.dart';
import '../di/app_locator.dart';

class DriverWalletProvider extends ChangeNotifier {
  DriverWalletModel? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;

  DriverWalletModel? get wallet => _wallet;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWallet(String driverId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await AppLocator.instance.driverWallet.getWallet(driverId);
      if (data != null) {
        _wallet = DriverWalletModel.fromMap(driverId, data);
      }

      _transactions = await AppLocator.instance.driverWallet
          .watchTransactions(driverId)
          .first;

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
      final success = await AppLocator.instance.driverWallet.creditEarnings(
        driverId: driverId,
        orderId: orderId,
        amount: amount,
        description: description,
      );
      if (success) await loadWallet(driverId);
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPayout(String driverId, double amount) async {
    try {
      if (_wallet == null || _wallet!.balance < amount) return false;
      final success = await AppLocator.instance.driverWallet.requestPayout(
        driverId: driverId,
        amount: amount,
      );
      if (success) await loadWallet(driverId);
      return success;
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
      await AppLocator.instance.driverWallet.updateLevel(driverId, newLevel.firestoreValue);
      _wallet = _wallet!.copyWith(level: newLevel);
      notifyListeners();
    }
  }

  void clear() {
    _wallet = null;
    _transactions = [];
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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
