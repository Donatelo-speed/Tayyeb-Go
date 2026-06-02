import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
}

class PartnerRoleController extends ChangeNotifier {
  final AuthProvider _auth;

  PartnerRoleController(this._auth) {
    _auth.addListener(notifyListeners);
  }

  String get currentRole {
    final role = _auth.user?.role;
    if (role == UserRole.cashier) return 'cashier';
    if (role == UserRole.restaurantOwner) return 'owner';
    if (role == UserRole.superAdmin) return 'owner';
    return 'unknown';
  }

  String? get restaurantId => _auth.user?.vendorId;

  bool get isCashier => currentRole == 'cashier';
  bool get isOwner => currentRole == 'owner';

  void assertOwnerOnly() {
    if (!isOwner) {
      _auth.logout();
      throw PermissionDeniedException(
        'Owner-only operation attempted by role: $currentRole',
      );
    }
  }
}
