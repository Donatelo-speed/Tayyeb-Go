import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final Map<String, _OTPCode> _codes = {};
  final int _codeLength = 6;
  final Duration _codeExpiry = const Duration(minutes: 5);
  final int _maxAttempts = 3;

  String generateCode(String phoneNumber) {
    final random = Random();
    final code = List.generate(_codeLength, (_) => random.nextInt(10).toString()).join();
    
    _codes[phoneNumber] = _OTPCode(
      code: code,
      expiresAt: DateTime.now().add(_codeExpiry),
      attempts: 0,
    );
    
    return code;
  }

  bool verifyCode(String phoneNumber, String code) {
    final otpData = _codes[phoneNumber];
    if (otpData == null) return false;

    if (DateTime.now().isAfter(otpData.expiresAt)) {
      _codes.remove(phoneNumber);
      return false;
    }

    if (otpData.attempts >= _maxAttempts) {
      _codes.remove(phoneNumber);
      return false;
    }

    if (otpData.code == code) {
      _codes.remove(phoneNumber);
      return true;
    }

    _codes[phoneNumber] = _OTPCode(
      code: otpData.code,
      expiresAt: otpData.expiresAt,
      attempts: otpData.attempts + 1,
    );

    return false;
  }

  bool hasAttemptsRemaining(String phoneNumber) {
    final otpData = _codes[phoneNumber];
    if (otpData == null) return true;
    return otpData.attempts < _maxAttempts;
  }

  int getAttemptsRemaining(String phoneNumber) {
    final otpData = _codes[phoneNumber];
    if (otpData == null) return _maxAttempts;
    return _maxAttempts - otpData.attempts;
  }

  void clearCode(String phoneNumber) {
    _codes.remove(phoneNumber);
  }
}

class _OTPCode {
  final String code;
  final DateTime expiresAt;
  final int attempts;

  _OTPCode({
    required this.code,
    required this.expiresAt,
    required this.attempts,
  });
}

class PhoneOTPPasswordReset extends StatefulWidget {
  final String? initialPhone;

  const PhoneOTPPasswordReset({super.key, this.initialPhone});

  @override
  State<PhoneOTPPasswordReset> createState() => _PhoneOTPPasswordResetState();
}

class _PhoneOTPPasswordResetState extends State<PhoneOTPPasswordReset> {
  final _otpService = OTPService();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _sendOTP() {
    if (_phoneController.text.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final code = _otpService.generateCode(_phoneController.text);
    
    // In demo mode, show the code
    // In production, this would send via SMS API
    print('Demo OTP: $code');

    setState(() {
      _step = 1;
      _isLoading = false;
      _resendCountdown = 60;
    });

    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _verifyOTP() {
    final phone = _phoneController.text;
    final code = _codeController.text;

    if (code.isEmpty) {
      setState(() => _error = 'Please enter the verification code');
      return;
    }

    final success = _otpService.verifyCode(phone, code);

    if (success) {
      setState(() {
        _step = 2;
        _error = null;
      });
    } else {
      final remaining = _otpService.getAttemptsRemaining(phone);
      if (remaining <= 0) {
        setState(() {
          _error = 'Too many attempts. Please request a new code.';
          _step = 0;
        });
      } else {
        setState(() => _error = 'Invalid code. $remaining attempts remaining.');
      }
    }
  }

  void _resetPassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    // In production, this would update the password in the backend
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step >= 0) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: _step == 0,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_step >= 1) ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  prefixIcon: Icon(Icons.pin),
                  border: const OutlineInputBorder(),
                  helperText: _resendCountdown > 0
                      ? 'Resend in $_resendCountdown seconds'
                      : 'Enter the 6-digit code sent to your phone',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_step >= 2) ...[
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],

            FilledButton(
              onPressed: _isLoading
                  ? null
                  : _step == 0
                      ? _sendOTP
                      : _step == 1
                          ? _verifyOTP
                          : _resetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(_step == 0
                      ? 'Send Code'
                      : _step == 1
                          ? 'Verify Code'
                          : 'Reset Password'),
            ),

            if (_step == 1 && _resendCountdown == 0) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _sendOTP,
                child: const Text('Resend Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}