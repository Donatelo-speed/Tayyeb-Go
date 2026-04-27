import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/token_manager.dart';
import '../services/biometric_auth.dart';
import '../config.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  String? _token;
  bool _biometricEnabled = false;

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  String? get token => _token;
  bool get biometricEnabled => _biometricEnabled;
  
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isAdmin => _user?.role == 'admin';
  bool get isDelivery => _user?.role == 'delivery';
  bool get isCustomer => _user?.role == 'customer' || _user == null;

  Future<void> checkAuth() async {
    await checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    try {
      _state = AuthState.loading;
      notifyListeners();
      
      _token = await TokenManager.getAccessToken();
      if (_token != null && _token!.startsWith('demo_')) {
        _user = User(id: 1, email: 'demo@demo.com', name: 'Demo User', role: 'customer', status: 'active');
        _state = AuthState.authenticated;
      } else if (_token != null) {
        final data = await _api.me();
        _user = User.fromJson(data);
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _token = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password, {bool useBiometric = false}) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    
    if (useBiometric) {
      final authenticated = await BiometricAuth.authenticateWithBiometrics(
        reason: 'Authenticate to login to OmniMarket',
      );
      if (!authenticated) {
        _state = AuthState.error;
        _error = 'Biometric authentication failed';
        notifyListeners();
        return false;
      }
    }
    
    // Try demo login first
    final demoResult = _tryDemoLogin(email, password);
    if (demoResult != null) {
      _user = demoResult;
      _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      await TokenManager.saveTokens(accessToken: _token!);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }
    
    // Try API login
    try {
      final data = await _api.login(email, password);
      _token = data['token'];
      _user = User.fromJson(data['user']);
      await TokenManager.saveTokens(
        accessToken: _token!,
        refreshToken: data['refreshToken'],
        expiresIn: Duration(seconds: data['expiresIn'] ?? 3600),
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      // If API fails and demo mode is on, use demo
      if (Config.demoMode) {
        final demoResult = _tryDemoLogin(email, password);
        if (demoResult != null) {
          _user = demoResult;
          _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
          await TokenManager.saveTokens(accessToken: _token!);
          _state = AuthState.authenticated;
          notifyListeners();
          return true;
        }
      }
      _state = AuthState.error;
      _error = 'Invalid credentials';
      notifyListeners();
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    final available = await BiometricAuth.isBiometricAvailable();
    if (!available) return false;
    
    final authenticated = await BiometricAuth.authenticateWithBiometrics(
      reason: 'Enable biometric login for OmniMarket',
    );
    
    if (authenticated) {
      _biometricEnabled = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  User? _tryDemoLogin(String email, String password) {
    final emailLower = email.toLowerCase();
    
    if (emailLower == 'customer@test.com' && password == 'password123') {
      return User(id: 1, email: email, name: 'Ahmed Hassan', phone: '+963912345678', role: 'customer', status: 'active');
    } else if (emailLower == 'driver@omnimarket.sy' && password == 'driver123') {
      return User(id: 2, email: email, name: 'Khalid Mahmoud', phone: '+963944567890', role: 'delivery', status: 'active');
    } else if (emailLower == 'admin@omnimarket.sy' && password == 'admin123') {
      return User(id: 3, email: email, name: 'Admin User', phone: '+963911111111', role: 'admin', status: 'active');
    }
    return null;
  }

  Future<bool> register(String email, String password, String name, {String? phone}) async {
    try {
      _state = AuthState.loading;
      notifyListeners();
      
      final data = await _api.register(email, password, name, phone: phone);
      _token = data['token'];
      _user = User.fromJson(data['user']);
      await TokenManager.saveTokens(
        accessToken: _token!,
        refreshToken: data['refreshToken'],
        expiresIn: Duration(seconds: data['expiresIn'] ?? 3600),
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      // Demo mode registration
      if (Config.demoMode) {
        _user = User(id: DateTime.now().millisecondsSinceEpoch, email: email, name: name, phone: phone, role: 'customer', status: 'active');
        _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
        await TokenManager.saveTokens(accessToken: _token!);
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      }
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenManager.clearTokens();
    _user = null;
    _token = null;
    _biometricEnabled = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}