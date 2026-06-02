import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../features/dashboard/admin_helper.dart';
import '../design_system/app_motion.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBarCommandShortcut(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? DarkAppColors.surface : Colors.white,
          border: Border(bottom: BorderSide(color: isDark ? DarkAppColors.border : AppColors.border)),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (breadcrumb != null)
                        Text(
                          breadcrumb!,
                          style: TextStyle(fontSize: 11, color: context.textMutedColor),
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
    return ElevatedButton.icon(
      onPressed: () => AdminHelper.show(context),
      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
      label: const Text('Assist'),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
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
      onPressed: () => context.push('/notifications'),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
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
