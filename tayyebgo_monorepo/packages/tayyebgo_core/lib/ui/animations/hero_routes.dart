import 'package:flutter/material.dart';

/// HeroRoutes — Custom hero route transitions
class HeroFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  HeroFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class HeroSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  HeroSlideRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(
              begin: _getBegin(direction),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );

  static Offset _getBegin(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.up:
        return const Offset(0.0, 1.0);
      case SlideDirection.down:
        return const Offset(0.0, -1.0);
    }
  }
}

class HeroScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  HeroScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

class HeroSizeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  HeroSizeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return Align(
              alignment: Alignment.center,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

enum SlideDirection { left, right, up, down }
