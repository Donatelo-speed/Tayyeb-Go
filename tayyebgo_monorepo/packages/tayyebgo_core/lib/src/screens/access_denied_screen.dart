import 'package:flutter/material.dart';
import '../theme/tayyebgo_theme.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String? role;
  final bool isDisabled;
  final VoidCallback? onGoBack;

  const AccessDeniedScreen({super.key, this.role, this.isDisabled = false, this.onGoBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isDisabled ? TayyebGoTheme.warningColor : TayyebGoTheme.errorColor).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDisabled ? Icons.person_off_outlined : Icons.lock_outline,
                  size: 64,
                  color: isDisabled ? TayyebGoTheme.warningColor : TayyebGoTheme.errorColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isDisabled ? 'Account Deactivated' : 'Access Denied',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isDisabled
                    ? 'Your account has been deactivated. You cannot sign in at this time.'
                    : (role != null
                        ? 'Your role ($role) does not have permission to access this page'
                        : 'You do not have permission to access this page'),
                style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isDisabled
                    ? 'Please contact your administrator to reactivate your account'
                    : 'Please contact your administrator if you believe this is a mistake',
                style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onGoBack != null)
                ElevatedButton.icon(
                  onPressed: onGoBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TayyebGoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
