import 'package:flutter/material.dart';
import '../design/design.dart';

class AdminLoadingState extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const AdminLoadingState({super.key, this.itemCount = 8, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      itemCount: itemCount,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
        child: _ShimmerBlock(isDark: isDark, height: itemHeight),
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final bool isDark;
  final double height;
  const _ShimmerBlock({required this.isDark, required this.height});
  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          gradient: LinearGradient(
            colors: [
              AdminColors.skeleton(widget.isDark),
              AdminColors.skeletonShine(widget.isDark),
              AdminColors.skeleton(widget.isDark),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1 + _ctrl.value * 2, 0),
            end: Alignment(1 + _ctrl.value * 2, 0),
          ),
        ),
      ),
    );
  }
}

class AdminSkeletonCard extends StatelessWidget {
  final bool isDark;
  const AdminSkeletonCard({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ShimmerBlock(isDark: isDark, height: 32),
        const SizedBox(height: AdminSpacing.lg),
        Row(children: List.generate(4, (_) => Expanded(child: Padding(
          padding: const EdgeInsets.only(right: AdminSpacing.md),
          child: _ShimmerBlock(isDark: isDark, height: 120),
        )))),
        const SizedBox(height: AdminSpacing.xxl),
        _ShimmerBlock(isDark: isDark, height: 24),
        const SizedBox(height: AdminSpacing.lg),
        Expanded(child: _ShimmerBlock(isDark: isDark, height: double.infinity)),
      ]),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AdminErrorState({super.key, this.message = 'Failed to load data', this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            decoration: BoxDecoration(color: AdminColors.dangerBg, borderRadius: BorderRadius.circular(AdminRadius.full)),
            child: const Icon(Icons.error_outline_rounded, color: AdminColors.danger, size: 32),
          ),
          const SizedBox(height: AdminSpacing.lg),
          Text('Something went wrong', style: AdminTypography.h3(isDark)),
          const SizedBox(height: AdminSpacing.sm),
          Text(message, style: AdminTypography.bodySmall(isDark), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AdminSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ]),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(AdminSpacing.xl),
            decoration: BoxDecoration(
              color: isDark ? AdminColors.darkCardHover : AdminColors.lightSurface,
              borderRadius: BorderRadius.circular(AdminRadius.xxl),
            ),
            child: Icon(icon, size: 48, color: AdminColors.textMuted(isDark)),
          ),
          const SizedBox(height: AdminSpacing.xl),
          Text(title, style: AdminTypography.h3(isDark)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.sm),
            Text(subtitle, style: AdminTypography.bodySmall(isDark), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AdminSpacing.xl),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ]),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? countLabel;
  final String searchHint;
  final String addLabel;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onSearch;
  final List<Widget>? filterChips;
  final List<Widget>? actions;
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.countLabel,
    this.searchHint = 'Search...',
    this.addLabel = 'Create',
    this.onAdd,
    this.onSearch,
    this.filterChips,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: EdgeInsets.fromLTRB(AdminSpacing.xl, AdminSpacing.lg, AdminSpacing.xl, AdminSpacing.md),
      decoration: BoxDecoration(
        color: AdminColors.card(isDark),
        border: Border(bottom: BorderSide(color: AdminColors.border(isDark))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isMobile) ...[
          Row(children: [
            Expanded(child: Text(title, style: AdminTypography.h2(isDark))),
            if (onAdd != null)
              ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 18), label: Text(addLabel)),
          ]),
          const SizedBox(height: AdminSpacing.md),
          if (onSearch != null)
            SizedBox(height: 40, child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            )),
          if (filterChips != null) ...[
            const SizedBox(height: AdminSpacing.sm),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: filterChips!)),
          ],
        ] else Row(children: [
          Text(title, style: AdminTypography.h2(isDark)),
          if (count != null) ...[
            const SizedBox(width: AdminSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AdminColors.primaryBg, borderRadius: BorderRadius.circular(AdminRadius.full)),
              child: Text(countLabel ?? count.toString(), style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
          if (filterChips != null) ...[
            const SizedBox(width: AdminSpacing.lg),
            ...filterChips!,
          ],
          const Spacer(),
          if (actions != null) ...actions!,
          if (onSearch != null) ...[
            SizedBox(width: 200, child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            )),
            const SizedBox(width: AdminSpacing.sm),
          ],
          if (onAdd != null)
            ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 18), label: Text(addLabel)),
        ]),
      ]),
    );
  }
}

class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool danger;
  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xl)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: danger ? AdminColors.danger : AdminColors.primary),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class AdminBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;
  const AdminBadge({super.key, required this.label, required this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (bgColor ?? color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminRadius.full),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  final String status;
  const AdminStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.statusColor(status);
    return AdminBadge(label: status.replaceAll('_', ' ').toUpperCase(), color: c);
  }
}

class AdminKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? change;
  final bool positive;
  const AdminKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      decoration: cardDecoration(isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(AdminSpacing.sm),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.md)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          if (change != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: positive ? AdminColors.success : AdminColors.danger),
              const SizedBox(width: 2),
              Text(change!, style: AdminTypography.caption(isDark)),
            ]),
        ]),
        const SizedBox(height: AdminSpacing.lg),
        Text(value, style: AdminTypography.kpiValue(isDark)),
        const SizedBox(height: AdminSpacing.xs),
        Text(label, style: AdminTypography.kpiLabel(isDark)),
      ]),
    );
  }
}

String timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

const List<String> businessTypes = [
  'Restaurant', 'Cafe', 'Bakery', 'Market', 'Supermarket',
  'Pharmacy', 'Electronics', 'Flower Shop', 'Pet Store', 'Courier Partner',
];

const List<String> deliveryModes = ['platform', 'store', 'hybrid'];