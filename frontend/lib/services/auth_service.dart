import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Map<String, dynamic> _currentUser = {};
  bool _isGuestMode = false;
  List<Map<String, dynamic>> _sessions = [];

  // Auth Methods
  static const String METHOD_EMAIL = 'email';
  static const String METHOD_GOOGLE = 'google';
  static const String METHOD_APPLE = 'apple';
  static const String METHOD_PHONE = 'phone';
  static const String METHOD_BIOMETRIC = 'biometric';

  // ==================== SOCIAL LOGIN ====================
  Future<Map<String, dynamic>> signInWithGoogle() async {
    // In production: use google_sign_in package
    // Implementation: Launch Google Sign-In flow -> Get ID token -> Verify with backend
    
    // Demo: Simulate successful Google login
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser.addAll({
      'id': 1,
      'email': 'user@gmail.com',
      'name': 'Ahmed Google',
      'photoUrl': 'https://lh3.googleusercontent.com/a/default user',
      'authMethod': METHOD_GOOGLE,
      'isSetupComplete': true,
      'role': 'customer',
    });
    
    _addSession(METHOD_GOOGLE);
    return {'success': true, 'user': _currentUser};
  }

  Future<Map<String, dynamic>> signInWithApple() async {
    // In production: use sign_in_with_apple package
    // iOS-only: Requires Apple Developer configured
    
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser.addAll({
      'id': 2,
      'email': 'user@icloud.com',
      'name': 'Ahmed Apple',
      'photoUrl': 'https://developer.apple.com/assets/elements/icons/sign-in-with-apple.svg',
      'authMethod': METHOD_APPLE,
      'isSetupComplete': true,
      'role': 'customer',
    });
    
    _addSession(METHOD_APPLE);
    return {'success': true, 'user': _currentUser};
  }

  // ==================== EMAIL/PASSWORD ====================
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    // Password validation
    if (password.length < 8) {
      HapticFeedback.heavyImpact();
      return {'success': false, 'error': 'Password must be at least 8 characters'};
    }

    // Check if account already exists with different method
    final existingUser = await _findExistingUser(email);
    if (existingUser != null) {
      // Smart Account Linking
      if (existingUser['authMethod'] != METHOD_EMAIL) {
        // Link new login method to existing account
        return await _linkAccount(existingUser, METHOD_EMAIL);
      }
      return {'success': false, 'error': 'Account already exists. Please login.'};
    }

    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));

    _currentUser.addAll({
      'id': DateTime.now().millisecondsSinceEpoch,
      'email': email,
      'fullName': name,
      'phone': phone,
      'authMethod': METHOD_EMAIL,
      'isSetupComplete': true,
      'role': 'customer',
      'createdAt': DateTime.now().toIso8601String(),
    });

    _addSession(METHOD_EMAIL);
    return {'success': true, 'user': _currentUser, 'isNewUser': true};
  }

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Apply rate limiting check here (via backend in production)
    
    if (password.length < 6) {
      HapticFeedback.heavyImpact();
      return {'success': false, 'error': 'Invalid credentials'};
    }

    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));

    _currentUser.addAll({
      'id': 3,
      'email': email,
      'fullName': 'Ahmed Customer',
      'authMethod': METHOD_EMAIL,
      'isSetupComplete': true,
      'role': 'customer',
    });

    _addSession(METHOD_EMAIL);
    return {'success': true, 'user': _currentUser};
  }

  // ==================== PHONE/OTP ====================
  String? _pendingPhone;
  String? _otpCode;
  int _otpAttempts = 0;

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    // In production: Use Firebase Phone Auth or Twilio
    // Generate 6-digit code
    _otpCode = (DateTime.now().millisecondsSinceEpoch % 900000 + 100000).toString();
    _pendingPhone = phone;
    _otpAttempts = 0;

    // Demo: Log the code
    print('[OTP] Code sent to $phone: $_otpCode');

    HapticFeedback.mediumImpact();
    return {'success': true, 'message': 'OTP sent successfully'};
  }

  Future<Map<String, dynamic>> verifyOTP(String code) async {
    // Rate limit check
    _otpAttempts++;
    if (_otpAttempts > 3) {
      HapticFeedback.heavyImpact();
      return {'success': false, 'error': 'Too many attempts. Please request a new code.'};
    }

    if (code != _otpCode) {
      HapticFeedback.heavyImpact();
      return {'success': false, 'error': 'Invalid OTP code'};
    }

    HapticFeedback.mediumImpact();
    _currentUser.addAll({
      'id': 4,
      'phone': _pendingPhone,
      'authMethod': METHOD_PHONE,
      'isSetupComplete': false,
      'role': 'customer',
    });

    _addSession(METHOD_PHONE);
    _otpCode = null;
    return {'success': true, 'user': _currentUser};
  }

  Future<Map<String, dynamic>> sendVoiceOTP(String phone) async {
    // In production: Use Twilio Voice API for automated call
    // This reads out the OTP code via voice
    
    print('[VoiceOTP] Calling $phone...');
    HapticFeedback.mediumImpact();
    return {'success': true, 'message': 'Automated call initiated'};
  }

  // ==================== BIOMETRIC ====================
  Future<Map<String, dynamic>> authenticateWithBiometric() async {
    // Uses local_auth package - implemented in biometric_auth.dart
    
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser.addAll({
      'id': 5,
      'email': 'biometric@example.com',
      'fullName': 'Ahmed Bio',
      'authMethod': METHOD_BIOMETRIC,
      'isSetupComplete': true,
      'role': 'customer',
    });

    _addSession(METHOD_BIOMETRIC);
    return {'success': true, 'user': _currentUser};
  }

  // ==================== SMART ACCOUNT LINKING ====================
  Future<Map<String, dynamic>?> _findExistingUser(String email) async {
    // In production: Query database to find user by email
    // Check linked accounts
    
    // Demo: Return null (no existing account)
    return null;
  }

  Future<Map<String, dynamic>> _linkAccount(Map<String, dynamic> existingUser, String newMethod) async {
    // Smart linking: Link new login method to existing account
    // Instead of creating duplicate accounts
    
    HapticFeedback.mediumImpact();
    
    // Update user's auth methods
    final linkedMethods = List<String>.from(existingUser['linkedMethods'] ?? [existingUser['authMethod']]);
    linkedMethods.add(newMethod);
    
    _currentUser.addAll({
      ...existingUser,
      'authMethod': newMethod,
      'linkedMethods': linkedMethods,
    });

    _addSession(newMethod);
    return {'success': true, 'user': _currentUser, 'linked': true};
  }

  // ==================== GUEST MODE ====================
  Future<Map<String, dynamic>> enableGuestMode() async {
    _isGuestMode = true;
    HapticFeedback.lightImpact();
    
    return {
      'success': true,
      'isGuest': true,
      'user': {
        'id': 0,
        'name': 'Guest',
        'isGuestMode': true,
      }
    };
  }

  Future<Map<String, dynamic>> convertGuestToUser(Map<String, dynamic> userData) async {
    // Convert guest account to registered user
    _isGuestMode = false;
    
    _currentUser.addAll({
      ...userData,
      'isGuestMode': false,
    });
    
    HapticFeedback.mediumImpact();
    return {'success': true, 'user': _currentUser};
  }

  // ==================== SESSION MANAGEMENT ====================
  void _addSession(String method) {
    _sessions.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': method,
      'device': _getDeviceInfo(),
      'ip': '192.168.1.${DateTime.now().second % 255}',
      'createdAt': DateTime.now().toIso8601String(),
      'current': true,
    });
  }

  String _getDeviceInfo() {
    // In production: Use device_info_plus
    return 'Mobile Device';
  }

  List<Map<String, dynamic>> getSessions() => _sessions;

  Future<void> logoutSession(int sessionId) async {
    _sessions.removeWhere((s) => s['id'] == sessionId);
    HapticFeedback.mediumImpact();
  }

  Future<void> logoutAllOtherSessions() async {
    _sessions = _sessions.where((s) => s['current'] == true).toList();
    HapticFeedback.heavyImpact();
  }

  // ==================== CURRENT USER ====================
  Map<String, dynamic> getCurrentUser() => _currentUser;
  bool get isAuthenticated => _currentUser.isNotEmpty;
  bool get isGuest() => _isGuestMode;
  String? get currentRole => _currentUser['role']?.toString();
  bool get isAdmin => currentRole == 'admin';
  bool get isDelivery => currentRole == 'delivery';
  bool get isCustomer => currentRole == 'customer';

  Future<void> logout() async {
    // Mark current session as closed
    if (_sessions.isNotEmpty) {
      final currentIndex = _sessions.length - 1;
      _sessions[currentIndex] = {..._sessions[currentIndex], 'current': false};
    }
    
    _currentUser.clear();
    _isGuestMode = false;
    HapticFeedback.mediumImpact();
  }
}