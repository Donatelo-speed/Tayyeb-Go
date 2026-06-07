# Wave 1 Verification Report

**Date**: 2026-06-07
**Scope**: Firestore collection naming consistency, security rules coverage, storage accessibility, environment separation
**Method**: Static code analysis of Dart, JS, TS, JSON, and rules files
**Constraint**: No code was modified -- inspection only

---

## 1. Actual Firestore Collection Names in Production

**Production project ID**: `tayybego` (from `serviceAccountKey.json`)

### Top-Level Collections (39 total)

| Collection | Source |
|---|---|
| `users` | code, rules, seed, indexes |
| `restaurants` | code, rules, seed, indexes |
| `orders` | code, rules, seed, indexes |
| `promos` | code, rules, seed, indexes |
| `payments` | code, rules, indexes |
| `menu_items` | code, seed, indexes |
| `activity_log` | code, rules, seed |
| `config` | code, seed |
| `dispatch_requests` | code, rules, indexes |
| `driver_locations` | code, rules, indexes |
| `driver_wallets` | code, rules, indexes |
| `notifications` | code, rules, indexes |
| `payment_intents` | code, rules |
| `payment_methods` | code, rules |
| `payouts` | code, rules, indexes |
| `anything_requests` | code, rules, indexes |
| `loyalty_transactions` | code, rules, indexes |
| `brands` | code, rules |
| `branches` | code, rules |
| `zones` | code, rules |
| `approvals` | code, rules |
| `contracts` | code, rules |
| `coupons` | code, rules |
| `campaigns` | code, rules |
| `reports` | code, rules |
| `feature_flags` | code, rules |
| `support_tickets` | code, rules |
| `support` | code, rules |
| `marketing` | code, rules |
| `settlements` | code, rules |
| `drivers` | code, rules |
| `emergency_alerts` | rules only |
| `customers` | rules only |
| `dispatches` | rules only (legacy) |
| `settings` | rules only (legacy/alias) |
| `documents` | code only (NO rules) |
| `driverAssignments` | code only (NO rules) |
| `subscriptions` | code only (NO rules) |

### Subcollections (9 total)

| Collection Path | Parent | Source |
|---|---|---|
| `users/{id}/addresses` | `users` | code, rules |
| `users/{id}/saved_addresses` | `users` | code only (NO rules) |
| `users/{id}/loyalty_transactions` | `users` | code only |
| `restaurants/{id}/menu_items` | `restaurants` | code, rules, seed |
| `restaurants/{id}/orders` | `restaurants` | rules only |
| `restaurants/{id}/reviews` | `restaurants` | rules only |
| `restaurants/{id}/promos` | `restaurants` | rules only |
| `restaurants/{id}/products` | `restaurants` | code only (NO rules) |
| `restaurants/{id}/categories` | `restaurants` | code only (NO rules) |
| `restaurants/{id}/promotions` | `restaurants` | code only (NO rules) |
| `driver_wallets/{id}/transactions` | `driver_wallets` | code only (NO rules) |

---

## 2. Case Sensitivity Verification

**Verdict: NO MISMATCH FOUND**

All five key collections use consistent lowercase naming across every code path:

| Concept | Code Uses | Rules Uses | Seed Uses | Uppercase Variant Found? |
|---|---|---|---|---|
| `users` | `'users'` | `'users'` | `'users'` | No |
| `orders` | `'orders'` | `'orders'` | `'orders'` | No |
| `restaurants` | `'restaurants'` | `'restaurants'` | `'restaurants'` | No |
| `promos` | `'promos'` | `'promos'` | `'promos'` | No |
| `payments` | `'payments'` | `'payments'` | not seeded | No |

**Evidence**: Grep across 275+ `.collection('xxx')` calls in Dart files (`tayyebgo_monorepo/packages/`, `tayyebgo_monorepo/apps/`) and 15+ in JS files (`tayyebgo_monorepo/scripts/`, `tayyebgo_monorepo/functions/`) confirms zero uppercase collection name strings.

**Note**: One camelCase outlier exists -- `driverAssignments` in `apps/tayyebgo_admin/lib/core/services/admin_firestore_service.dart` (line 222) -- but this is a separate collection from the five under review.

---

## 3. Collection Coverage Matrix

| Collection | Used In Code | Used In Rules | Exists In Seed | Exists In Indexes |
|---|---|---|---|---|
| `users` | YES | YES | YES | YES |
| `restaurants` | YES | YES | YES | YES |
| `orders` | YES | YES | YES | YES |
| `promos` | YES | YES | YES | YES |
| `payments` | YES | YES | NO | YES |
| `menu_items` | YES | YES (subcol) | YES | YES |
| `activity_log` | YES | YES | YES | NO |
| `config` | YES | YES | YES | NO |
| `dispatch_requests` | YES | YES | NO | YES |
| `driver_locations` | YES | YES | NO | YES |
| `driver_wallets` | YES | YES | NO | YES |
| `notifications` | YES | YES | NO | YES |
| `payment_intents` | YES | YES | NO | NO |
| `payment_methods` | YES | YES | NO | NO |
| `payouts` | YES | YES | NO | YES |
| `anything_requests` | YES | YES | NO | YES |
| `loyalty_transactions` | YES | YES | NO | YES |
| `brands` | YES | YES | NO | NO |
| `branches` | YES | YES | NO | NO |
| `zones` | YES | YES | NO | NO |
| `approvals` | YES | YES | NO | NO |
| `contracts` | YES | YES | NO | NO |
| `coupons` | YES | YES | NO | NO |
| `campaigns` | YES | YES | NO | NO |
| `reports` | YES | YES | NO | NO |
| `feature_flags` | YES | YES | NO | NO |
| `support_tickets` | YES | YES | NO | NO |
| `support` | YES | YES | NO | NO |
| `marketing` | YES | YES | NO | NO |
| `settlements` | YES | YES | NO | NO |
| `drivers` | YES | YES | NO | NO |
| `customers` | NO | YES | NO | NO |
| `dispatches` | NO | YES | NO | NO |
| `emergency_alerts` | NO | YES | NO | NO |
| `settings` | NO | YES | NO | NO |
| `documents` | YES | **NO** | NO | NO |
| `driverAssignments` | YES | **NO** | NO | NO |
| `subscriptions` | YES | **NO** | NO | NO |
| `restaurants/{id}/products` | YES | **NO** | NO | N/A |
| `restaurants/{id}/categories` | YES | **NO** | NO | N/A |
| `restaurants/{id}/promotions` | YES | **NO** | NO | N/A |
| `driver_wallets/{id}/transactions` | YES | **NO** | NO | N/A |
| `users/{id}/addresses` | YES | YES | NO | N/A |
| `users/{id}/saved_addresses` | YES | **NO** | NO | N/A |
| `restaurants/{id}/reviews` | NO | YES | NO | N/A |
| `restaurants/{id}/menu_items` | YES | YES | YES | N/A |
| `restaurants/{id}/orders` | NO | YES | NO | N/A |
| `restaurants/{id}/promos` | NO | YES | NO | N/A |

### Key Gaps

1. **7 collections in code lack security rules**: `documents`, `driverAssignments`, `subscriptions`, `products`, `categories`, `promotions`, `transactions`. These would all be denied by the default fallback rule at line 432 of `firestore.rules`.
2. **4 collections in rules are unused in code**: `customers`, `dispatches`, `emergency_alerts`, `reviews` -- dead rule paths.
3. **`users/{id}/saved_addresses`** is referenced in code but not covered by security rules.
4. **Only 7 of 30+ collections are seeded**: `users`, `restaurants`, `orders`, `promos`, `menu_items`, `config`, `activity_log`.

---

## 4. Restaurant Logo & Menu Image Public Readability

**Source**: `tayyebgo_monorepo/storage.rules`

```javascript
// Restaurant logos/menus (line 44)
match /restaurants/{restaurantId}/{imageName} {
  allow read: if isAuthenticated();      // NOT public
  allow write: if isRestaurantOwner(restaurantId) || isCashier(restaurantId) || isAdmin();
}

// Menu item images (line 55)
match /menu_items/{restaurantId}/{imageName} {
  allow read: if isAuthenticated();      // NOT public
  allow write: if isRestaurantOwner(restaurantId) || isCashier(restaurantId) || isAdmin();
}
```

**Verdict: NOT publicly readable.** Both paths require Firebase Authentication for read access (`allow read: if isAuthenticated()`).

**Impact**: The blueprint specifies a Guest Mode feature where unauthenticated users browse restaurants and menus. Current rules would block image loading for guests, resulting in broken images.

---

## 5. Environment Separation Status

**Source**: `tayyebgo_monorepo/.firebaserc`, `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options.dart`, `tayyebgo_monorepo/serviceAccountKey.json`

### What exists:
- `.firebaserc` defines three project aliases: `tayyebgo-dev`, `tayyebgo-staging`, `tayyebgo-prod`
- Hosting targets are environment-specific (e.g., `tayyebgo-customer-dev` vs `tayyebgo-customer`)

### What's missing:
- `firebase_options.dart` hardcodes `projectId: 'tayyebgo'` (production) -- no build flavor or `--dart-define` switching
- `serviceAccountKey.json` is for production only and is checked into the repo
- No `.env` files exist for environment-specific configuration
- Single `firestore.rules` and `storage.rules` deployed to all environments
- No Flutter build flavors configured

### Classification: PARTIAL

The Firebase project infrastructure is set up (3 projects), but the application code has no mechanism to target different environments. All environments effectively share the same production Firestore instance.

---

## 6. Wave 1 Status Re-evaluation

### Correct
- All 5 key collections (`users`, `orders`, `restaurants`, `promos`, `payments`) use consistent lowercase naming across code, rules, seed, and indexes
- Comprehensive security rules exist for most collections
- 3 Firebase projects configured in `.firebaserc`

### Issues

| # | Issue | Severity | Location |
|---|---|---|---|
| 1 | 7 collections in code lack security rules | **HIGH** | `documents`, `driverAssignments`, `subscriptions`, `products`, `categories`, `promotions`, `transactions` |
| 2 | Storage images not publicly readable (breaks guest mode) | **MEDIUM** | `storage.rules` lines 44-61 |
| 3 | Environment separation incomplete | **MEDIUM** | `firebase_options.dart` hardcodes production |
| 4 | Only 7 of 30+ collections are seeded | **LOW** | `scripts/seed_firestore.js` |
| 5 | `users/{id}/saved_addresses` subcollection has no rules | **MEDIUM** | `firestore.rules` lacks matching path |
| 6 | Dead rule paths for unused collections | **LOW** | `customers`, `dispatches`, `emergency_alerts`, `reviews` |

### Final Verdict: PARTIALLY COMPLETE

Core naming consistency is correct, but critical gaps remain in security rule coverage, storage accessibility for guest mode, and environment separation implementation.

---

## Evidence File Index

| File | Relevance |
|---|---|
| `tayyebgo_monorepo/firestore.rules` | All collection security rules |
| `tayyebgo_monorepo/storage.rules` | Storage access rules for images |
| `tayyebgo_monorepo/scripts/seed_firestore.js` | Seed data (11 collections) |
| `tayyebgo_monorepo/functions/index.js` | Cloud Functions collection references |
| `tayyebgo_monorepo/cloud_functions/functions/src/index.ts` | TypeScript cloud functions |
| `tayyebgo_monorepo/firestore.indexes.json` | Composite indexes per collection |
| `tayyebgo_monorepo/firebase.json` | Firebase project config |
| `tayyebgo_monorepo/.firebaserc` | Environment aliases (dev/staging/prod) |
| `tayyebgo_monorepo/serviceAccountKey.json` | Production project ID |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/src/firebase/firebase_options.dart` | Hardcoded project config |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/infrastructure/repositories/*.dart` | All repository collection refs |
| `tayyebgo_monorepo/packages/tayyebgo_core/lib/infrastructure/services/*.dart` | Service layer collection refs |
| `tayyebgo_monorepo/packages/tayyebgo_payment/lib/src/providers/payment_provider.dart` | Payments collection refs |
| `tayyebgo_monorepo/apps/*/lib/**/*.dart` | App-level collection refs |
