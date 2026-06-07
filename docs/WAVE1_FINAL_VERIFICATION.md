# Wave 1 Final Verification

**Date**: 2026-06-07
**Status**: COMPLETE

---

## Files Changed

| File | Action | Description |
|---|---|---|
| `tayyebgo_monorepo/firestore.rules` | MODIFIED | Added rules for 8 missing collections |
| `tayyebgo_monorepo/storage.rules` | MODIFIED | Changed restaurant/menu image reads from auth-only to public |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options.dart` | MODIFIED | Added environment selection via `--dart-define=ENV=` |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options_dev.dart` | CREATED | Dev Firebase config template |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options_staging.dart` | CREATED | Staging Firebase config template |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options_prod.dart` | CREATED | Production Firebase config (extracted from existing) |

---

## 1. Firestore Security Rules Added

### 1.1 `documents` (top-level) — lines 388-396
- `read`: admin or owner (by `resource.data.userId`)
- `create`: any authenticated user
- `update`: admin or owner
- `delete`: admin only
- **Rationale**: Drivers/stores submit documents for verification; admin reviews and approves.

### 1.2 `driverAssignments` (top-level) — lines 400-404
- `read`: admin or driver
- `write`: admin only
- **Rationale**: Admin auto-dispatch creates assignment records; drivers read their assignments.

### 1.3 `subscriptions` (top-level) — lines 408-412
- `read`: admin only
- `write`: admin only
- **Rationale**: Admin-managed subscription plans for stores.

### 1.4 `users/{userId}/saved_addresses` (subcollection) — lines 69-75
- `read`: owner or admin
- `create`: owner
- `update`: owner
- `delete`: owner or admin
- **Rationale**: Users manage their own saved addresses via `user_repository.dart`.

### 1.5 `restaurants/{restaurantId}/products` (subcollection) — lines 128-134
- `read`: any authenticated user
- `write`: admin, restaurantOwner, or cashier
- **Rationale**: Catalog management for store products.

### 1.6 `restaurants/{restaurantId}/categories` (subcollection) — lines 136-141
- `read`: any authenticated user
- `write`: admin or restaurantOwner
- **Rationale**: Menu category organization.

### 1.7 `restaurants/{restaurantId}/promotions` (subcollection) — lines 143-148
- `read`: any authenticated user
- `write`: admin or restaurantOwner
- **Rationale**: Store-level discount promotions.

### 1.8 `driver_wallets/{driverId}/transactions` (subcollection) — lines 188-193
- `read`: owner or admin
- `create`: owner (driver records own earnings/payouts)
- `delete`: admin only
- **Rationale**: Driver wallet transaction history.

---

## 2. Security Audit: serviceAccountKey.json

### Findings
- **File**: `tayyebgo_monorepo/serviceAccountKey.json`
- **Project**: `tayyebgo` (production)
- **Tracked by git?**: NO — properly ignored by `.gitignore` pattern `**/serviceAccountKey.json`
- **Account type**: Firebase Admin SDK service account
- **Status**: Active

### Actions Taken
- **No removal needed** — the file is already gitignored and not committed to the repository. It exists only on local filesystem for development use.
- **Precaution**: The `.gitignore` at repo root includes `**/serviceAccountKey.json` (line 33). Verified this matches the file path.

### Key Rotation Steps (documented)
When rotating this key:
1. **Firebase Console**: Project Settings > Service Accounts > Generate new private key
2. **Replace**: Overwrite `tayyebgo_monorepo/serviceAccountKey.json` with the new key
3. **Verify**: Run `node scripts/seed_firestore.js --dry-run` to confirm connectivity
4. **Revoke old key**: Firebase Console > Service Accounts > Delete the previous key
5. **DO NOT commit**: Confirm `git status` shows the file as ignored

---

## 3. Guest Mode Audit

### Findings
- **Guest mode is NOT implemented in code**: No anonymous auth, no guest browsing flow, no pre-auth cart logic found in the Dart codebase.
- **Blueprint mentions it** as a future feature in Section 6 (Pro-Tier Upgrades).
- **Storage rules previously required authentication** for restaurant logos and menu item images (`allow read: if isAuthenticated()`).

### Actions Taken
Updated `storage.rules` to prepare for guest mode:
| Path | Old Rule | New Rule |
|---|---|---|
| `/restaurants/{id}/{imageName}` | `allow read: if isAuthenticated()` | `allow read: if true` |
| `/menu_items/{id}/{imageName}` | `allow read: if isAuthenticated()` | `allow read: if true` |

**Protected paths remain secure** (no change):
- `/users/{userId}/profile_picture.jpg` — auth required
- `/drivers/{driverId}/{documentName}` — owner/admin only
- `/uploads/{userId}/{fileName}` — owner/admin only
- `/{allPaths=**}` — deny all

---

## 4. Environment Separation

### Before
- Single `firebase_options.dart` hardcoded production credentials
- No mechanism to switch between dev/staging/prod
- `.firebaserc` defined 3 project aliases but they were unusable from Flutter

### After

#### File structure
```
packages/tayyebgo_core/lib/src/firebase/
  firebase_options.dart        # Selector: reads --dart-define=ENV=
  firebase_options_prod.dart   # Production config (tayyebgo)
  firebase_options_staging.dart # Staging config (tayyebgo-staging) — TEMPLATE
  firebase_options_dev.dart     # Dev config (tayyebgo-dev) — TEMPLATE
```

#### Usage
```bash
# Production (default)
flutter run --dart-define=ENV=prod

# Staging
flutter run --dart-define=ENV=staging

# Development
flutter run --dart-define=ENV=dev
```

#### TODO: Fill dev/staging configs
The dev and staging template files contain placeholder values (`AIzaSyEXAMPLE_*`). To populate:
1. Go to Firebase Console for each project
2. Project Settings > General > Your apps > Web app > Config
3. Copy the `firebaseConfig` values into the respective `firebase_options_*.dart` file

---

## 5. Collection Coverage Matrix (After Remediation)

| Collection | Used In Code | Used In Rules | Status |
|---|---|---|---|
| `users` | YES | YES | OK |
| `restaurants` | YES | YES | OK |
| `orders` | YES | YES | OK |
| `promos` | YES | YES | OK |
| `payments` | YES | YES | OK |
| `menu_items` | YES | YES | OK |
| `documents` | YES | **NOW ADDED** | FIXED |
| `driverAssignments` | YES | **NOW ADDED** | FIXED |
| `subscriptions` | YES | **NOW ADDED** | FIXED |
| `users/{id}/saved_addresses` | YES | **NOW ADDED** | FIXED |
| `restaurants/{id}/products` | YES | **NOW ADDED** | FIXED |
| `restaurants/{id}/categories` | YES | **NOW ADDED** | FIXED |
| `restaurants/{id}/promotions` | YES | **NOW ADDED** | FIXED |
| `driver_wallets/{id}/transactions` | YES | **NOW ADDED** | FIXED |
| `activity_log` | YES | YES | OK |
| `config` | YES | YES | OK |
| `dispatch_requests` | YES | YES | OK |
| `driver_locations` | YES | YES | OK |
| `driver_wallets` | YES | YES | OK |
| `notifications` | YES | YES | OK |
| `payment_intents` | YES | YES | OK |
| `payment_methods` | YES | YES | OK |
| `payouts` | YES | YES | OK |
| `anything_requests` | YES | YES | OK |
| `loyalty_transactions` | YES | YES | OK |
| `brands` | YES | YES | OK |
| `branches` | YES | YES | OK |
| `zones` | YES | YES | OK |
| `approvals` | YES | YES | OK |
| `contracts` | YES | YES | OK |
| `coupons` | YES | YES | OK |
| `campaigns` | YES | YES | OK |
| `reports` | YES | YES | OK |
| `feature_flags` | YES | YES | OK |
| `support_tickets` | YES | YES | OK |
| `support` | YES | YES | OK |
| `marketing` | YES | YES | OK |
| `settlements` | YES | YES | OK |
| `drivers` | YES | YES | OK |
| `customers` | NO | YES | Dead rule (no impact) |
| `dispatches` | NO | YES | Dead rule (no impact) |
| `emergency_alerts` | NO | YES | Dead rule (no impact) |
| `settings` | NO | YES | Dead rule (no impact) |
| `restaurants/{id}/reviews` | NO | YES | Dead rule (no impact) |
| `users/{id}/addresses` | YES | YES | OK |
| `restaurants/{id}/menu_items` | YES | YES | OK |
| `restaurants/{id}/orders` | NO | YES | Dead rule (no impact) |
| `restaurants/{id}/promos` | NO | YES | Dead rule (no impact) |

---

## 6. Final Readiness Assessment

### Remediation Summary

| Issue | Severity | Status |
|---|---|---|
| 8 collections missing security rules | HIGH | **RESOLVED** |
| Storage images require auth (breaks guest mode) | MEDIUM | **RESOLVED** (public read) |
| Environment separation incomplete | MEDIUM | **RESOLVED** (3 env files + --dart-define) |
| serviceAccountKey.json committed to git | HIGH | **NOT AN ISSUE** (already gitignored) |

### Remaining Items (non-blocking for Wave 2)

| Item | Type | Note |
|---|---|---|
| Fill dev/staging Firebase config values | TODO | Needs Firebase Console access for `tayyebgo-dev` and `tayyebgo-staging` projects |
| Dead rules for unused collections | CLEANUP | `customers`, `dispatches`, `emergency_alerts`, `settings`, `reviews` can be pruned |
| Guest mode implementation | FUTURE | Blueprint feature — not yet in code; storage rules are now prepared |
| Seed script covers only 7/30+ collections | ENHANCEMENT | Future work to extend seed data |

### Wave 1 Verdict

**Before**: PARTIALLY COMPLETE — core naming correct, but 8 security gaps, no environment switching, storage blocked guests
**After**: **COMPLETE** — all identified gaps closed, security rules cover all collections, storage supports guest browsing, environment selection implemented

---

## Reference

- Collection coverage analysis: `docs/wave1_verification_report.md`
- Security rules: `tayyebgo_monorepo/firestore.rules`
- Storage rules: `tayyebgo_monorepo/storage.rules`
- Environment config: `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options*.dart`
- Firebase project config: `tayyebgo_monorepo/.firebaserc`
