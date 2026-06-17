import 'package:flutter/foundation.dart';
import '../services/guest_mode_service.dart';

class GuestModeProvider extends ChangeNotifier {
  final GuestModeService _service = GuestModeService();

  GuestModeService get service => _service;

  bool get isGuest => _service.isGuest;

  Future<void> enterGuestMode() async {
    await _service.enterGuestMode();
    notifyListeners();
  }

  Future<void> exitGuestMode() async {
    await _service.exitGuestMode();
    notifyListeners();
  }

  Future<void> addToGuestCart(Map<String, dynamic> item) async {
    await _service.addToGuestCart(item);
    notifyListeners();
  }

  Future<void> removeFromGuestCart(String itemId) async {
    await _service.removeFromGuestCart(itemId);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getGuestCart() {
    return _service.getGuestCart();
  }

  Future<void> clearGuestCart() async {
    await _service.clearGuestCart();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> mergeGuestCartWithUser(String userId) async {
    final cart = await _service.mergeGuestCartWithUser(userId);
    notifyListeners();
    return cart;
  }
}
