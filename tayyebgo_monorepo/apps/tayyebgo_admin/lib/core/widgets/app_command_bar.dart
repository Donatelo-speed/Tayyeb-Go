import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../services/admin_firestore_service.dart';

class AppCommandBar extends StatefulWidget {
  const AppCommandBar({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
        child: const AppCommandBar(),
      ),
    );
  }

  @override
  State<AppCommandBar> createState() => _AppCommandBarState();
}

class _AppCommandBarState extends State<AppCommandBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  int _selectedIndex = 0;

  static const _actions = <_CommandAction>[
    _CommandAction('New Business', Icons.add_business_rounded, 'create_business', '/dashboard?tab=3&new=1'),
    _CommandAction('View Approvals', Icons.verified_outlined, 'approvals', '/dashboard?tab=1'),
    _CommandAction('View Orders', Icons.receipt_long_rounded, 'orders', '/dashboard?tab=2'),
    _CommandAction('View Stores', Icons.store_rounded, 'stores', '/dashboard?tab=3'),
    _CommandAction('View Drivers', Icons.delivery_dining, 'drivers', '/dashboard?tab=4'),
    _CommandAction('View Finance', Icons.account_balance, 'finance', '/dashboard?tab=5'),
    _CommandAction('Send Notification', Icons.notifications_active, 'notifications', '/dashboard?tab=9'),
    _CommandAction('Open Settings', Icons.settings_outlined, 'settings', '/dashboard?tab=13'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _runSearch('');
    });
  }

  Future<void> _runSearch(String q) async {
    setState(() => _loading = true);
    final results = await AdminFirestoreService.instance.searchAll(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _select(int idx) {
    if (idx < _results.length) {
      final r = _results[idx];
      Navigator.pop(context);
      if (r['type'] == 'store') {
        context.go('/dashboard?tab=3');
      } else if (r['type'] == 'driver') {
        context.go('/dashboard?tab=4');
      }
    } else {
      final actionIdx = idx - _results.length;
      if (actionIdx >= 0 && actionIdx < _actions.length) {
        Navigator.pop(context);
        context.go(_actions[actionIdx].path);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brDialog,
          boxShadow: AppShadow.elevation4(context.isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: context.textMutedColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      decoration: const InputDecoration.collapsed(hintText: 'Search stores, drivers, or run a command…'),
                      onChanged: (v) {
                        _runSearch(v);
                        setState(() => _selectedIndex = 0);
                      },
                      onSubmitted: (_) => _select(_selectedIndex),
                      style: AppTypography.body.copyWith(color: context.textPrimaryColor),
                    ),
                  ),
                  _kbd('esc'),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Flexible(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    }
    final hasResults = _results.isNotEmpty;
    final hasActions = _controller.text.isEmpty || !hasResults;
    if (!hasResults && !hasActions) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('No results for "${_controller.text}"', style: AppTypography.body.copyWith(color: context.textMutedColor))),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasResults) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('RESULTS', style: AppTypography.label.copyWith(color: context.textMutedColor)),
            ),
            ..._results.asMap().entries.map((e) => _buildResultRow(e.key, e.value)),
          ],
          if (hasActions) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('QUICK ACTIONS', style: AppTypography.label.copyWith(color: context.textMutedColor)),
            ),
            ..._actions.asMap().entries.map((e) {
              final i = _results.length + e.key;
              return _buildActionRow(i, e.value);
            }),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildResultRow(int idx, Map<String, dynamic> r) {
    final isSelected = idx == _selectedIndex;
    return InkWell(
      onTap: () => _select(idx),
      child: Container(
        color: isSelected ? context.primaryColor.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(r['type'] == 'store' ? Icons.store_rounded : Icons.delivery_dining, size: 18, color: context.textSecondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['title'] ?? '', style: AppTypography.body.copyWith(color: context.textPrimaryColor)),
                  if ((r['subtitle'] as String?)?.isNotEmpty == true)
                    Text(r['subtitle'], style: AppTypography.bodySmall.copyWith(color: context.textMutedColor)),
                ],
              ),
            ),
            _kbd('↵'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(int idx, _CommandAction a) {
    final isSelected = idx == _selectedIndex;
    return InkWell(
      onTap: () => _select(idx),
      child: Container(
        color: isSelected ? context.primaryColor.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(a.icon, size: 18, color: context.primaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(a.label, style: AppTypography.body.copyWith(color: context.textPrimaryColor))),
            _kbd('↵'),
          ],
        ),
      ),
    );
  }

  Widget _kbd(String k) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.surfaceAltColor,
        borderRadius: AppRadius.brXs,
        border: Border.all(color: context.borderColor),
      ),
      child: Text(k, style: AppTypography.labelSmall.copyWith(color: context.textMutedColor)),
    );
  }
}

class _CommandAction {
  final String label;
  final IconData icon;
  final String id;
  final String path;
  const _CommandAction(this.label, this.icon, this.id, this.path);
}

class AppCommandBarTrigger extends StatelessWidget {
  const AppCommandBarTrigger({super.key});
  @override
  Widget build(BuildContext context) {
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    return InkWell(
      onTap: () => AppCommandBar.show(context),
      borderRadius: AppRadius.brSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceAltColor,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_rounded, size: 14, color: context.textMutedColor),
          const SizedBox(width: 6),
          Text('Search', style: AppTypography.caption.copyWith(color: context.textMutedColor)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.brXs,
              border: Border.all(color: context.borderColor),
            ),
            child: Text(isMac ? '⌘K' : 'Ctrl K', style: AppTypography.labelSmall.copyWith(color: context.textMutedColor)),
          ),
        ]),
      ),
    );
  }
}

class AppCommandBarHotkey extends StatelessWidget {
  final Widget child;
  const AppCommandBarHotkey({super.key, required this.child});

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
