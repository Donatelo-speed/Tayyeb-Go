import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  static const primary = Color(0xFF7C3AED);
  static const primaryHover = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFFC084FC);
  static const primaryBg = Color(0xFFF5F3FF);

  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFEFF6FF);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  static const darkBg = Color(0xFF0A0A0B);
  static const darkSurface = Color(0xFF131316);
  static const darkCard = Color(0xFF1C1C1E);
  static const darkCardHover = Color(0xFF242428);
  static const darkBorder = Color(0xFF2C2C2E);
  static const darkInput = Color(0xFF1C1C1E);

  static const lightBg = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFF4F4F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardHover = Color(0xFFF8F8FA);
  static const lightBorder = Color(0xFFE4E4E7);
  static const lightInput = Color(0xFFF4F4F5);

  static Color textPrimary(bool isDark) => isDark ? const Color(0xFFF8FAFC) : slate900;
  static Color textSecondary(bool isDark) => isDark ? const Color(0xFFA1A1AA) : slate500;
  static Color textMuted(bool isDark) => isDark ? const Color(0xFF71717A) : slate400;
  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color cardHover(bool isDark) => isDark ? darkCardHover : lightCardHover;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color input(bool isDark) => isDark ? darkInput : lightInput;
  static Color divider(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color skeleton(bool isDark) => isDark ? darkCard : slate200;
  static Color skeletonShine(bool isDark) => isDark ? darkCardHover : slate100;
  static Color textOnPrimary(bool isDark) => Colors.white;

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return warning;
      case 'accepted': return info;
      case 'preparing': return const Color(0xFF7C3AED);
      case 'ready_for_driver': return const Color(0xFF0891B2);
      case 'picked_up': return const Color(0xFFEA580C);
      case 'delivered': return success;
      case 'cancelled': return danger;
      case 'open': return success;
      case 'assigned': return info;
      case 'in_progress': return const Color(0xFF7C3AED);
      case 'resolved': return success;
      case 'closed': return slate400;
      case 'online': return success;
      case 'offline': return slate400;
      case 'busy': return warning;
      case 'suspended': return danger;
      default: return slate400;
    }
  }

  static Color roleColor(String role) {
    switch (role) {
      case 'superAdmin': return const Color(0xFFDC2626);
      case 'restaurantOwner': return const Color(0xFF2563EB);
      case 'cashier': return const Color(0xFF7C3AED);
      case 'driver': return const Color(0xFFD97706);
      case 'customer': return const Color(0xFF059669);
      default: return primary;
    }
  }

  static List<Color> statusGradient(String status) {
    final c = statusColor(status);
    return [c, c.withValues(alpha: 0.7)];
  }
}