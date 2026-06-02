import 'package:flutter/material.dart';

class AuthListenable extends ChangeNotifier {
  static AuthListenable? _instance;
  static AuthListenable? get instance => _instance;

  AuthListenable() {
    _instance = this;
  }

  void forceNotify() => notifyListeners();

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }
}
