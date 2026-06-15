import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_admin/core/services/admin_firestore_service.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class SettingsView extends StatelessWidget {
  const SettingsView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor)),
            const SizedBox(height: 4),
            Text('Manage your account, preferences, and platform features.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
            const SizedBox(height: 24),
            _ProfileCard(auth: auth),
            const SizedBox(height: 16),
            _PreferencesCard(theme: theme),
            const SizedBox(height: 16),
            _FeatureTogglesCard(),
            const SizedBox(height: 16),
            _AccountCard(auth: auth),
            const SizedBox(height: 16),
            _AboutCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AuthProvider auth;
  const _ProfileCard({required this.auth});
  @override
  Widget build(BuildContext context) {
    final name = auth.user?.displayName ?? 'Admin';
    final email = auth.user?.email ?? 'admin@tayyebgo.com';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: context.textPrimaryColor)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(auth.user?.role.displayName ?? 'Super Admin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: context.primaryColor)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            icon: Icon(Icons.edit_outlined, color: context.primaryColor),
            onPressed: () => context.go('/dashboard?tab=14'),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final ThemeProvider theme;
  const _PreferencesCard({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Preferences', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          _SettingRow(
            icon: Icons.dark_mode_rounded,
            title: 'Dark mode',
            subtitle: theme.isDark ? 'Dark theme is active' : 'Light theme is active',
            trailing: Switch(
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
              activeColor: context.primaryColor,
            ),
          ),
          Divider(height: 1, color: context.borderColor),
          _SettingRow(
            icon: Icons.notifications_outlined,
            title: 'Push notifications',
            subtitle: 'Receive admin alerts on this device',
            trailing: Switch(
              value: AdminFirestoreService.instance.getLocalFlag('push_notifications', defaultValue: true),
              onChanged: (v) {
                AdminFirestoreService.instance.setLocalFlag('push_notifications', v);
                (context as Element).markNeedsBuild();
                if (v) {
                  context.showSuccess('Admin alerts enabled');
                } else {
                  context.showInfo('Admin alerts muted on this device');
                }
              },
              activeColor: context.primaryColor,
            ),
          ),
          Divider(height: 1, color: context.borderColor),
          _SettingRow(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: AdminFirestoreService.instance.getLocalFlag('language', defaultValue: 'English (US)'),
            trailing: Icon(Icons.chevron_right, color: context.textMutedColor),
            onTap: () => _showLanguagePicker(context),
          ),
        ],
      ),
    );
  }
}

class _FeatureTogglesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final flags = const [
      _Flag('free_delivery', 'Free delivery', 'Allow stores to offer free delivery', Icons.local_shipping_rounded, true),
      _Flag('scheduled_orders', 'Scheduled orders', 'Customers schedule orders for later', Icons.schedule_rounded, true),
      _Flag('group_orders', 'Group orders', 'Multiple people ordering together', Icons.groups_rounded, false),
      _Flag('driver_subscriptions', 'Driver subscriptions', 'Drivers pay a monthly fee', Icons.subscriptions_rounded, false),
      _Flag('cash_on_delivery', 'Cash on delivery', 'Accept cash payments', Icons.payments_rounded, true),
      _Flag('tipping', 'Tipping', 'Customers can tip drivers', Icons.volunteer_activism_rounded, true),
      _Flag('loyalty_program', 'Loyalty program', 'Reward repeat customers', Icons.card_giftcard_rounded, false),
      _Flag('referral_system', 'Referral system', 'Customers earn for inviting friends', Icons.share_rounded, true),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.toggle_on_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feature toggles', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
                    Text('Control features across all apps', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<Map<String, dynamic>?>(
            stream: AdminFirestoreService.instance.watchFeatureFlags(),
            builder: (ctx, snap) {
              final data = snap.data ?? const <String, dynamic>{};
              return Column(
                children: [
                  for (var i = 0; i < flags.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: context.borderColor),
                    _FeatureToggleRow(
                      flag: flags[i],
                      value: data[flags[i].key] as bool? ?? flags[i].defaultValue,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Flag {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool defaultValue;
  const _Flag(this.key, this.title, this.subtitle, this.icon, this.defaultValue);
}

class _FeatureToggleRow extends StatelessWidget {
  final _Flag flag;
  final bool value;
  const _FeatureToggleRow({required this.flag, required this.value});
  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      icon: flag.icon,
      title: flag.title,
      subtitle: flag.subtitle,
      trailing: Switch(
        value: value,
        onChanged: (v) async {
          await AdminFirestoreService.instance.updateFeatureFlag(flag.key, v);
        },
        activeColor: context.primaryColor,
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AuthProvider auth;
  const _AccountCard({required this.auth});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle_outlined, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          _SettingRow(
            icon: Icons.lock_outline_rounded,
            title: 'Change password',
            subtitle: 'Send a password-reset email to your account',
            trailing: Icon(Icons.chevron_right, color: context.textMutedColor),
            onTap: () => _sendPasswordReset(context, auth),
          ),
          Divider(height: 1, color: context.borderColor),
          _SettingRow(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'End your current session',
            iconColor: context.errorColor,
            trailing: TextButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              child: Text('Sign out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.errorColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('About', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          _SettingRow(
            icon: Icons.tag_rounded,
            title: 'Version',
            subtitle: 'TayyebGo Admin v2.0.0',
          ),
          Divider(height: 1, color: context.borderColor),
          _SettingRow(
            icon: Icons.description_outlined,
            title: 'Terms of service',
            subtitle: 'Read the platform terms',
            trailing: Icon(Icons.chevron_right, color: context.textMutedColor),
            onTap: () => _showPolicyPage(context, 'Terms of service', _kTermsOfService),
          ),
          Divider(height: 1, color: context.borderColor),
          _SettingRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            subtitle: 'How we handle your data',
            trailing: Icon(Icons.chevron_right, color: context.textMutedColor),
            onTap: () => _showPolicyPage(context, 'Privacy policy', _kPrivacyPolicy),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title — $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? context.textMutedColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context) {
  const languages = <(String, String)>[
    ('English (US)', 'en'),
    ('English (UK)', 'en-gb'),
    ('العربية', 'ar'),
    ('Türkçe', 'tr'),
    ('Français', 'fr'),
  ];
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Choose language', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((l) => ListTile(
            leading: Icon(Icons.language_rounded, color: context.primaryColor),
            title: Text(l.$1, style: GoogleFonts.inter(color: context.textPrimaryColor)),
            onTap: () {
              AdminFirestoreService.instance.setLocalFlag('language', l.$1);
              AdminFirestoreService.instance.setLocalFlag('language_code', l.$2);
              Navigator.pop(ctx);
              context.showSuccess('Language set to ${l.$1}');
              (context as Element).markNeedsBuild();
            },
          )).toList(),
        ),
      );
    },
  );
}

Future<void> _sendPasswordReset(BuildContext context, AuthProvider auth) async {
  final email = auth.user?.email;
  if (email == null || email.isEmpty) {
    if (context.mounted) context.showError('No email on file for this account');
    return;
  }
  if (!context.mounted) return;
  final ok = await context.confirmAction(
    title: 'Send password reset?',
    message: 'We will email a password-reset link to:\n\n$email',
    confirmLabel: 'Send email',
  );
  if (!ok) return;
  await auth.resetPassword(email);
  if (context.mounted) {
    if (auth.error != null) {
      context.showError(auth.error!);
    } else {
      context.showSuccess('Password-reset email sent to $email');
    }
  }
}

void _showPolicyPage(BuildContext context, String title, String body) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: context.surfaceColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: Icon(Icons.close, color: context.textMutedColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(body, style: GoogleFonts.inter(fontSize: 13.5, height: 1.55, color: context.textSecondaryColor)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

const String _kTermsOfService = '''
Last updated: January 2026

1. ACCEPTANCE OF TERMS
By accessing or using TayyebGo's admin panel, you agree to be bound by these Terms of Service.

2. ADMIN RESPONSIBILITIES
As an authorized administrator, you will:
  • Use the platform only for legitimate business operations.
  • Protect the confidentiality of customer, driver, and store data.
  • Comply with all applicable local laws and regulations.

3. PROHIBITED ACTIVITIES
You may not:
  • Access accounts or data you are not authorized to view.
  • Modify platform pricing, commissions, or payouts without approval.
  • Share administrative credentials with unauthorized parties.

4. DATA HANDLING
All data processed through the platform is governed by our Privacy Policy. You agree to handle such data in accordance with applicable data-protection laws.

5. TERMINATION
TayyebGo may suspend or terminate admin access for violations of these terms.

6. CHANGES
We may update these terms from time to time. Continued use of the admin panel after changes constitutes acceptance of the new terms.

For the full legal text, contact legal@tayyebgo.com.
''';

const String _kPrivacyPolicy = '''
Last updated: January 2026

1. INFORMATION WE COLLECT
  • Account information (name, email, role).
  • Activity logs of admin actions performed in the panel.
  • Authentication and device information.

2. HOW WE USE INFORMATION
  • To operate, secure, and improve the platform.
  • To investigate and prevent fraud, abuse, and policy violations.
  • To comply with legal obligations.

3. DATA SHARING
We do not sell personal data. We share data only with:
  • Service providers that help us operate the platform (e.g. Firebase, Stripe).
  • Law-enforcement or regulators when legally required.

4. YOUR RIGHTS
Subject to local law, you may request access to, correction of, or deletion of your personal data by contacting privacy@tayyebgo.com.

5. RETENTION
We retain admin action logs for a minimum of 18 months for security and compliance purposes.

6. CONTACT
For privacy questions: privacy@tayyebgo.com.
''';
