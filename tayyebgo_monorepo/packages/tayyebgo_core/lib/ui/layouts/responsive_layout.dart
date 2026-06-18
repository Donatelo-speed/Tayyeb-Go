import 'package:flutter/material.dart';
import '../../presentation/theme/app_breakpoints.dart';

/// Responsive layout wrapper that adapts content based on screen size.
///
/// Provides breakpoint-aware layout with mobile (single column),
/// tablet (2 columns), desktop (sidebar + content), and wide (3-4 columns).
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wide;
  final double? maxContentWidth;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
    this.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        if (w >= AppBreakpoints.wide && wide != null) return wide!;
        if (w >= AppBreakpoints.desktop && desktop != null) return desktop!;
        if (w >= AppBreakpoints.tablet && tablet != null) return tablet!;
        return mobile;
      },
    );
  }
}

/// Responsive grid that adapts column count to screen width.
class ResponsiveGrid extends StatelessWidget {
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final List<Widget> children;

  const ResponsiveGrid({
    super.key,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cols;
        if (w >= AppBreakpoints.desktop) {
          cols = desktopColumns ?? tabletColumns ?? mobileColumns;
        } else if (w >= AppBreakpoints.tablet) {
          cols = tabletColumns ?? mobileColumns;
        } else {
          cols = mobileColumns;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Consistent scroll physics for all platforms.
/// iOS gets BouncingScrollPhysics, Android gets ClampingScrollPhysics.
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics();
      default:
        return const ClampingScrollPhysics();
    }
  }
}

/// Platform-adaptive padding that respects safe area and content width.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        EdgeInsetsGeometry padding;

        if (w >= AppBreakpoints.desktop) {
          padding = desktopPadding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        } else if (w >= AppBreakpoints.tablet) {
          padding = tabletPadding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        } else {
          padding = mobilePadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        }

        return Padding(padding: padding, child: child);
      },
    );
  }
}

/// Centered content wrapper with max width for desktop layouts.
class ContentCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ContentCenter({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? AppBreakpoints.maxContentWidth(context)),
        child: child,
      ),
    );
  }
}
