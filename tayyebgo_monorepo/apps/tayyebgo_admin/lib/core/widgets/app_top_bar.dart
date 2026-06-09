import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../features/dashboard/admin_helper.dart';
import 'app_command_bar.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? breadcrumb;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final bool showSearch;
  final bool showCommandBar;
  final bool showAssist;

  const AppTopBar({
    super.key,
    required this.title,
    this.breadcrumb,
    this.actions,
    this.onBack,
    this.onMenu,
    this.showSearch = true,
    this.showCommandBar = true,
    this.showAssist = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBarCommandShortcut(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(bottom: BorderSide(color: context.borderColor)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (onMenu != null) ...[
                  _IconAction(icon: Icons.menu_rounded, tooltip: 'Toggle sidebar', onPressed: onMenu!),
                  const SizedBox(width: 4),
                ],
                if (onBack != null) ...[
                  _IconAction(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () {
                    if (onBack != null) {
                      onBack!();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  }),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: Text(
                          title,
                          key: ValueKey(title),
                          style: AppTypography.titleLarge.copyWith(
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (breadcrumb != null)
                        Text(
                          breadcrumb!,
                          style: AppTypography.labelSmall.copyWith(color: context.textMutedColor),
                        ),
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
                if (showCommandBar) ...[
                  const SizedBox(width: 8),
                  const AppCommandBarTrigger(),
                ],
                if (showAssist) ...[
                  const SizedBox(width: 8),
                  _AssistButton(),
                ],
                const SizedBox(width: 4),
                const _ThemeToggle(),
                const SizedBox(width: 4),
                const _NotificationBell(),
                const SizedBox(width: 4),
                const _ProfileAvatar(),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _IconAction({required this.icon, required this.tooltip, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      color: context.textSecondaryColor,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AssistButton extends StatelessWidget {
  const _AssistButton();
  @override
  Widget build(BuildContext context) {
    return TGB(
      label: 'Assist',
      onPressed: () => AdminHelper.show(context),
      icon: Icons.auto_awesome_rounded,
      variant: TGBVariant.primary,
      isExpanded: false,
      height: 36,
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return _IconAction(
      icon: theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      tooltip: theme.isDark ? 'Light mode' : 'Dark mode',
      onPressed: () => context.read<ThemeProvider>().toggle(),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();
  @override
  Widget build(BuildContext context) {
    return _IconAction(
      icon: Icons.notifications_outlined,
      tooltip: 'Notifications',
      onPressed: () => context.go('/dashboard?tab=9'),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = (auth.user?.displayName ?? auth.user?.email ?? 'A').characters.first.toUpperCase();
    return InkWell(
      onTap: () => context.go('/dashboard?tab=14'),
      borderRadius: AppRadius.brAvatar,
      child: TGAvatar(
        initials: initial,
        size: TGAvatarSize.sm,
        backgroundColor: context.primaryColor,
      ),
    );
  }
}

class AppBarCommandShortcut extends StatelessWidget {
  final Widget child;
  const AppBarCommandShortcut({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _OpenCommandIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _OpenCommandIntent(),
      },
      child: Actions(
        actions: {
          _OpenCommandIntent: CallbackAction<_OpenCommandIntent>(onInvoke: (_) {
            AppCommandBar.show(context);
            return null;
          }),
        },
        child: Focus(autofocus: false, child: child),
      ),
    );
  }
}

class _OpenCommandIntent extends Intent {
  const _OpenCommandIntent();
}
