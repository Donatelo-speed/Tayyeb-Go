import 'package:flutter/material.dart';

/// Modern page transitions matching the TayyebGo design system

/// Slide from right (most common forward navigation)
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  @override
  final RouteSettings settings;

  SlideRightRoute({required this.page, String? name})
      : settings = RouteSettings(name: name),
        super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

/// Slide from bottom (modals, sheets, cart)
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  @override
  final RouteSettings settings;

  SlideUpRoute({required this.page, String? name})
      : settings = RouteSettings(name: name),
        super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Fade transition (subtle, for overlays)
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  @override
  final RouteSettings settings;

  FadeRoute({required this.page, String? name})
      : settings = RouteSettings(name: name),
        super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}

/// Scale + Fade (dialogs, featured cards)
class ScaleFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  @override
  final RouteSettings settings;

  ScaleFadeRoute({required this.page, String? name})
      : settings = RouteSettings(name: name),
        super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Shared axis transition (same-level navigation, like tab switching)
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType type;
  @override
  final RouteSettings settings;

  SharedAxisRoute({
    required this.page,
    this.type = SharedAxisTransitionType.horizontal,
    String? name,
  })  : settings = RouteSettings(name: name),
        super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final secondCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            );

            Offset getOffset(Animation<double> a, bool isForward) {
              final value = a.value;
              switch (type) {
                case SharedAxisTransitionType.horizontal:
                  return Offset(isForward ? 30.0 * (1 - value) : -30.0 * value, 0);
                case SharedAxisTransitionType.vertical:
                  return Offset(0, isForward ? 30.0 * (1 - value) : -30.0 * value);
              }
            }

            return AnimatedBuilder(
              animation: Listenable.merge([curved, secondCurved]),
              builder: (context, _) {
                final forwardOffset = getOffset(curved, true);
                final backOffset = getOffset(secondCurved, false);
                return Stack(
                  children: [
                    if (backOffset != Offset.zero)
                      Transform.translate(
                        offset: backOffset,
                        child: Opacity(
                          opacity: 1 - secondCurved.value,
                          child: child,
                        ),
                      ),
                    Transform.translate(
                      offset: forwardOffset,
                      child: Opacity(
                        opacity: curved.value,
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
}

enum SharedAxisTransitionType { horizontal, vertical }
