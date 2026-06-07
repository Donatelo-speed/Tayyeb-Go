# Wave 2 Audit Report — Operational Readiness

**Date**: 2026-06-07
**Status**: AUDIT COMPLETE — NOT PRODUCTION READY

---

## Executive Summary

Two parallel delivery systems exist in the codebase that **do not connect**:

1. **Food Order Pipeline** (`orders` + `OrderStateMachine` + `AutoDispatcher`) — handles restaurant food ordering with a 9-state lifecycle and automatic driver scoring/dispatch
2. **"Anything" Delivery Pipeline** (`anything_requests` + `AnythingProvider`) — handles general shopping/courier requests with a 6-state lifecycle, fully implemented in the driver app

**The driver app only implements the "Anything" pipeline.** The food order dispatch system assigns drivers to orders via `dispatch_requests` and `AutoDispatcher`, but the driver app never reads these collections, never receives food-order notifications, and has no UI to accept or fulfill food deliveries.

**Readiness Score: 3/10** — Core infrastructure exists but critical disconnects prevent end-to-end deliveries.

---

## 1. Driver App ↔ Backend Integration Audit

### 1.1 Order Assignment

| Aspect | Finding | Severity |
|---|---|---|
| Food orders assigned to driver | **NOT IMPLEMENTED** — AutoDispatcher assigns to `dispatch_requests` but driver app never reads this collection | **CRITICAL** |
| "Anything" requests visible to driver | IMPLEMENTED — pull-based, one-time `.get()` query on `anything_requests` where `status == 'pending'` | OK |
| Real-time stream for available requests | NOT IMPLEMENTED — uses `.get()`, not `.snapshots()`. Driver must manually navigate to screen | MEDIUM |
| Push notification for new dispatch | NOT IMPLEMENTED — `sendDriverNotification()` exists but is **dead code** (never called) | **HIGH** |

**Evidence:**
- `auto_dispatcher.dart` assigns to `dispatch_requests` collection (lines 170-191)
- `available_requests_screen.dart` queries `anything_requests` only (line 99)
- `push_notification_service.dart` line 23 — `sendDriverNotification()` never called
- Driver app `main.dart` routes (lines 78-96) — no food order delivery route

### 1.2 Order Acceptance

| Aspect | Finding | Severity |
|---|---|---|
| "Anything" accept flow | IMPLEMENTED — `acceptRequest()` updates `anything_requests/{id}` status to `accepted` | OK |
| Food order accept flow | NOT IMPLEMENTED — no UI, no endpoint, no mechanism | **CRITICAL** |
| Driver accepts via push notification | NOT IMPLEMENTED | **HIGH** |

**Evidence:**
- `anything_provider.dart` lines 117-137 — `acceptRequest()` exists for Anything flow only
- No equivalent method for food orders anywhere
- `firebase_order_repository.dart` has `watchOrdersForDriver()` but it's never called from driver app

### 1.3 Driver Availability

| Aspect | Finding | Severity |
|---|---|---|
| Online/offline toggle | IMPLEMENTED in driver dashboard — writes to `driver_locations/{id}.isOnline` | OK |
| Auto-dispatcher reads online status | READS from `users` collection `isOnline` — **different** from what dashboard writes | **HIGH** |
| Online state persisted on restart | NOT IMPLEMENTED — always starts offline, no Firestore read on init | MEDIUM |
| `DriverLocationService` auto-start | NOT IMPLEMENTED — only starts when `DriverLiveMap` widget is on screen | **HIGH** |

**Evidence:**
- `driver_dashboard_screen.dart` lines 45-60 — writes `isOnline` to `driver_locations` collection
- `firebase_driver_repository.dart` lines 57-60 — `setOnlineStatus()` writes to `users` collection
- `auto_dispatcher.dart` line 103-117 — queries `users` for `isOnline == true` (not `driver_locations`)
- `driver_location_service.dart` — started from `driver_live_map.dart` only (line 33-40)
- Driver dashboard `_isOnline` initialized to `false` (line 14), never synced from Firestore

### 1.4 Delivery Completion

| Aspect | Finding | Severity |
|---|---|---|
| "Anything" completion | IMPLEMENTED — driver progresses through shopping → enRoute → delivered | OK |
| Food order completion | NOT IMPLEMENTED — no driver UI for picked_up → delivered transition | **CRITICAL** |
| Wallet update on completion | NOT IMPLEMENTED — `addEarnings()` exists but **never called** | **HIGH** |

**Evidence:**
- `anything_provider.dart` lines 139-157 — `updateStatus()` only updates `anything_requests`, no wallet call
- `driver_wallet_provider.dart` lines 53-95 — `addEarnings()` defined, zero callers across entire codebase

### 1.5 Cancellation Flow

| Aspect | Finding | Severity |
|---|---|---|
| Customer cancels food order | IMPLEMENTED via `OrderStateMachine.transition()` (only `placed`/`accepted`) | OK |
| Restaurant rejects order | IMPLEMENTED via `OrderStateMachine.rejectOrder()` | OK |
| Driver cancels delivery | NOT IMPLEMENTED — `cancelRequest()` exists on `AnythingProvider` but **not wired to any UI button** | MEDIUM |
| Food order cancellation after dispatch | NOT IMPLEMENTED — no code handles driver unassignment or re-dispatch | **HIGH** |

**Evidence:**
- `anything_provider.dart` lines 175-192 — `cancelRequest()` exists but unreachable from driver UI
- `order_state_machine.dart` lines 140-193 — `rejectOrder()` is restaurant-facing only

### 1.6 Failure Handling

| Aspect | Finding | Severity |
|---|---|---|
| Error catching in providers | IMPLEMENTED — try/catch on all provider methods, returns false/null | OK |
| User-facing error messages | PARTIAL — `ErrorRetryWidget` in some screens, silent failures in others | MEDIUM |
| Offline queue | EXISTS but **not wired** to driver provider calls | **HIGH** |
| Silent error suppression | EXISTS in critical paths — `driver_location_service.dart` line 74, `auto_dispatcher.dart` line 188 | MEDIUM |

**Evidence:**
- `sync_engine.dart` and `offline_queue.dart` exist but are never integrated with `AnythingProvider` or `DriverWalletProvider`
- `driver_location_service.dart` line 74: `.catchError((_) {})` — location update fails silently
- `auto_dispatcher.dart` line 188: `.catchError((_) {})` — driver assignment update fails silently

---

## 2. Driver GPS Tracking Audit

### 2.1 Implementation Status

| Feature | Status | Evidence |
|---|---|---|
| Foreground tracking | **IMPLEMENTED** — Geolocator stream, 20m distance filter, high accuracy | `driver_location_service.dart` lines 17-31 |
| Background tracking | **NOT IMPLEMENTED** — no flutter_background_service, no Android foreground notification, no iOS background modes | Entire codebase search — zero references |
| Online/offline state | **PARTIAL** — toggle exists but stored in wrong collection for dispatcher | See 1.3 |
| Realtime updates | **PARTIAL** — works only when `DriverLiveMap` widget is mounted | `driver_live_map.dart` lines 33-40 |
| Battery optimization | **NOT IMPLEMENTED** — always high accuracy, no adaptive accuracy, no reduced polling when idle | `driver_location_service.dart` line 27 |
| Location throttling | **IMPLEMENTED** — 5-second minimum interval, 20m distance filter | `driver_location_service.dart` lines 51, 22 |
| Geohash encoding | **IMPLEMENTED** — precision 4 (~20km grid) | `driver_location_service.dart` line 62 |

### 2.2 Gaps

| Gap | Severity | Details |
|---|---|---|
| No background tracking | **CRITICAL** | Driver app stops updating location when minimized or screen off. ETA becomes stale, customer tracking breaks. |
| Service only runs on live map | **HIGH** | `DriverLocationService.start()` is only called from `DriverLiveMap` widget. No background service. |
| No geofencing | MEDIUM | No arrival/departure detection for store or customer locations |
| Silent `users` update failure | MEDIUM | Location write to `users` collection suppresses errors — driver position in `users` may be stale |
| No adaptive accuracy | MEDIUM | Always uses `LocationAccuracy.high` — unnecessary battery drain when driver is stationary |
| No location permissions handling | MEDIUM | No runtime permission request/deny handling in `DriverLocationService` |

---

## 3. Dispatch Workflow Audit

### 3.1 Implementation Status

| Feature | Status | Evidence |
|---|---|---|
| Driver scoring algorithm | **IMPLEMENTED** — ETA(40%) + Rating(25%) + Load(20%) + Distance(15%) | `driver_scorer.dart` lines 16-52 |
| Assignment via transaction | **PARTIAL** — dispatch update inside txn, user update outside | `auto_dispatcher.dart` lines 170-191 |
| Store driver first routing | **IMPLEMENTED** — tries store drivers before platform | `auto_dispatcher.dart` lines 59-77 |
| Platform fallback with delay | **IMPLEMENTED** — configurable delay (default 30s) | `auto_dispatcher.dart` lines 194-205 |
| Driver overload detection | **IMPLEMENTED** — threshold: 80% of drivers with 3+ deliveries | `auto_dispatcher.dart` lines 79-92 |

### 3.2 Gaps

| Gap | Severity | Details |
|---|---|---|
| **No reassignment logic** | **CRITICAL** | Once a driver is assigned, there is no code path to unassign and retry. Status flow: `pending → scoring → assigned` (terminal for assignment). |
| **No driver acceptance timeout** | **CRITICAL** | No timer starts when driver is assigned. The driver has infinite time to accept, and there's no auto-unassign. |
| **No driver rejection for food orders** | **CRITICAL** | Driver cannot reject a food dispatch. `OrderStateMachine.rejectOrder()` is for restaurants. |
| **No-driver-available does not retry** | **HIGH** | When no driver found, status is set to `unassigned` or `overloaded` with no retry mechanism. Order is stranded. |
| Race condition in assignment | **HIGH** | `user.update` (lines 186-189) is OUTSIDE the transaction with `.catchError(_)`. Assignment succeeds in dispatch_requests but driver's `currentOrderId` may not update. |
| Fallback delay is blocking | MEDIUM | `Future.delayed` on the main dispatch thread — blocks other dispatches during the 30s wait. |

**Evidence:**
- `auto_dispatcher.dart` — no `reassign()`, `unassign()`, or `timeoutDriver()` methods exist
- Dispatch status flow: `pending → scoring → assigned | unassigned | overloaded` — one-directional
- Reassignment search: zero results across entire codebase
- Driver rejection search: zero results for food order rejection
- Transaction at `auto_dispatcher.dart` lines 170-191 vs user update at lines 186-189

---

## 4. Order Lifecycle Validation

### 4.1 Parallel State Systems

There are **two independent order status enums** with different state sets and no mapping between them:

| Status Position | Domain (`OrderStatus`) | Data (`OrderStatusEx`) |
|---|---|---|
| 1 | `placed` | `pending` |
| 2 | `accepted` | `accepted` |
| 3 | `preparing` | `preparing` |
| 4 | `ready` | *(missing)* |
| 5 | `readyForDriver` | `readyForDriver` |
| 6 | `dispatched` | *(missing)* |
| 7 | `pickedUp` | `pickedUp` |
| 8 | `delivered` | `delivered` |
| 9 | `cancelled` | `cancelled` |

**Evidence:**
- `domain/enums/order_status.dart` lines 1-20 — 9-status enum
- `src/models/order_model.dart` lines 3-50 — 7-status enum

### 4.2 Transition Validation Mismatch

**Domain (`OrderStateMachine`) transitions:**
```
placed → [accepted, cancelled]
accepted → [preparing, cancelled]
preparing → [ready, cancelled]
ready → [readyForDriver, cancelled]
readyForDriver → [dispatched, cancelled]
dispatched → [pickedUp, cancelled]
pickedUp → [delivered, cancelled]
```
*Source: `order_state_machine.dart` lines 7-17*

**Data (`OrderRepository`) transitions:**
```
pending → [accepted, cancelled]
accepted → [preparing, cancelled]
preparing → [readyForDriver, cancelled]
readyForDriver → [pickedUp, cancelled]
pickedUp → [delivered, cancelled]
```
*Source: `order_repository.dart` lines 285-293*

**Key differences:**
- Data layer skips `ready` and `dispatched` — `preparing` jumps directly to `readyForDriver`
- This means cashier terminal (`preparing → ready → readyForDriver`) and kitchen mode (`preparing → readyForDriver`) produce **different state flows** for the same order
- If a status is written by the domain layer (`dispatched`), the data layer's `OrderStatusEx.fromString()` cannot parse it

### 4.3 Race Conditions

| Issue | Severity | Details |
|---|---|---|
| No transactions in status transitions | **HIGH** | `OrderStateMachine.transition()` uses `doc.update()` — two drivers or a driver+cashier could race on the same order |
| AutoDispatcher skips state machine | **HIGH** | `assignDriver()` in data layer repo (line 209-233) writes to `orders` directly without calling `OrderStateMachine.transition()` |
| Dual write paths for driver assignment | **HIGH** | AutoDispatcher writes to `dispatch_requests` AND `users` (outside transaction). Data repo writes to `orders` directly. Two systems updating different collections without coordination. |

**Evidence:**
- `order_state_machine.dart` line 65: `FirebaseFirestore.instance.collection('orders').doc(orderId)` — no transaction
- `order_repository.dart` lines 199-233: `assignDriver()` updates `orders` doc directly
- `auto_dispatcher.dart` lines 170-191: updates `dispatch_requests` via txn but `users` outside txn

### 4.4 Missing States and Invalid Transitions

| Issue | Severity | Details |
|---|---|---|
| `ready` state maybe unreachable from kitchen UI | MEDIUM | Kitchen mode transitions `preparing → readyForDriver`, skipping `ready`. Any code listening for `ready` will miss it. |
| No `rejected` or `expired` status | MEDIUM | Orders are cancelled rather than rejected/expired — no ability to differentiate |
| `pending` vs `placed` inconsistency | MEDIUM | OrderPlacementService writes `placed` (domain). OrderRepository looks for `pending` (data). If domain system creates the order, data system may not find it. |

---

## 5. Cash On Delivery Audit

### 5.1 Implementation Status

| Feature | Status | Evidence |
|---|---|---|
| COD payment method selection | **IMPLEMENTED** | `payment_selection_sheet.dart` — customer selects "Sham Cash" |
| Payment intent creation | **IMPLEMENTED** | `sham_cash_service.dart` — creates `payment_intents` doc |
| Driver marks delivery complete | **PARTIAL** — only for "Anything" requests | `active_delivery_screen.dart` lines 101-143 |
| Driver wallet `addEarnings()` | **IMPLEMENTED but NEVER CALLED** | `driver_wallet_provider.dart` lines 53-95 |
| Commission calculation | **IMPLEMENTED** | `commission_calculator.dart` — simple percent formula |
| Restaurant payout generation | **IMPLEMENTED but NEVER CALLED** | `revenue_service.dart` lines 82-105 |
| Settlement view in admin | **IMPLEMENTED** | `settlements_view.dart` — manual admin UI |

### 5.2 Gaps

| Gap | Severity | Details |
|---|---|---|
| **No wallet update on delivery** | **CRITICAL** | `addEarnings()` is defined but has zero callers. After a delivery is completed, the driver's wallet is never updated. |
| **No cash collection verification** | **CRITICAL** | Driver marks "Delivered" but there is no step to confirm cash was collected. COD amount is never recorded as collected. |
| **No automated settlement** | **HIGH** | `revenue_service.generatePayout()` creates payout docs but is never called by any scheduled job or workflow. |
| **Duplicate earning fields** | MEDIUM | `DriverModel` has `pendingPayout`/`totalEarnings` (lines 46-47 in `driver_model.dart`) separate from `driver_wallets` collection. No sync between them. |
| No commission applied to earnings | **HIGH** | CommissionCalculator exists but earnings are never adjusted for commission. Driver gets full order value? |
| `processPayouts` cloud function is skeleton | **HIGH** | `cloud_functions/functions/src/index.ts` line 11 — `console.log` only, no actual payout logic |
| No payment reconciliation | MEDIUM | No way to verify COD amounts collected match order totals |

**Evidence:**
- `driver_wallet_provider.dart` lines 53-95 — `addEarnings()` defined, grep for callers: **zero results**
- `anything_provider.dart` lines 139-157 — `updateStatus()` sets `deliveredAt` but never calls wallet
- `revenue_service.dart` lines 82-105 — `generatePayout()` never called
- `cloud_functions/functions/src/index.ts` lines 11-26 — skeleton function with "TODO"
- `commission_calculator.dart` — exists, never imported or used by any caller

---

## 6. Readiness Score

### Scoring Rubric

| Category | Score | Weight |
|---|---|---|
| Driver App ↔ Backend Integration | 2/10 | 30% |
| Driver GPS Tracking | 4/10 | 20% |
| Dispatch Workflow | 2/10 | 25% |
| Order Lifecycle | 4/10 | 15% |
| Cash On Delivery | 1/10 | 10% |

**Weighted Score: 2.6/10** (rounded to **3/10**)

### Critical Blockers (must fix before production)

1. **Food order dispatch is not connected to the driver app** — The core delivery loop is broken
2. **No driver acceptance/rejection for food orders** — Drivers cannot respond to dispatches
3. **No reassignment or timeout logic** — A single unresponsive driver blocks the order permanently
4. **No wallet update on delivery** — Drivers are never paid
5. **No background GPS tracking** — Customer tracking breaks when app is minimized

---

## 7. Implementation Tasks (Recommendations)

### Phase 1 — Critical Path

| Task | Affected Files | Complexity |
|---|---|---|
| Connect driver app to food `dispatch_requests` collection | `driver_dashboard_screen.dart`, `active_delivery_screen.dart`, `auto_dispatch_listener.dart` | High |
| Implement driver accept/reject for food dispatches | New driver UI + `OrderStateMachine` integration | Medium |
| Add assignment timeout + auto-reassignment logic | `auto_dispatcher.dart` | Medium |
| Wire `addEarnings()` to delivery completion flow | `anything_provider.dart`, `order_state_machine.dart`, `driver_wallet_provider.dart` | Low |
| Implement background location service | New service file + platform configs | High |

### Phase 2 — High Priority

| Task | Affected Files | Complexity |
|---|---|---|
| Unify `OrderStatus` and `OrderStatusEx` into single enum | Multiple files across domain, data, and UI layers | High |
| Add Firestore transactions to all status transitions | `order_state_machine.dart` | Medium |
| Fix online state desync between `driver_locations` and `users` | `driver_dashboard_screen.dart`, `firebase_driver_repository.dart` | Low |
| Implement COD payment verification step | `active_delivery_screen.dart`, new provider logic | Medium |
| Add automated settlement/payout schedule | `cloud_functions/functions/src/index.ts` | Medium |

### Phase 3 — Improvements

| Task | Affected Files | Complexity |
|---|---|---|
| Add adaptive location accuracy for battery optimization | `driver_location_service.dart` | Low |
| Add geofencing for store arrival/departure | `driver_location_service.dart`, new geofence service | Medium |
| Wire offline queue to driver provider calls | `anything_provider.dart`, `driver_wallet_provider.dart` | Medium |
| Remove silent error suppression in critical paths | `auto_dispatcher.dart`, `driver_location_service.dart` | Low |
| Add push notifications for driver dispatch | `push_notification_service.dart`, new cloud function | Medium |

---

## 8. Affected Files Index

| File | Role | Issues |
|---|---|---|
| `apps/tayyebgo_driver/lib/screens/available_requests_screen.dart` | Driver UI | Only handles Anything requests, no food order UI |
| `apps/tayyebgo_driver/lib/screens/driver_dashboard_screen.dart` | Driver UI | Online state stored wrong collection, never synced on restart |
| `apps/tayyebgo_driver/lib/screens/active_delivery_screen.dart` | Driver UI | Only handles Anything deliveries, no COD step, no wallet update |
| `packages/tayyebgo_core/lib/infrastructure/services/auto_dispatcher.dart` | Dispatch engine | No reassignment, no timeout, race condition in user update |
| `packages/tayyebgo_core/lib/infrastructure/services/order_state_machine.dart` | Order lifecycle | No transactions, dual state system, no driver dispatch integration |
| `packages/tayyebgo_core/lib/infrastructure/services/driver_location_service.dart` | GPS tracking | No background mode, only runs in live map widget |
| `packages/tayyebgo_core/lib/src/providers/anything_provider.dart` | Anything state | No wallet update on delivery, cancel not wired to UI |
| `packages/tayyebgo_core/lib/src/providers/driver_wallet_provider.dart` | Wallet | `addEarnings()` is dead code — zero callers |
| `packages/tayyebgo_core/lib/infrastructure/services/revenue_service.dart` | Payouts | `generatePayout()` is dead code — zero callers |
| `packages/tayyebgo_core/lib/infrastructure/services/commission_calculator.dart` | Commissions | Never imported or used anywhere |
| `packages/tayyebgo_core/lib/infrastructure/services/push_notification_service.dart` | Notifications | `sendDriverNotification()` is dead code |
| `packages/tayyebgo_core/lib/infrastructure/repositories/firebase_driver_repository.dart` | Driver data | `isOnline` writes to wrong collection |
| `packages/tayyebgo_core/lib/domain/enums/order_status.dart` | Domain statuses | 9-status system, conflicts with data layer |
| `packages/tayyebgo_core/lib/src/models/order_model.dart` | Data statuses | 7-status system, missing `ready` and `dispatched` |
| `packages/tayyebgo_core/lib/src/repositories/order_repository.dart` | Data order ops | Own transition map, different from domain |
| `packages/tayyebgo_core/lib/domain/enums/anything_request_status.dart` (missing) | Anything status | Status enum is in `anything_request_model.dart`, not in domain |
| `cloud_functions/functions/src/index.ts` | Payout scheduler | Skeleton only — no real payout logic |
| `functions/index.js` | Notifications/FCM | Only handles push delivery to devices |

---

## 9. Firestore Collection Usage Map

| Collection | Read By Driver | Written By Driver | Read By Dispatcher | Written By Dispatcher |
|---|---|---|---|---|
| `orders` | **NO** | **NO** | NO | YES (via repo) |
| `anything_requests` | YES | YES | NO | NO |
| `dispatch_requests` | **NO** | **NO** | YES | YES |
| `driver_locations` | YES (dashboard toggle) | YES (location) | YES (ETA) | NO |
| `users` | YES (profile) | YES (location, online) | YES (online query) | YES (assignment) |
| `driver_wallets` | YES | YES (payout request) | NO | NO |
| `restaurants` | NO | NO | YES (store config) | NO |
| `notifications` | NO | NO | NO | NO (written by state machine) |

***The driver app has zero reads from `orders` and `dispatch_requests` — the two collections that carry food dispatch data.***

---

## Notes

- This audit is static code analysis only. Runtime behavior may differ.
- No code was modified during this audit.
- The "Anything" pipeline is functionally complete for courier/general delivery but disconnected from food ordering.
- Two Pipelines exist: `anything_requests` (driver-facing, complete) and `orders` + `dispatch_requests` (food, incomplete integration).
