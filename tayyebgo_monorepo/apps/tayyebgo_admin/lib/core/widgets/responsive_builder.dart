import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

enum AppLayout { mobile, tablet, desktop, wide }

extension AppLayoutX on AppLayout {
  bool get isMobile => this == AppLayout.mobile;
  bool get isTablet => this == AppLayout.tablet;
  bool get isDesktop => this == AppLayout.desktop || this == AppLayout.wide;
  bool get isWide => this == AppLayout.wide;

  /// Max content width on this layout. Beyond this we center content.
  double get contentMaxWidth {
    switch (this) {
      case AppLayout.mobile:
        return double.infinity;
      case AppLayout.tablet:
        return 1024;
      case AppLayout.desktop:
        return 1280;
      case AppLayout.wide:
        return 1440;
    }
  }

  /// Standard horizontal page padding for the layout.
  double get pagePadding {
    switch (this) {
      case AppLayout.mobile:
        return 16;
      case AppLayout.tablet:
        return 24;
      case AppLayout.desktop:
        return 32;
      case AppLayout.wide:
        return 40;
    }
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppLayout layout) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final layout = AppBreakpoints.isMobile(c.maxWidth)
            ? AppLayout.mobile
            : AppBreakpoints.isTablet(c.maxWidth)
                ? AppLayout.tablet
                : AppBreakpoints.isWide(c.maxWidth)
                    ? AppLayout.wide
                    : AppLayout.desktop;
        return builder(context, layout);
      },
    );
  }
}

/// Wraps any child in a horizontally-centered, max-width container
/// appropriate for the current layout. Use for content that should not
/// stretch indefinitely on wide screens (tables, forms, lists).
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const ResponsiveContent({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (ctx, layout) {
        final maxWidth = layout.contentMaxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth == double.infinity ? double.infinity : maxWidth),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: layout.pagePadding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
