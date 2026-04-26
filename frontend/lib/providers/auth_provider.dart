import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  String? _token;

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  String? get token => _token;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isDelivery => _user?.isDelivery ?? false;
  bool get isCustomer => _user?.isCustomer ?? true;

  Future<void> checkAuthStatus() async {
    try {
      _state = AuthState.loading;
      notifyListeners();
      _token = await _apiService.getToken();
      if (_token != null) {
        final userData = await _apiService.getCurrentUser();
        _user = User.fromJson(userData);
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      await _apiService.deleteToken();
      _token = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _state = AuthState.loading;
      _error = null;
      notifyListeners();
      final response = await _apiService.login(email: email, password: password);
      _token = response['token'];
      await _apiService.saveToken(_token!);
      _user = User.fromJson(response['user']);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({required String email, required String password, required String fullName, String? phone, String role = 'customer'}) async {
    try {
      _state = AuthState.loading;
      _error = null;
      notifyListeners();
      final response = await _apiService.register(email: email, password: password, fullName: fullName, phone: phone, role: role);
      _token = response['token'];
      await _apiService.saveToken(_token!);
      _user = User.fromJson(response['user']);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.deleteToken();
    _user = null;
    _token = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}