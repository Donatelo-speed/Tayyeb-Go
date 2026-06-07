# Tayyeb Go — Production Readiness Audit

**Audit Date:** 2026-06-06  
**Auditor:** Senior Staff Engineer / System Architect  
**Scope:** All 4 apps, all 4 packages, Firebase backend, Core Engine

---

## 1. Current Implementation Status

### 1.1 Customer App (`apps/tayyebgo_customer`)

| Feature | Status | Evidence |
|---|---|---|
| Restaurant browsing | Complete | `customer_home_screen.dart` (999 lines), `restaurant_list_screen.dart` with Firestore streams, vertical type filtering, favorites |
| Restaurant menu display | Complete | `restaurant_menu_screen.dart` (369 lines) with category grouping, modifier selectors, quantity picker |
| Shopping cart | Complete | `cart_screen.dart` (432 lines) with line items, quantities, coupon code, totals |
| Checkout flow | Partial | `checkout_screen.dart` (429 lines) has form, processing animation, error state — but `PaymentSelectionSheet` callback is a no-op, payment method never connected |
| Order placement | Partial | `OrderPlacementService` exists but **no transaction** between Order creation and dispatch_request creation — can create orphan orders |
| Order tracking | Partial | `order_tracking_screen.dart` (412 lines) has ETA stream and timeline — **no live map**, no driver contact |
| Order history | Partial | `order_history_screen.dart` (170 lines) — `RefreshIndicator.onRefresh` is a no-op |
| Anything Delivery | Partial | `anything_request_screen.dart` (254 lines) — **missing `image_picker` dependency in pubspec.yaml**, no geolocation capture |
| Anything tracking | Partial | `anything_tracking_screen.dart` (228 lines) — map is a text placeholder, driver contact buttons are no-ops |
| Saved addresses | Missing | `AddressProvider` registered but **never used** by any screen |
| Loyalty redemption | Stub | `_LoyaltyCard` "Redeem" button has no `onPressed` handler |
| Localization | Missing | `LocaleProvider('en')` hardcoded — no language selector |
| Push notifications | Missing | No FCM token registration in customer app |
| Maps | Missing | `flutter_map` in pubspec but **never instantiated** anywhere |
| Tests | Missing | Zero test files |

### 1.2 Driver App (`apps/tayyebgo_driver`)

| Feature | Status | Evidence |
|---|---|---|
| Dashboard | Complete | `driver_dashboard_screen.dart` (298 lines) with online/offline toggle, wallet summary, quick actions |
| Online/offline toggle | Partial | Writes to Firestore but **no actual location tracking** — `Geolocator` not used anywhere |
| Available requests | Stub | `available_requests_screen.dart` (108 lines) — one-shot `loadAvailableRequests` call, **no real-time stream** |
| Active delivery progress | Partial | `active_delivery_screen.dart` (145 lines) — status advancement works but **no map, no navigation, no customer contact** |
| Earnings history | Partial | `driver_earnings_screen.dart` (183 lines) — no date filtering, no charts, no pagination on transactions |
| Wallet & payouts | Stub | `driver_wallet_screen.dart` (132 lines) — payout request form exists but **no payout method selection, no payout history** |
| Safety & emergency | Stub | `driver_safety_screen.dart` (126 lines) — **SOS and Report Issue dialogs are fake** (only show SnackBars, no backend persistence) |
| GPS location tracking | Missing | Entirely absent — no `Geolocator`, no background service, no location updates to Firestore |
| Real-time map | Missing | `flutter_map` in pubspec but **never used** |
| Push notifications | Missing | No FCM registration |
| Photo proof of delivery | Missing | No camera/image_picker integration |
| Customer contact | Missing | No call/SMS buttons |
| Navigation integration | Missing | No deep links to Google Maps/Waze |
| Tests | Missing | Zero test files |

### 1.3 Partner App (`apps/tayyebgo_partner`)

| Feature | Status | Evidence |
|---|---|---|
| Role-based routing | Complete | `partner_gatekeeper.dart` (24 lines) — routes to cashier terminal or owner dashboard |
| Owner dashboard (4 tabs) | Partial | `owner_dashboard_screen.dart` (858 lines) — overview, menu CRUD, dispatch, marketing. Menu editing uses raw `AlertDialog` with no form validation. No pagination on orders. Dispatch tab shows ALL drivers system-wide. |
| Cashier terminal | Partial | `cashier_terminal_screen.dart` (429 lines) — `RefreshIndicator.onRefresh` is a no-op, blanket catch in offline fallback masks real errors |
| Kitchen display | Partial | `kitchen_mode_screen.dart` (160 lines) — missing 'placed' status, orders disappear after "Mark Ready", no sound on new order |
| AI menu creation | Partial | `ai_menu_creation_screen.dart` (185 lines) — **missing `image_picker` dependency**, no camera option, no PDF support, brittle AI JSON parsing |
| Store customization | Partial | `store_customization_screen.dart` (160 lines) — text fields become stale if data changes externally, no image upload |
| Offline queue | Partial | `offline_queue_provider.dart` (29 lines) — no real-time listener, no error handling |
| Analytics/revenue charts | Missing | `fl_chart` in pubspec but **never imported or used** |
| Push notifications | Missing | `push_notification_service` in core never invoked from partner app |
| Tests | Missing | Zero test files |

### 1.4 Admin App (`apps/tayyebgo_admin`)

| Feature | Status | Evidence |
|---|---|---|
| 15-tab dashboard | Complete | Dashboard, Approvals, Orders, Stores, Drivers, Finance, Customers, Settlements, Marketing, Notifications, Zones, Support, SystemHealth, Settings, Profile |
| Responsive layout | Complete | `ResponsiveBuilder` with mobile (bottom nav), tablet (collapsible drawer), desktop (permanent sidebar) |
| Dark mode | Complete | `_ThemeToggle`, `TayyebGoTheme.lightTheme`/`darkTheme`, `ThemeProvider` |
| Back navigation | Complete | `_onBack()` with `_navHistory` list, breadcrumb, `PopScope` |
| Notification center | Complete | `notifications_view.dart` (243 lines) — compose + history with audience targeting |
| AI copilot system | Complete | 30+ registered tools, 79-intent classifier, 5 tool files (read/create/edit/analyze/recommend) |
| Audit log | Complete | `AppActivityFeed` (116 lines) streams from `activity_log` |
| Push notification sending | Stub | `_send()` only writes to Firestore `notifications` — **no FCM/APNs delivery** |
| Export functionality | Stub | `quick_actions.dart` Export button shows success dialog but **no actual CSV/PDF generation** |
| Image upload | Stub | `store_detail_dialogs.dart` uses text field for URL with instruction: "upload via Firebase Console" |
| Tests | Minimal | 1 test file (`ai_tools_smoke_test.dart`, 80 lines) |

### 1.5 Core Engine (`packages/tayyebgo_core`)

| Service | Status | Readiness |
|---|---|---|
| Order State Machine | Complete | 85% — transaction-protected transitions, valid transition map |
| Commission Calculator | Complete | 85% — simple percentage calculation |
| Notification Templates | Complete | 75% — 102 lines, string-based status matching |
| Connectivity Service | Complete | 65% — `isOnline` defaults to true before init |
| Geolocation Service | Complete (trivial) | 60% — 14 lines, duplicates `GeoLocation.distanceTo` |
| Auto Dispatcher | Partial | 55% — race condition on scoring check, driver count increment outside transaction |
| Menu Sync Service | Partial | 55% — two stream subscriptions never cancelled (memory leak) |
| Firebase Auth Repository | Partial | 55% — `signInWithPhone` completer never completes on timeout |
| Driver Scorer | Partial | 70% — Euclidean distance, no road network, hardcoded speed |
| Driver Location Service | Partial | 50% — stale heartbeat, no lifecycle handling, too-coarse geohash |
| ETA Service | Partial | 45% — hardcoded 8m/s, no traffic or road routing |
| Order Placement Service | Partial | 35% — **no transaction**, can create orphan orders |
| Revenue Service | Partial | 30% — **fetches ALL delivered orders without pagination**, client-side date filtering |
| Push Notification Service | Partial | 40% — **only writes to Firestore**, no actual FCM delivery |
| Offline Queue | Partial | 45% — SharedPreferences 1MB limit, no encryption, JSON corruption crashes app |
| Sync Engine | Partial | 30% — **no max retry limit (infinite loop)**, no exponential backoff, no concurrency lock |
| Skill Execution Engine | Partial | 40% — in-memory only, all data lost on restart, no cancellation support |
| Payment Gateway | Stub | 10% — **mock implementation**, hardcoded success, no Stripe integration |
| Stripe Checkout Service | Stub | 15% — **no Stripe API call**, fake checkout URL |
| Sham Cash Service | Stub | 20% — writes to Firestore, **no real cash processing** |

### 1.6 Supporting Packages

| Package | Status | Readiness | Evidence |
|---|---|---|---|
| `tayyebgo_multi_tenant` | Stub | 25% | Good models but **no TenantProvider** (can't create/manage tenants). `AdminStatsProvider` is a singleton anti-pattern with dead subscription. |
| `tayyebgo_payment` | Stub | 15% | `PaymentProvider` can create docs but **no actual payment gateway integration**. No refunds, no webhooks, no idempotency. |
| `tayyebgo_payout` | Stub | 10% | `PayoutProvider` can LISTEN to payouts but **cannot create or process them**. No bank/payment rails integration. |

---

## 2. Architecture Review

### 2.1 Strengths
- **Clean domain/infrastructure separation** in `tayyebgo_core` — domain interfaces are well-defined
- **Thin apps** — customer, driver, partner all delegate to core correctly
- **Consistent serialization pattern** — `toMap()`/`fromMap()` on all entities
- **GoRouter** used across all apps for consistent routing
- **Provider** for state management (appropriate for this scale)
- **Barrel exports** organized in `tayyebgo_core.dart`

### 2.2 Violations & Risks

| Violation | Severity | Location | Impact |
|---|---|---|---|
| **Direct Firestore access in screens** | HIGH | All 4 apps — screens bypass repos/services and call `FirebaseFirestore.instance` directly | UI coupled to database, impossible to unit test, security rules bypass |
| **No transaction in OrderPlacementService** | CRITICAL | `infrastructure/services/order_placement_service.dart` | Can create orphan Orders without dispatch_requests |
| **AutoDispatcher driver count outside transaction** | HIGH | `infrastructure/services/auto_dispatcher.dart:186` | Driver `activeDeliveries` increments multiple times on transaction retry |
| **RevenueService fetches ALL documents** | CRITICAL | `infrastructure/services/revenue_service.dart` | Will fail at scale with >20K orders |
| **SyncEngine has no max retry** | HIGH | `infrastructure/services/sync_engine.dart` | Infinite loop if operation keeps failing |
| **Domain layer violations** | MEDIUM | `auto_dispatcher.dart` imports `DeliveryMode` from `src/models` (not `domain/`) | Layering violation |
| **No DI framework** | MEDIUM | Entire codebase — manual singletons | Testing is difficult, mock injection requires changing production code |
| **Empty domain/events/ and domain/engine/** | MEDIUM | Both directories exist but are empty | Engine abstraction and event-driven patterns not implemented |
| **Mixed naming conventions** | LOW | PascalCase (`Users`, `Orders`) in some apps vs lowercase (`users`, `orders`) in admin | Inconsistency, potential for confusion |

---

## 3. Core Engine Audit

| Component | Implemented | Partially | Missing | Score |
|---|---|---|---|---|
| **Order State Machine** | ✓ | — | — | 85% |
| **Dispatch Engine** | — | ✓ | — | 55% |
| **Driver Assignment Logic** | — | ✓ | — | 55% |
| **Driver Reassignment Logic** | — | — | ✓ | 0% |
| **Payment Engine** | — | — | ✓ | 10% |
| **Notification Engine** | — | ✓ | — | 40% |
| **Tracking Engine** | — | ✓ | — | 50% |
| **Event System** | — | — | ✓ | 0% |
| **Payout Processing** | — | — | ✓ | 0% |
| **Offline Sync** | — | ✓ | — | 30% |

**Key findings:**
- The order state machine is the most complete component — correct transaction usage, valid transition enforcement
- Driver reassignment logic is completely absent — when a driver rejects, there's no fallback to the next candidate
- No domain events exist anywhere — side effects are called imperatively, making the system rigid
- Payment and payout engines are stubs — they write to Firestore but never call external APIs
- The event system (`domain/events/`) is an empty directory

---

## 4. Firebase Audit

### 4.1 Firestore Security Rules

| Issue | Severity | Detail |
|---|---|---|
| **Collection name casing mismatch** | CRITICAL | Rules protect `users`, `orders`, `restaurants` (lowercase). App code uses `Users`, `Orders`, `Restaurants` (PascalCase). The catch-all deny blocks EVERYTHING. |
| **Review update rule always true** | CRITICAL | `allow update: if isOwner(request.auth.uid)` compares uid to itself — any authenticated user can update any review |
| **Over-permissive read on restaurant subcollection orders** | MODERATE | All authenticated users can read ALL orders within a restaurant |
| **Over-permissive read on drivers** | MODERATE | All authenticated users can read ALL driver documents |
| **Over-permissive read on dispatches** | MODERATE | All authenticated users can read dispatch records |
| **Zero data validation** | MODERATE | No type checks, size constraints, required field checks, or status transition validation |
| **Config collection blocked** | MODERATE | `config`, `payment_intents`, `approvals`, `coupons`, `campaigns`, `reports`, `contracts`, `support`, `settlements`, `marketing` collections have no rules — all blocked by catch-all deny |

**Security Rules Completeness:** 35%

### 4.2 Firestore Indexes

| Issue | Severity | Detail |
|---|---|---|
| **Casing mismatch (same as rules)** | CRITICAL | Indexes on `Orders`, `Users`, `Restaurants`, `Payments` never apply to `orders`, `users`, `restaurants` queries |
| **Missing: orders by status + createdAt** | MODERATE | Admin app queries lowercase `orders` with status filter |
| **Missing: dispatches by driverId + status** | MODERATE | Driver's current dispatch query |
| **Missing: Favorite restaurants query** | LOW | Home screen uses `arrayContains: customerId` on Restaurants — needs composite index |

**Index Completeness:** 40%

### 4.3 Storage Rules

| Issue | Severity | Detail |
|---|---|---|
| **Public read on ALL files** | CRITICAL | `allow read: if true` on `/{allPaths=**}` — driver license docs, restaurant documents, all uploads world-readable |
| **Driver docs readable by all auth users** | MODERATE | Driver license/insurance docs accessible to any logged-in user |
| **No size limits** | LOW | No `request.resource.size` constraints — multi-GB uploads possible |
| **No content type validation** | LOW | No MIME type restrictions |

**Storage Completeness:** 25%

### 4.4 Cloud Functions

| Issue | Severity | Detail |
|---|---|---|
| **No order lifecycle triggers** | HIGH | No `onDocumentUpdated` for auto-assign, auto-notify, or SMS |
| **No payment webhooks** | HIGH | No Stripe/PayPal webhook handler |
| **ProcessPayouts is a skeleton** | CRITICAL | TypeScript function logs intent but **creates no payouts** |
| **No SMS integration** | MEDIUM | No SMS provider for order updates |
| **No rate limiting on AI endpoint** | LOW | Any authenticated user can send arbitrarily large images to OpenAI |
| **CleanupNotifications unbounded** | MODERATE | No `.limit()` on query — batch will fail at >500 docs |

**Functions Completeness:** 45%

### 4.5 Infrastructure

| Issue | Severity | Detail |
|---|---|---|
| **No staging/dev environment** | CRITICAL | `.firebaserc` only has `tayyebgo-prod` — `firebase deploy` goes directly to production |
| **No security headers** | MODERATE | `firebase.json` hosting has no CSP, HSTS, X-Frame-Options |
| **Missing Inter font in pubspec** | LOW | `AppTypography` hardcodes `_family = 'Inter'` but font not registered |

---

## 5. App-by-App Audit

### 5.1 Customer App

**Missing screens/flows:**
- Notifications screen (exists in core but no route in customer app)
- Register screen (exists in core but no route)
- Saved addresses (AddressProvider registered but never used)
- No "Add more items" from cart
- No guest checkout

**Broken integrations:**
- `PaymentSelectionSheet` callback is a no-op — payment method never captured
- `image_picker` imported but missing from pubspec.yaml — build will fail
- No geolocation capture in anything_request
- `_LoyaltyCard` redeem button has no handler
- `RefreshIndicator.onRefresh` is a no-op in order history

### 5.2 Driver App

**Missing workflows:**
- **No GPS location tracking** — core requirement for a delivery driver app
- **No real-time available requests** — current implementation is one-shot
- **No live map** despite `flutter_map` being a declared dependency
- **No navigation directions** (Google Maps/Waze deep link)
- **No proof of delivery** (photos, signature)
- **No customer contact** (call/SMS)
- **No push notifications**

**Tracking implementation:**
- Active delivery screen shows text-based status only
- `DriverLiveMap` widget exists in core but is never used
- `DriverLocationService` in core exists but driver app never calls it

**Dispatch integration:**
- Currently uses `anything_requests` collection (not `dispatch_requests`)
- AutoDispatcher in core targets `dispatch_requests` — driver app reads from the wrong collection
- This is a fundamental mismatch — the driver app is wired for the "Anything Delivery" feature, not the core dispatch system

### 5.3 Partner App

**Store operations completeness:**
- Menu CRUD exists but uses raw `AlertDialog` — no form validation, no image upload, no modifier support
- Kitchen display works but missing 'placed' orders, no sound alerts
- Cashier terminal has `RefreshIndicator` with no-op
- Store customization text fields become stale (initialized once in `initState`)
- No delivery zone management UI
- No staff management UI beyond role assignment

**Product management completeness:**
- Menu items can be created, but modifier groups and options are not manageable from the UI
- Category management is text-based (no category CRUD)
- No batch operations (reorder, bulk price change)
- AI menu creation has no edit-before-save flow

### 5.4 Admin App

**Operational readiness:**
- 15-tab dashboard is fully implemented with responsive layout
- Dark mode, audit log, notification center all exist
- AI copilot with 30+ tools is functional (rule-based, no LLM)

**Analytics readiness:**
- No actual charts or graphs (`fl_chart` not used in customer app at least)
- RevenueService fetches all documents without pagination (will fail at scale)
- `AdminStatsProvider` has real-time aggregation but uses singleton anti-pattern

**Management capabilities:**
- User management, store management, driver management screens exist
- Order override controls exist
- Notification compose with audience targeting
- **Missing:** Real push notification delivery (only writes to Firestore)
- **Missing:** CSV/PDF export (stub only)
- **Missing:** Firebase Storage upload widget (users told to upload via Console)

---

## 6. Launch Readiness Assessment

### Overall Score: 30 / 100

| Category | Score | Rationale |
|---|---|---|
| **Architecture** | 55/100 | Good domain abstractions but no events, no DI, layering violations in infrastructure |
| **Backend / Firebase** | 20/100 | Casing mismatch breaks rules+indexes, no payment/payout webhooks, no staging env, public storage reads, skeleton functions |
| **Customer App** | 40/100 | Core flows work but payment integration broken, no maps, no notifications, missing deps |
| **Driver App** | 15/100 | No GPS tracking, no maps, fake safety features, wired to wrong collection |
| **Partner App** | 40/100 | Dashboard and cashier terminal work, but menu management is fragile, AI feature has missing deps |
| **Admin App** | 60/100 | Most complete app — 15 tabs, dark mode, responsive, AI copilot. Missing real push delivery and export |
| **Security** | 15/100 | Public storage reads, casing mismatch breaks Firestore rules, no security headers, no staging env |
| **Scalability** | 20/100 | No pagination on any Firestore query, RevenueService loads all docs, SyncEngine has infinite retry |

### Readiness Breakdown by Launch Type

| Launch Type | Score | Verdict |
|---|---|---|
| **Soft launch (limited users, manual operations)** | 35/100 | Not ready — Firebase rules are broken, basic flows have critical gaps |
| **Production launch (public, automated)** | 15/100 | Not ready — security issues alone are showstoppers |
| **MVP launch (core feature only, single city)** | 30/100 | Not ready — payment is stubbed, driver app has no GPS, no real-time dispatch |

---

## 7. Critical Blockers

### CRITICAL (Must fix before any launch)

| # | Blocker | Component | Impact |
|---|---|---|---|
| C1 | **Firestore rules casing mismatch** — rules protect `users` but apps write to `Users` | Firebase | All Firestore reads/writes are blocked. System is non-functional. |
| C2 | **Storage public read on ALL files** — driver licenses, restaurant docs world-readable | Firebase | Critical data exposure. Legal liability. |
| C3 | **No transaction in OrderPlacementService** — Order and dispatch_request can be orphaned | Core Engine | Data integrity violation — orders without dispatch records |
| C4 | **ActiveDelivery screen wired to `anything_requests` instead of `dispatch_requests`** | Driver App | Drivers cannot accept real dispatch assignments |
| C5 | **No GPS location tracking in driver app** | Driver App | Core requirement for any delivery platform |
| C6 | **Payment services are stubs** — no actual Stripe or payment processing | Core Engine | Cannot accept real payments |
| C7 | **ProcessPayouts function is a skeleton** — no payout creation | Cloud Functions | Vendors cannot be paid |
| C8 | **No staging/dev Firebase project** — `firebase deploy` goes directly to prod | DevOps | Any deployment mistake hits production |

### HIGH (Must fix before public launch)

| # | Blocker | Component | Impact |
|---|---|---|---|
| H1 | **RevenueService loads ALL delivered orders** — no pagination | Core Engine | Will crash/timeout at scale |
| H2 | **SyncEngine has no max retry** — infinite loop if an operation fails | Core Engine | Battery drain, data corruption |
| H3 | **AutoDispatcher driver count outside transaction** | Core Engine | Inflated active delivery counts |
| H4 | **Order history RefreshIndicator is a no-op** | Customer App | Users cannot manually refresh |
| H5 | **SOS/Report Issue dialogs are fake** — no backend persistence | Driver App | Safety feature is deceptive |
| H6 | **No SMS/email notifications** | Cloud Functions | Customers not notified of order status |
| H7 | **`image_picker` missing from both customer and partner pubspec.yaml** | Customer + Partner | Build will fail at compile time |
| H8 | **Missing dispatch_request indexes for driver queries** | Firebase | Driver dispatch queries will fail |
| H9 | **Review update rule always true** — any auth user can edit any review | Firebase | Data integrity issue |
| H10 | **No payment webhook handler** — Stripe confirmations not processed | Cloud Functions | Payments never captured |

### MEDIUM (Fix before feature-complete launch)

| # | Blocker | Component | Impact |
|---|---|---|---|
| M1 | **No domain events** — side effects called imperatively | Core Engine | Rigid architecture, hard to extend |
| M2 | **No pagination on any list** — restaurants, orders, menu items all unbounded | All Apps | Performance degradation at scale |
| M3 | **Driver reassignment logic absent** — no fallback on reject | Core Engine | Stale unassigned orders |
| M4 | **Euclidean distance in driver scoring** — no road network | Core Engine | Inaccurate ETAs |
| M5 | **Push notifications write to Firestore but don't deliver** | Admin + Core | Notifications never reach devices |
| M6 | **No saved addresses in checkout** | Customer App | Users must re-enter address every order |
| M7 | **No charts in any app** despite `fl_chart` declared | Customer, Partner | No visual analytics |
| M8 | **TenantProvider missing** — cannot create/manage tenants | Multi-Tenant | Multi-tenant feature is non-functional |
| M9 | **Admin export buttons are stubs** | Admin App | No CSV/PDF generation |
| M10 | **No DI framework** — manual singletons everywhere | Core Engine | Testing is difficult |

### LOW (Fix post-launch)

| # | Blocker | Component | Impact |
|---|---|---|---|
| L1 | No test coverage anywhere | All | Quality risk |
| L2 | No CI/CD pipeline | DevOps | Manual deployment risk |
| L3 | No error reporting (Crashlytics/Sentry) | All | Silent failures |
| L4 | No localization | All | Single-language only |
| L5 | No accessibility labels | All | Accessibility issues |
| L6 | Hardcoded SYP currency symbol | All | No multi-currency |
| L7 | No Firebase Analytics | All | No user behavior data |
| L8 | `flutter_map` dead dependency in customer/driver | Customer, Driver | Unused bundle bloat |

---

## 8. Prioritized Execution Plan

### Phase A — Critical Fixes (Week 1-2)

| Task | Effort | Dependencies |
|---|---|---|
| **A1: Unify collection naming** — Standardize to `lowercase` across all Dart code, security rules, indexes, and Cloud Functions | 2-3 days | None |
| **A2: Fix Storage rules** — Remove catch-all public read, scope read per path | 0.5 day | None |
| **A3: Add transaction to OrderPlacementService** | 0.5 day | A1 |
| **A4: Add staging Firebase project** — Create `tayyebgo-staging`, add to `.firebaserc` | 1 day | Firebase Admin |
| **A5: Wire driver app to dispatch_requests** — Replace anything_requests with proper dispatch system | 2 days | A1 |
| **A6: Add Geolocator + GPS tracking to driver app** — Background location service | 2 days | None |
| **A7: Add pagination to RevenueService** — Query with limit/cursor | 0.5 day | A1 |
| **A8: Add `image_picker` to pubspec.yaml** in customer and partner apps | 0.5 day | None |
| **A9: Fix `PaymentSelectionSheet` callback** in checkout screen | 0.5 day | None |

### Phase B — Launch Requirements (Week 3-6)

| Task | Effort | Dependencies |
|---|---|---|
| **B1: Implement Stripe payment integration** — Replace stub with real Stripe SDK calls | 3-5 days | A1 |
| **B2: Implement FCM push delivery** — Send actual push notifications from admin and state machine | 2 days | None |
| **B3: Add real-time available requests to driver app** — Firestore stream subscription | 1 day | A1, A5 |
| **B4: Add live map to customer order tracking** — Embed `DriverLiveMap` widget | 1 day | None |
| **B5: Add live map + navigation to driver active delivery** | 1 day | None |
| **B6: Fix SOS/Report Issue to persist to Firestore** | 1 day | A1 |
| **B7: Implement SyncEngine retry limit + exponential backoff** | 1 day | None |
| **B8: Fix review update rule in firestore.rules** | 0.5 day | None |
| **B9: Add order lifecycle Cloud Functions** — Auto-assign, auto-notify | 2 days | A1 |
| **B10: Implement payout processing in TypeScript function** | 2 days | B1 |

### Phase C — Post-Launch Improvements (Week 7-12)

| Task | Effort | Dependencies |
|---|---|---|
| **C1: Add domain event system** — Event bus for order lifecycle | 3 days | None |
| **C2: Implement full test suite** — Unit + widget + integration tests | 5-10 days | None |
| **C3: Set up CI/CD in GitHub Actions** | 2 days | A4 |
| **C4: Add Crashlytics + Analytics** | 1 day | None |
| **C5: Implement multi-language localization** | 3 days | None |
| **C6: Add pagination to all Firestore list queries** | 2 days | None |
| **C7: Implement driver reassignment logic** | 2 days | A5 |
| **C8: Add CSV/PDF export to admin** | 2 days | None |
| **C9: Add Firebase Storage upload widget** | 1 day | None |
| **C10: Implement Tenants provider** | 2 days | None |
| **C11: Add road-aware ETA/distance service** | 3 days | None |
| **C12: Implement proper DI (get_it or riverpod)** | 3 days | None |

---

## 9. AI Implementation Tasks

### Task 1: Fix Firestore Collection Name Casing

**Objective:** Unify collection name casing to lowercase across all Dart code, security rules, indexes, and Cloud Functions

**Files/Packages affected:**
- `firestore.rules` — change all collection patterns to lowercase
- `firestore.indexes.json` — change all collection group names to lowercase
- All 4 apps — change `FirebaseFirestore.instance.collection('Users')` → `'users'` etc.
- `packages/tayyebgo_core/infrastructure/` — all repository implementations
- `functions/index.js` — all Firestore collection references
- `scripts/seed_firestore.js`

**Acceptance criteria:**
- Every Firestore collection reference in Dart code uses lowercase
- Security rules match exactly
- Indexes match exactly
- `firebase emulators:exec --only firestore` passes
- All screens that read/write Firestore work end-to-end

**Priority:** CRITICAL (Blocking C1)

---

### Task 2: Fix Storage Security Rules

**Objective:** Remove public read access on all files and scope permissions per path

**Files affected:** `storage.rules`

**Acceptance criteria:**
- No `allow read: if true` on catch-all path
- User profile pictures readable by authenticated users only
- Driver documents readable by driver + admin only
- Restaurant images readable by authenticated users only
- Uploads readable by owner + admin only

**Priority:** CRITICAL (Blocking C2)

---

### Task 3: Add Transaction to OrderPlacementService

**Objective:** Wrap Order creation + dispatch_request creation in a Firestore transaction

**Files affected:**
- `packages/tayyebgo_core/lib/infrastructure/services/order_placement_service.dart`

**Acceptance criteria:**
- Both documents written atomically
- If either write fails, both roll back
- No orphan Orders in the database

**Priority:** CRITICAL (Blocking C3)

---

### Task 4: Wire Driver App to Core Dispatch System

**Objective:** Replace `anything_requests` collection with `dispatch_requests` in driver app screens

**Files affected:**
- `apps/tayyebgo_driver/lib/screens/available_requests_screen.dart`
- `apps/tayyebgo_driver/lib/screens/active_delivery_screen.dart`
- `apps/tayyebgo_driver/lib/screens/driver_dashboard_screen.dart`
- `apps/tayyebgo_driver/lib/main.dart` (providers)

**Acceptance criteria:**
- Available requests screen reads from `dispatch_requests` where status = 'pending'
- Accept button calls `AutoDispatcher` or writes to `dispatch_requests`
- Active delivery screen reads from `dispatch_requests` where status = 'assigned'
- Status updates (pickedUp, delivered) write to both `dispatch_requests` and `Orders`

**Priority:** CRITICAL (Blocking C4)

---

### Task 5: Implement GPS Location Tracking in Driver App

**Objective:** Add background location service that publishes driver GPS to Firestore

**Files affected:**
- `apps/tayyebgo_driver/pubspec.yaml` — add `geolocator`, `workmanager`
- `apps/tayyebgo_driver/lib/screens/driver_dashboard_screen.dart` — start/stop tracking with online toggle
- New: `apps/tayyebgo_driver/lib/services/location_service.dart`
- `packages/tayyebgo_core/lib/infrastructure/services/driver_location_service.dart` — verify heartbeat logic

**Acceptance criteria:**
- Location updates every 10 seconds when driver is online
- `driver_locations` collection receives `{driverId, lat, lng, updatedAt}` documents
- Background updates continue when app is minimized
- Location stops when driver goes offline
- Battery-efficient (uses foreground service on Android, significant-change on iOS)

**Priority:** CRITICAL (Blocking C5)

---

### Task 6: Implement Stripe Payment Integration

**Objective:** Replace stub payment services with real Stripe SDK calls

**Files affected:**
- `packages/tayyebgo_core/pubspec.yaml` — add `stripe_sdk` or `stripe_flutter`
- `packages/tayyebgo_core/lib/infrastructure/services/stripe_checkout_service.dart`
- `packages/tayyebgo_core/lib/infrastructure/services/payment_gateway.dart`
- `packages/tayyebgo_core/lib/domain/services/i_payment_service.dart`
- New: `cloud_functions/functions/src/stripe_webhook.ts`

**Acceptance criteria:**
- Customer can pay with credit/debit card via Stripe Checkout
- PaymentIntent is created and confirmed
- Webhook handler captures payment and updates Order status
- Refund flow works via admin panel
- Platform commission is calculated and tracked
- Idempotency prevents duplicate charges

**Priority:** CRITICAL (Blocking C6)

---

### Task 7: Implement Payout Processing

**Objective:** Implement the payout pipeline from start to finish

**Files affected:**
- `cloud_functions/functions/src/index.ts` — full implementation of `processPayouts`
- `packages/tayyebgo_payout/lib/` — add `createPayout`, `processPayout`, `completePayout` methods

**Acceptance criteria:**
- Daily scheduled function queries completed orders in date range
- Groups by vendor, calculates net amount after commission
- Creates payout documents in Firestore
- Admin can review, approve, or reject payouts
- Payout status transitions correctly (pending → processing → completed/failed)

**Priority:** CRITICAL (Blocking C7)

---

### Task 8: Add Pagination to RevenueService

**Objective:** Prevent RevenueService from loading all documents at once

**Files affected:**
- `packages/tayyebgo_core/lib/infrastructure/services/revenue_service.dart`

**Acceptance criteria:**
- Revenue queries use `.limit()` with cursor pagination
- Date filtering happens in Firestore query (not client-side)
- Works with >100K orders

**Priority:** HIGH (Blocking H1)

---

### Task 9: Add Max Retry + Exponential Backoff to SyncEngine

**Objective:** Prevent infinite retry loop in offline sync

**Files affected:**
- `packages/tayyebgo_core/lib/infrastructure/services/sync_engine.dart`

**Acceptance criteria:**
- Configurable max retry limit (default: 5)
- Exponential backoff between retries (1s, 2s, 4s, 8s, 16s)
- Concurrency lock prevents simultaneous processing
- Failed operations are preserved for manual review
- Progress reporting via listener/callback

**Priority:** HIGH (Blocking H2)

---

### Task 10: Fix Safety Screen to Persist Reports

**Objective:** Make SOS and Issue Report dialogs write to Firestore

**Files affected:**
- `apps/tayyebgo_driver/lib/screens/driver_safety_screen.dart`

**Acceptance criteria:**
- SOS alert creates a document in `emergency_alerts` collection
- Issue report creates a document in `support_tickets` collection
- Both include driver ID, timestamp, and optional location
- Admin app has a view to see and respond to alerts
- Show loading/success/error feedback to driver

**Priority:** HIGH (Blocking H5)

---

### Task 11: Create Staging Firebase Project

**Objective:** Prevent accidental production deployments

**Files affected:**
- `.firebaserc`
- New: `tayyebgo-staging` Firebase project

**Acceptance criteria:**
- `firebase use staging` switches to staging project
- `firebase use default` stays on production
- CI/CD deploys to staging first, production on approval
- Staging has its own Firestore, Auth, and test data

**Priority:** CRITICAL (Blocking C8)

---

### Task 12: Add Dispatch Request Indexes

**Objective:** Ensure driver dispatch queries have required indexes

**Files affected:**
- `firestore.indexes.json` — add indexes for driver dispatch queries

**Acceptance criteria:**
- Index on `dispatch_requests` for `driverId + status + createdAt` (descending)
- Index on `dispatch_requests` for `status + createdAt` (descending)
- Index on `Orders` for `customerId + status + createdAt` (descending)
- All queries in driver app and AutoDispatcher are covered

**Priority:** HIGH (Blocking H8)

---

## Appendix: Audit Methodology

- All files were read in full (not summarized)
- Every screen, service, provider, and model was analyzed
- Firebase rules, indexes, functions, and config were tested against code queries
- Cross-referenced collection names in Dart code vs security rules vs indexes
- Architecture violations identified by tracing dependencies bottom-up
- Production readiness scored by evaluating: correctness, error handling, security, scalability, testing, documentation, and integration completeness
