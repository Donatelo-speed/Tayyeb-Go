import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_admin/core/design_system/design_system.dart' as ds;
import 'package:tayyebgo_admin/core/services/admin_firestore_service.dart';
import 'package:tayyebgo_admin/core/widgets/widgets.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class SettingsView extends StatelessWidget {
  const SettingsView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    return ResponsiveContent(
      padding: EdgeInsets.zero,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: ds.AppSpacing.lg,
          vertical: ds.AppSpacing.lg,
        ),
        children: [
          _SectionHeader(
            title: 'Settings',
            subtitle: 'Manage your account, preferences, and platform features.',
          ),
          const SizedBox(height: ds.AppSpacing.lg),
          _ProfileCard(auth: auth),
          const SizedBox(height: ds.AppSpacing.md),
          _PreferencesCard(theme: theme),
          const SizedBox(height: ds.AppSpacing.md),
          _FeatureTogglesCard(),
          const SizedBox(height: ds.AppSpacing.md),
          _AccountCard(auth: auth),
          const SizedBox(height: ds.AppSpacing.md),
          _AboutCard(),
          const SizedBox(height: ds.AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(subtitle,
            style: ds.AppTypography.caption.copyWith(color: context.textSecondaryColor)),
      ],
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
    return AdminCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(ds.AppRadius.lg),
            ),
            child: Center(
              child: Text(initials,
                  style: ds.AppTypography.number.copyWith(color: Colors.white, fontSize: 24)),
            ),
          ),
          const SizedBox(width: ds.AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(email,
                    style: ds.AppTypography.caption
                        .copyWith(color: context.textSecondaryColor)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(auth.user?.role.displayName ?? 'Super Admin',
                      style: ds.AppTypography.label.copyWith(color: context.primaryColor)),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Edit profile',
            button: true,
            child: IconButton(
              tooltip: 'Edit profile',
              icon: Icon(Icons.edit_outlined, color: context.primaryColor),
              onPressed: () => context.go('/dashboard?tab=14'),
            ),
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
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.tune, title: 'Preferences'),
          const SizedBox(height: ds.AppSpacing.sm),
          _SettingRow(
            icon: Icons.dark_mode_rounded,
            title: 'Dark mode',
            subtitle: theme.isDark ? 'Dark theme is active' : 'Light theme is active',
            trailing: Switch(
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
            ),
          ),
          const Divider(height: 1),
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
            ),
          ),
          const Divider(height: 1),
          _SettingRow(
            icon: Icons.language,
            title: 'Language',
            subtitle: AdminFirestoreService.instance.getLocalFlag('language', defaultValue: 'English (US)'),
            trailing: const Icon(Icons.chevron_right),
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
      _Flag('free_delivery', 'Free delivery', 'Allow stores to offer free delivery', Icons.local_shipping, true),
      _Flag('scheduled_orders', 'Scheduled orders', 'Customers schedule orders for later', Icons.schedule, true),
      _Flag('group_orders', 'Group orders', 'Multiple people ordering together', Icons.groups, false),
      _Flag('driver_subscriptions', 'Driver subscriptions', 'Drivers pay a monthly fee', Icons.subscriptions, false),
      _Flag('cash_on_delivery', 'Cash on delivery', 'Accept cash payments', Icons.payments, true),
      _Flag('tipping', 'Tipping', 'Customers can tip drivers', Icons.volunteer_activism, true),
      _Flag('loyalty_program', 'Loyalty program', 'Reward repeat customers', Icons.card_giftcard, false),
      _Flag('referral_system', 'Referral system', 'Customers earn for inviting friends', Icons.share, true),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.toggle_on,
            title: 'Feature toggles',
            subtitle: 'Control which features are available in customer, driver, and partner apps.',
          ),
          const SizedBox(height: ds.AppSpacing.sm),
          StreamBuilder<Map<String, dynamic>?>(
            stream: AdminFirestoreService.instance.watchFeatureFlags(),
            builder: (ctx, snap) {
              final data = snap.data ?? const <String, dynamic>{};
              return Column(
                children: [
                  for (var i = 0; i < flags.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
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
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AuthProvider auth;
  const _AccountCard({required this.auth});
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.account_circle_outlined, title: 'Account'),
          const SizedBox(height: ds.AppSpacing.sm),
          _SettingRow(
            icon: Icons.lock_outline,
            title: 'Change password',
            subtitle: 'Send a password-reset email to your account',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _sendPasswordReset(context, auth),
          ),
          const Divider(height: 1),
          _SettingRow(
            icon: Icons.logout,
            title: 'Sign out',
            subtitle: 'End your current session',
            iconColor: context.errorColor,
            trailing: TextButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              style: TextButton.styleFrom(foregroundColor: context.errorColor),
              child: const Text('Sign out'),
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
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.info_outline, title: 'About'),
          const SizedBox(height: ds.AppSpacing.sm),
          _SettingRow(
            icon: Icons.tag,
            title: 'Version',
            subtitle: 'TayyebGo Admin v2.0.0',
          ),
          const Divider(height: 1),
          _SettingRow(
            icon: Icons.description_outlined,
            title: 'Terms of service',
            subtitle: 'Read the platform terms',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPolicyPage(context, 'Terms of service', _kTermsOfService),
          ),
          const Divider(height: 1),
          _SettingRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            subtitle: 'How we handle your data',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPolicyPage(context, 'Privacy policy', _kPrivacyPolicy),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _CardTitle({required this.icon, required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ds.AppRadius.md),
          ),
          child: Icon(icon, color: context.primaryColor, size: 18),
        ),
        const SizedBox(width: ds.AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: ds.AppTypography.caption.copyWith(color: context.textSecondaryColor)),
              ],
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(ds.AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? context.textSecondaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: ds.AppTypography.bodyBold.copyWith(color: context.textPrimaryColor)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: ds.AppTypography.caption.copyWith(color: context.textMutedColor)),
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
      return SimpleDialog(
        title: const Text('Choose language'),
        children: [
          for (final l in languages)
            SimpleDialogOption(
              onPressed: () {
                AdminFirestoreService.instance.setLocalFlag('language', l.$1);
                AdminFirestoreService.instance.setLocalFlag('language_code', l.$2);
                Navigator.pop(ctx);
                context.showSuccess('Language set to ${l.$1}');
                (context as Element).markNeedsBuild();
              },
              child: Row(
                children: [
                  Icon(Icons.language, size: 18, color: context.primaryColor),
                  const SizedBox(width: 12),
                  Text(l.$1),
                ],
              ),
            ),
        ],
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
                      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55)),
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
