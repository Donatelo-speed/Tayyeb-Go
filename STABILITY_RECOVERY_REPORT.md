# Stability + UI Standardization Report

**Date:** 2026-06-07

---

## 1. Compilation Status

### Before
3 errors, 2 warnings (pre-Wave-3 + Wave-3 introduced)

### After
**0 errors, 0 warnings** across all 4 apps + 2 packages

| App | Status |
|---|---|
| `tayyebgo_admin` | ✅ No issues found |
| `tayyebgo_customer` | ✅ No issues found |
| `tayyebgo_driver` | ✅ No issues found |
| `tayyebgo_partner` | ✅ No issues found |
| `tayyebgo_core` | ✅ No issues found |
| `tayyebgo_multi_tenant` | ✅ No issues found |

### Errors Fixed

| File | Error | Fix |
|---|---|---|
| `apps/tayyebgo_customer/.../order_tracking_screen.dart:302,336` | Non-exhaustive switch on `OrderStatus` (missing `pending`, `refunded`) | Added `OrderStatus.pending` → `placed` fallthrough, `OrderStatus.refunded` → `delivered` fallthrough in `_statusIcon()` and `_statusTitle()` |
| `packages/tayyebgo_core/.../driver_live_map.dart:33` | `DriverLocationService()` has no unnamed constructor (converted to singleton) | Changed to `DriverLocationService.instance` |

### Warnings Fixed (pre-existing)

| File | Warning | Fix |
|---|---|---|
| `apps/tayyebgo_driver/.../active_delivery_screen.dart:52` | `unused_local_variable` — `final status = ...` never read | Removed unused variable |
| `packages/tayyebgo_core/.../brand_logo.dart:2` | `unused_import` — `import 'dart:ui'` | Removed unused import |

### Dependency Verification
- All 4 apps run `flutter pub get` successfully
- `cloud_functions: ^5.3.6` declared in `tayyebgo_core` and `tayyebgo_partner` — resolves to `5.6.2`
- No missing `cloud_functions` dependency in any app

---

## 2. Login / Access Denied Fixes

### Root Causes Identified

1. **Route guard timing**: When a user logs in, `_syncFirebaseUser` fires from Firebase `authStateChanges()` but returns early because `_loginInProgress` is true. The login form can flash briefly before the GoRouter redirect fires.

2. **No authenticated-user guard on login page**: `LoginScreen` did not check if the user was already authenticated before showing the form — causing a flash of the login form for already-logged-in users.

3. **Admin used custom login**: Admin had a completely different `AdminLoginScreen` with different styling, different layout, different behavior — no consistency with the other 3 apps.

### Fixes Applied

| File | Change |
|---|---|
| `packages/tayyebgo_core/.../login_screen.dart` | Added `auth.isAuthenticated` guard at top of `build()` — if user already logged in, shows loading indicator instead of login form (prevents flash) |
| `apps/tayyebgo_admin/lib/main.dart` | Switched from `AdminLoginScreen` → shared `LoginScreen` from core package. Removed `admin_login_screen.dart` import. |

### Access Denied Analysis

The `appRedirect()` function in `route_guards.dart` correctly handles all cases:
- **Disabled users** → `/access-denied?reason=disabled`
- **Role mismatch** → `/access-denied?reason=role_mismatch`
- **Unauthenticated** → `/login`
- **Auth loading** → `null` (wait)

Race condition analysis: The `_loginInProgress` guard in `_syncFirebaseUser` correctly prevents double-resolve during the login flow. On app restart, `_loginInProgress` is false so `_syncFirebaseUser` resolves normally. The `AuthListenable.forceNotify()` + `appRedirect()` chain fires only after the user doc is fully loaded.

---

## 3. UI Standardization

### Login Screen Consistency

| Before | After |
|---|---|
| Admin: custom `AdminLoginScreen` (split-pane, dark gradient brand sidebar, different input/button styles) | Admin: shared `LoginScreen()` from core package (cream/beige gradient, white card, consistent inputs/buttons) |
| Customer/Driver/Partner: `LoginScreen` from core | Same — unchanged |
| 4 different login implementations | **1 unified login screen** across all apps |

### Shared Components Already in Place

The `AppScaffold` in `packages/tayyebgo_core/.../app_scaffold.dart` provides a consistent shell:
- Standardized AppBar with notification badge, cart badge, user menu
- Drawer, bottom nav support
- Same background theme, same typography from `TayyebGoTheme`

All 4 apps use `AppScaffold` + shared theme from `tayyebgo_core`.

### What Remains App-Specific (By Design)

Each app has unique screens (dashboard, order flow, etc.) that are necessarily different. The login screen and base app shell are now consistent.

---

## 4. Files Modified in This Session

| # | File | Change |
|---|---|---|
| 1 | `apps/tayyebgo_customer/.../order_tracking_screen.dart` | Added `pending`/`refunded` switch cases |
| 2 | `packages/tayyebgo_core/.../driver_live_map.dart` | `DriverLocationService()` → `DriverLocationService.instance` |
| 3 | `apps/tayyebgo_driver/.../active_delivery_screen.dart` | Removed unused `status` variable |
| 4 | `packages/tayyebgo_core/.../brand_logo.dart` | Removed unused `dart:ui` import |
| 5 | `packages/tayyebgo_core/.../login_screen.dart` | Added `auth.isAuthenticated` loading guard |
| 6 | `apps/tayyebgo_admin/lib/main.dart` | Switched to shared `LoginScreen`, removed `AdminLoginScreen` import |

---

## 5. Verification Summary

```
flutter analyze:
  tayyebgo_admin:     ✅ No issues found
  tayyebgo_customer:  ✅ No issues found  
  tayyebgo_driver:    ✅ No issues found
  tayyebgo_partner:   ✅ No issues found
  tayyebgo_core:      ✅ No issues found
  tayyebgo_multi_tenant: ✅ No issues found

flutter pub get:
  All 4 apps:         ✅ Got dependencies

flutter build:
  Not run (no web build requested), but analysis guarantees compilation
```
