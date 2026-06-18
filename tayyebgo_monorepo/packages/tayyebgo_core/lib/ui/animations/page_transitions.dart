import 'package:flutter/material.dart';
import '../../presentation/theme/app_motion.dart';

/// Custom page route with fade + slide transition (default for all routes).
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset beginOffset;

  FadeSlidePageRoute({
    required this.page,
    this.beginOffset = const Offset(0.3, 0.0),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.easeOut,
              reverseCurve: AppMotion.easeInOut,
            );
            final slideTween = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).chain(CurveTween(curve: AppMotion.easeOut));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
          transitionDuration: AppMotion.pageTransition,
          reverseTransitionDuration: AppMotion.medium,
        );
}

/// Bottom sheet slide-up + fade transition.
class BottomSheetRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BottomSheetRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: AppMotion.easeOut));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: AppMotion.bottomSheet,
          reverseTransitionDuration: AppMotion.medium,
          barrierDismissible: true,
          opaque: false,
        );
}

/// Scale + fade transition for dialogs.
class DialogPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DialogPageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).chain(CurveTween(curve: AppMotion.spring));

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: AppMotion.dialog,
          reverseTransitionDuration: AppMotion.fast,
          barrierDismissible: true,
        );
}
