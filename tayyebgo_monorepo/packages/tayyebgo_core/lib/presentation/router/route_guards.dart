import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/enums/user_role.dart';
import '../../src/providers/auth_provider.dart';

String roleHomePath(UserRole role) {
  return switch (role) {
    UserRole.superAdmin => '/dashboard',
    UserRole.restaurantOwner || UserRole.cashier => '/dashboard',
    UserRole.driver => '/dashboard',
    UserRole.customer => '/home',
  };
}

/// Builds the access-denied redirect URL with full role context.
String _accessDeniedRedirect({
  required String reason,
  required AuthProvider auth,
  required List<UserRole> allowedRoles,
}) {
  final currentRole = auth.user?.role.value ?? 'unknown';
  final userId = auth.user?.id ?? 'unknown';
  final required = allowedRoles.map((r) => r.value).join(',');
  return '/access-denied?reason=$reason&currentRole=$currentRole&requiredRoles=$required&userId=$userId';
}

String? appRedirect({
  required String location,
  required List<UserRole> allowedRoles,
  AuthProvider? auth,
  bool onboardingComplete = true,
}) {
  final fbUser = fb.FirebaseAuth.instance.currentUser;
  final isLoggedIn = fbUser != null;

  debugPrint('[appRedirect] location=$location isLoggedIn=$isLoggedIn auth.isLoading=${auth?.isLoading} auth.user=${auth?.user?.role.value ?? "null"} allowedRoles=${allowedRoles.map((r)=>r.value).join(",")}');

  if (location == '/onboarding') {
    if (onboardingComplete) return '/login';
    return null;
  }

  if (location == '/login') {
    if (!isLoggedIn) {
      if (!onboardingComplete) return '/onboarding';
      return null;
    }
    if (auth == null || auth.isLoading) return null;
    if (auth.user != null) {
      if (!auth.user!.isActive) {
        return _accessDeniedRedirect(
          reason: 'disabled',
          auth: auth,
          allowedRoles: allowedRoles,
        );
      }
      if (!allowedRoles.contains(auth.user!.role)) {
        return _accessDeniedRedirect(
          reason: 'role_mismatch',
          auth: auth,
          allowedRoles: allowedRoles,
        );
      }
      final home = roleHomePath(auth.user!.role);
      debugPrint('[appRedirect] /login → redirecting to $home (role=${auth.user!.role.value})');
      return home;
    }
    return null;
  }

  if (location == '/splash') return null;

  if (location == '/forgot-password') return null;

  if (location == '/signup') return null;

  if (!isLoggedIn) {
    if (!onboardingComplete) return '/onboarding';
    return '/login';
  }
  if (auth == null || auth.isLoading) return null;
  if (auth.user == null) {
    debugPrint('[appRedirect] user is null but logged in → /login');
    return '/login';
  }
  if (location == '/access-denied') return null;
  if (!auth.user!.isActive) {
    return _accessDeniedRedirect(
      reason: 'disabled',
      auth: auth,
      allowedRoles: allowedRoles,
    );
  }
  if (location != '/login' && !allowedRoles.contains(auth.user!.role)) {
    debugPrint('[appRedirect] role_mismatch: user=${auth.user!.role.value} allowed=${allowedRoles.map((r)=>r.value).join(",")}}');
    return _accessDeniedRedirect(
      reason: 'role_mismatch',
      auth: auth,
      allowedRoles: allowedRoles,
    );
  }

  return null;
}
