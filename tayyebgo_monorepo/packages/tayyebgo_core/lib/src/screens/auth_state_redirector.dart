import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/user_role.dart';
import '../providers/auth_provider.dart';

/// Wraps a protected widget. Redirects to /login if not authenticated,
/// or to /access-denied if the user's role is not in [allowedRoles].
class AuthStateRedirector extends StatefulWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;

  const AuthStateRedirector({
    super.key,
    required this.child,
    this.allowedRoles,
  });

  @override
  State<AuthStateRedirector> createState() => _AuthStateRedirectorState();
}

class _AuthStateRedirectorState extends State<AuthStateRedirector> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated && !auth.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final authNow = context.read<AuthProvider>();
        if (!authNow.isAuthenticated && !authNow.isLoading) {
          context.go('/login');
        }
      });
    }

    if (auth.isAuthenticated &&
        auth.user != null &&
        widget.allowedRoles != null &&
        !widget.allowedRoles!.contains(auth.user!.role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final role = auth.user!.role.value;
        final userId = auth.user!.id;
        final required =
            widget.allowedRoles!.map((r) => r.value).join(',');
        context.go(
          '/access-denied?reason=role_mismatch&currentRole=$role&requiredRoles=$required&userId=$userId',
        );
      });
    }

    return widget.child;
  }
}
