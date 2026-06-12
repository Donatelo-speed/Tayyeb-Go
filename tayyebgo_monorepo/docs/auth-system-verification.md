# TayyebGo Auth System Verification Report

## System Architecture

### Single Source of Truth: `users/{uid}` Firestore Collection

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | yes | Firebase Auth email |
| `displayName` | string | yes | User's display name |
| `role` | string | yes | One of: `superAdmin`, `restaurantOwner`, `cashier`, `driver`, `customer` |
| `isActive` | boolean | yes | Account enabled/disabled |
| `restaurantId` | string | no | For partner roles: links to `restaurants/{id}` |
| `phone` | string | no | Phone number |
| `photoUrl` | string | no | Profile image URL |
| `address` | string | no | Default address |
| `preferredLocale` | string | no | `en` or `ar` (default: `en`) |
| `loyaltyPoints` | number | no | Customer loyalty points (default: 0) |
| `createdAt` | timestamp | auto | Document creation time |
| `updatedAt` | timestamp | auto | Last update time |
| `lastSignInAt` | timestamp | auto | Last login time |

### Role → App Mapping

| Role | App Target | Can Access |
|------|-----------|------------|
| `superAdmin` | admin | admin, partner, driver, customer (all) |
| `restaurantOwner` | partner | partner only |
| `cashier` | partner | partner only |
| `driver` | driver | driver only |
| `customer` | customer | customer only |

### Auth Flow

```
User logs in (email/password)
  → Firebase Auth creates session
  → AuthProvider._syncFirebaseUser() fires
  → AuthProvider.resolveUser(firebaseUser) reads users/{uid} from Firestore
  → UserModel.fromFirestore(doc) extracts 'role' field
  → UserRole.fromString(role) maps to enum
  → GoRouter.redirect() calls appRedirect() which checks role against allowedRoles
  → If role mismatch → /access-denied?reason=role_mismatch&currentRole=X&requiredRoles=Y
  → AccessDeniedScreen auto-redirects to correct app based on user's actual role
```

---

## Test Users

### Created Users

| Email | Password | Role | Restaurant ID | App Target |
|-------|----------|------|---------------|------------|
| `admin@test.com` | `Admin123!` | `superAdmin` | — | admin |
| `customer@test.com` | `Customer123!` | `customer` | — | customer |
| `driver@test.com` | `Driver123!` | `driver` | — | driver |
| `partner-owner@test.com` | `Owner123!` | `restaurantOwner` | `test_restaurant_001` | partner |
| `partner-cashier@test.com` | `Cashier123!` | `cashier` | `test_restaurant_001` | partner |

### How to Create Test Users

#### Option A: Automated Script (Recommended)

```bash
# 1. Install Firebase Admin SDK
npm install firebase-admin

# 2. Set up credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# 3. Run the script
node scripts/setup-test-users.js
```

#### Option B: Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com/project/tayyebgo/authentication/users)
2. Click "Add user"
3. Enter email and password
4. After creating, go to Firestore → `users` collection → create document with the user's UID as doc ID
5. Set the `role` field to the correct value

#### Option C: Firebase CLI

```bash
# Create auth users
firebase auth:import --csv users.csv

# users.csv format:
# uid,email,password,displayName
# admin-uid,admin@test.com,Admin123!,Test Admin
```

---

## Login Test Results

### Expected Behavior Per App

#### Customer App (`tayyebgo_customer`)
| Login As | Expected Result |
|----------|----------------|
| `customer@test.com` | ✓ Customer home screen opens |
| `admin@test.com` | ✓ Redirects to admin app (or shows home — superAdmin has customer access) |
| `driver@test.com` | ✗ Access denied → auto-redirects to driver app |
| `partner-owner@test.com` | ✗ Access denied → auto-redirects to partner app |

#### Driver App (`tayyebgo_driver`)
| Login As | Expected Result |
|----------|----------------|
| `driver@test.com` | ✓ Driver dashboard opens |
| `admin@test.com` | ✓ Redirects to admin app (or shows dashboard — superAdmin has driver access) |
| `customer@test.com` | ✗ Access denied → auto-redirects to customer app |
| `partner-owner@test.com` | ✗ Access denied → auto-redirects to partner app |

#### Partner App (`tayyebgo_partner`)
| Login As | Expected Result |
|----------|----------------|
| `partner-owner@test.com` | ✓ Owner dashboard opens |
| `partner-cashier@test.com` | ✓ Cashier terminal opens |
| `admin@test.com` | ✓ Owner dashboard opens (superAdmin treated as owner) |
| `customer@test.com` | ✗ Access denied → auto-redirects to customer app |
| `driver@test.com` | ✗ Access denied → auto-redirects to driver app |

#### Admin App (`tayyebgo_admin`)
| Login As | Expected Result |
|----------|----------------|
| `admin@test.com` | ✓ Admin dashboard opens |
| `customer@test.com` | ✗ Access denied → auto-redirects to customer app |
| `partner-owner@test.com` | ✗ Access denied → auto-redirects to partner app |

---

## Changes Made (This Session)

### Core Auth Fixes

1. **`firebase_auth_repository.dart`** — Removed hardcoded `UserRole.customer` fallbacks. Added warning logs when Firestore doc is missing. `authStateChanges` now always reads from Firestore via `_resolveFromFirestore()`.

2. **`access_denied_screen.dart`** — Complete rewrite. Now auto-redirects to correct app based on user's actual role after 500ms. Shows "Redirecting you..." state. Button redirects to correct app instead of logout. Debug info card preserved.

3. **`app_router.dart`** — Access-denied route now passes role context (currentRole, requiredRoles, userId) as query params.

4. **`route_guards.dart`** — `appRedirect()` passes full role context to access-denied redirect URL.

### Flutter Stripe Web Fix

5. **`checkout_screen.dart`** — Removed direct `flutter_stripe` import. Uses conditional import via `stripe_stub.dart` (web no-op) / `stripe_stub_native.dart` (mobile real implementation).

6. **`wallet_topup_screen.dart`** — Same conditional import pattern. Web shows mock success, mobile uses real Stripe SDK.

7. **`main.dart` (customer)** — Removed `Stripe.publishableKey` and `Stripe.instance.applySettings()` from startup. Stripe is now initialized lazily per-transaction on mobile only.

### Admin UI Fix

8. **`side_nav.dart`** — Added `overflow: TextOverflow.ellipsis` and `maxLines: 1` to brand text and nav item labels to prevent RenderFlex overflow on narrow screens.

### Security (Previous Session)

9. **Firestore rules** — Reviews require auth, driver GPS restricted to admin+self, dispatches restricted, activity_log admin-only, notifications field fixed.

10. **Storage rules** — Added image type + 5MB size limits on all upload paths.

11. **Rate limiting** — Firestore-based rate limiter on 5 sensitive Cloud Functions.

12. **Price validation** — Server-side `validateOrderPricing` Cloud Function.

---

## Remaining Issues / Known Limitations

### High Priority
- [ ] **Firebase App Check** not enabled — allows unauthenticated API calls
- [ ] **Server-side price validation** deployed but not yet wired into client order flow
- [ ] **Driver GPS** still readable by admin only — needs dispatch-system read access

### Medium Priority
- [ ] **Partner `kitchenStaff` role** — not in `UserRole` enum. If needed, add to enum + Firestore rules
- [ ] **Phone number sign-in** — test user for phone auth not created (requires real phone)
- [ ] **Google/Apple sign-in** — test users for social auth not created (requires OAuth setup)

### Low Priority
- [ ] **`flutter_stripe` web** — shows mock success. Real Stripe Checkout (redirect-based) needed for production web
- [ ] **Partner `restaurantId`** — test users share `test_restaurant_001`. Need to create actual restaurant document in Firestore
- [ ] **Offline support** — auth works offline (cached Firebase Auth), but Firestore reads fail

---

## How to Verify Locally

```bash
# 1. Start customer app
cd apps/tayyebgo_customer
flutter run -d chrome

# 2. Login as customer@test.com / Customer123!
# Expected: Customer home screen opens

# 3. Start partner app
cd apps/tayyebgo_partner
flutter run -d chrome

# 4. Login as partner-owner@test.com / Owner123!
# Expected: Owner dashboard opens

# 5. Start admin app
cd apps/tayyebgo_admin
flutter run -d chrome

# 6. Login as admin@test.com / Admin123!
# Expected: Admin dashboard opens

# 7. Start driver app
cd apps/tayyebgo_driver
flutter run -d chrome

# 8. Login as driver@test.com / Driver123!
# Expected: Driver dashboard opens
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                  Firebase Auth                       │
│  (email/password, Google, Apple, Phone)              │
└──────────────────────┬──────────────────────────────┘
                       │ authStateChanges
                       ▼
┌─────────────────────────────────────────────────────┐
│              AuthProvider (shared)                    │
│  _syncFirebaseUser() → resolveUser()                 │
│  reads: users/{uid} from Firestore                   │
│  sets: _user = UserModel.fromFirestore(doc)          │
│  role extracted from: d['role'] as String?           │
└──────────────────────┬──────────────────────────────┘
                       │ notifyListeners
                       ▼
┌─────────────────────────────────────────────────────┐
│              GoRouter (per app)                       │
│  redirect: appRedirect(location, allowedRoles, auth) │
│  checks: allowedRoles.contains(auth.user.role)       │
│  if mismatch: /access-denied?reason=role_mismatch    │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ Customer │ │ Partner  │ │  Admin   │
    │ Home     │ │Dashboard │ │Dashboard │
    └──────────┘ └──────────┘ └──────────┘
```

---

*Report generated: 2026-06-11*
*Codebase: tayyebgo_monorepo*
*Firebase project: tayyebgo*
