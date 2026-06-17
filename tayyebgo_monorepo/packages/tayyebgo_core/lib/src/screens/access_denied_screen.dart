import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../theme/tayyebgo_theme.dart';

class AccessDeniedScreen extends StatefulWidget {
  final String? currentRole;
  final String? requiredRoles;
  final String? userId;
  final bool isDisabled;
  final VoidCallback? onGoBack;

  const AccessDeniedScreen({
    super.key,
    this.currentRole,
    this.requiredRoles,
    this.userId,
    this.isDisabled = false,
    this.onGoBack,
  });

  @override
  State<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends State<AccessDeniedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TayyebGoTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (widget.isDisabled
                          ? TayyebGoTheme.warningColor
                          : TayyebGoTheme.errorColor)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isDisabled
                      ? Icons.person_off_outlined
                      : Icons.swap_horiz_rounded,
                  size: 64,
                  color: widget.isDisabled
                      ? TayyebGoTheme.warningColor
                      : TayyebGoTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isDisabled ? 'Account Deactivated' : 'Wrong App',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TayyebGoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isDisabled
                    ? 'Your account has been deactivated.\nYou cannot sign in at this time.'
                    : 'Your account (${widget.currentRole ?? 'unknown'}) has access to a different app.\nPlease open the correct app for your role.',
                style: GoogleFonts.inter(
                  color: TayyebGoTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _RoleInfoCard(
                currentRole: widget.currentRole,
                requiredRoles: widget.requiredRoles,
                userId: widget.userId,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isDisabled
                    ? 'Please contact your administrator to reactivate your account.'
                    : 'Sign out and open the ${_appNameForRole(widget.currentRole)} instead.',
                style: GoogleFonts.inter(
                  color: TayyebGoTheme.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  auth.logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text('Sign Out & Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TayyebGoTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _appNameForRole(String? role) {
    switch (role) {
      case 'superAdmin':
        return 'Admin App';
      case 'restaurantOwner':
      case 'cashier':
        return 'Partner App';
      case 'driver':
        return 'Driver App';
      case 'customer':
        return 'Customer App';
      default:
        return 'Login';
    }
  }
}

class _RoleInfoCard extends StatelessWidget {
  final String? currentRole;
  final String? requiredRoles;
  final String? userId;

  const _RoleInfoCard({
    this.currentRole,
    this.requiredRoles,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: TayyebGoTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Your Role',
            value: currentRole ?? 'unknown',
            valueColor: TayyebGoTheme.errorColor,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.lock_outline,
            label: 'Required',
            value: requiredRoles ?? 'unknown',
            valueColor: TayyebGoTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.fingerprint,
            label: 'User ID',
            value: userId ?? 'unknown',
            valueColor: TayyebGoTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: TayyebGoTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: TayyebGoTheme.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
