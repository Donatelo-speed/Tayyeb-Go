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

String? appRedirect({
  required String location,
  required List<UserRole> allowedRoles,
  AuthProvider? auth,
  bool onboardingComplete = true,
}) {
  final fbUser = fb.FirebaseAuth.instance.currentUser;
  final isLoggedIn = fbUser != null;

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
      if (!auth.user!.isActive) return '/access-denied?reason=disabled';
      if (!allowedRoles.contains(auth.user!.role)) return '/access-denied?reason=role_mismatch';
      return roleHomePath(auth.user!.role);
    }
    return null;
  }

  if (location == '/splash') return null;

  if (location == '/forgot-password') return null;

  if (!isLoggedIn) {
    if (!onboardingComplete) return '/onboarding';
    return '/login';
  }
  if (auth == null || auth.isLoading) return null;
  if (auth.user == null) return '/login';
  if (location == '/access-denied') return null;
  if (!auth.user!.isActive) return '/access-denied?reason=disabled';
  if (location != '/login' && !allowedRoles.contains(auth.user!.role)) return '/access-denied?reason=role_mismatch';

  return null;
}
