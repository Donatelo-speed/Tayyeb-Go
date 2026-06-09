import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../src/providers/auth_provider.dart';
import '../../src/screens/access_denied_screen.dart';
import '../shared_widgets/slide_transition.dart';

abstract class AppRouter {
  static GlobalKey<NavigatorState> routerKey = GlobalKey<NavigatorState>();

  static GoRoute route(String path, Widget child, {String? name}) {
    return GoRoute(
      path: path,
      name: name,
      pageBuilder: (_, state) =>
          SlideTransitionPage(key: state.pageKey, page: child),
    );
  }

  static GoRouter create({
    required List<RouteBase> routes,
    required Listenable refreshListenable,
    required String? Function(BuildContext, GoRouterState) redirect,
    String initialLocation = '/login',
  }) {
    return GoRouter(
      navigatorKey: routerKey,
      initialLocation: initialLocation,
      refreshListenable: refreshListenable,
      redirect: redirect,
      routes: [
        ...routes,
        GoRoute(
          path: '/access-denied',
          name: 'access-denied',
          pageBuilder: (_, state) {
            final reason = state.uri.queryParameters['reason'];
            return SlideTransitionPage(
              key: state.pageKey,
              page: AccessDeniedScreen(
                isDisabled: reason == 'disabled',
                onGoBack: () {
                  final context = routerKey.currentContext;
                  if (context != null && context.mounted) {
                    context.read<AuthProvider>().logout();
                    GoRouter.of(context).go('/login');
                  }
                },
              ),
            );
          },
        ),
      ],
      errorBuilder: (_, state) => _ErrorScreen(state.error),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen(this.error);
  @override
  Widget build(BuildContext context) {
    final isRouteError = error == null;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isRouteError ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isRouteError ? 'Page Not Found' : 'Something went wrong',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Something went wrong.\nPlease sign in with the correct account for this app.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
