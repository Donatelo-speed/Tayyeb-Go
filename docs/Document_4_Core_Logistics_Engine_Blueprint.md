# Document 4 — Core Logistics Engine Blueprint

**The Piece That Decides If All Apps Actually Work Together**

---

## What This Document Answers

"Everything connects through the engine. If the engine is broken, nothing works."

This is the single most critical document in the entire system.

Because TayybeGo is not 4 apps. It is 4 apps **connected by one engine**.

The engine decides:
- Who gets which order
- When a driver is assigned
- How status flows through the system
- What notifications fire
- How money moves

If the engine is wrong, the apps are just pretty screens.

---

## Current State: What Actually Exists

### What Works (Verified in Code)

| Component | Status | Location |
|---|---|---|
| Order State Machine | Exists, 11 states, valid transitions | `order_state_machine.dart:8-21` |
| Auto-Dispatcher | Exists, creates dispatch_requests | `auto_dispatcher.dart:11-98` |
| Driver Scorer | Exists, 5-factor weighted model | `driver_scorer.dart:7-87` |
| Dispatch Provider | Exists, streams to driver app | `dispatch_provider.dart:6-157` |
| Notification System | Exists, Firestore → FCM | `notifications.js:1-94` |
| Driver Earnings | Exists, credits wallet on delivery | `delivery_earnings_service.dart:3-75` |
| Accept/Reject UI | Exists in driver app | `available_requests_screen.dart` |
| Active Delivery UI | Exists for food + Anything | `active_delivery_screen.dart` |
| Cloud Function: Dispatch Created | Exists, triggers scoring | `dispatch.js:3-20` |
| Cloud Function: Dispatch Accepted | Exists, updates order to dispatched | `dispatch.js:22-40` |
| Cloud Function: Timeout Check | Exists, runs every 30 min | `dispatch.js:42-82` |

### What Is Broken (Critical)

| Issue | Severity | Impact |
|---|---|---|
| Driver never gets push notification for new food dispatch | **CRITICAL** | Drivers don't know they have a new order |
| Online/offline state stored in wrong collection | **CRITICAL** | Dispatcher can't find online drivers |
| Background GPS tracking stops when app minimized | **CRITICAL** | Customer can't track driver in real-time |
| Timeout check runs every 30 min, not every 30 sec | **HIGH** | Drivers wait up to 30 min for reassignment |
| Anything delivery completion never credits wallet | **HIGH** | Drivers lose money on Anything orders |
| `sendDriverNotification()` exists but is never called | **HIGH** | Dead code — dispatch assignment is silent |
| Race condition: `users` doc update outside transaction | **HIGH** | Can corrupt `activeDeliveries` count |
| Commission calculator exists but is never used | **MEDIUM** | Revenue tracking incomplete |
| No real-time streaming for available requests | **MEDIUM** | Driver sees stale data |
| Offline queue exists but is not wired | **LOW** | Offline actions lost |

---

## The Engine Architecture

### The 5 Subsystems

```
┌─────────────────────────────────────────────────────────────┐
│                    CORE LOGISTICS ENGINE                      │
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   ORDER     │  │   DISPATCH  │  │   NOTIFICATION      │  │
│  │   STATE     │  │   SYSTEM    │  │   SYSTEM            │  │
│  │   MACHINE   │  │             │  │                     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                      │             │
│  ┌──────┴──────────────┴──────────────────────┴──────────┐  │
│  │              DRIVER MATCHING ENGINE                     │  │
│  │  (Scoring + GPS + Availability + Workload)             │  │
│  └──────────────────────┬────────────────────────────────┘  │
│                         │                                    │
│  ┌──────────────────────┴────────────────────────────────┐  │
│  │              MONEY & SETTLEMENT ENGINE                  │  │
│  │  (Pricing + Commission + Earnings + Payouts)           │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

Each subsystem has:
- A single source of truth (code location)
- Clear inputs and outputs
- Defined failure modes
- Testable boundaries

---

## Subsystem 1: Order State Machine

### The 11 States

```
placed → accepted → preparing → ready → readyForDriver → dispatched → pickedUp → delivered
  │         │           │          │            │              │           │
  └─────────┴───────────┴──────────┴────────────┴──────────────┴───────────┴──→ cancelled
                                                                          └──→ refunded
```

### State Definitions

| State | Who Sets It | What It Means | Next Valid States |
|---|---|---|---|
| `placed` | Customer | Order submitted, waiting for restaurant | `accepted`, `cancelled` |
| `pending` | System | Alias for `placed` (legacy) | Maps to `placed` via `canonicalValue` |
| `accepted` | Restaurant | Restaurant confirmed order | `preparing`, `cancelled` |
| `preparing` | Restaurant | Food being made | `ready`, `cancelled` |
| `ready` | Restaurant | Food ready for pickup | `readyForDriver`, `cancelled` |
| `readyForDriver` | Restaurant | Awaiting driver assignment | `dispatched`, `cancelled` |
| `dispatched` | System (Cloud Function) | Driver assigned and en route | `pickedUp`, `cancelled` |
| `pickedUp` | Driver | Driver has the food | `delivered`, `cancelled` |
| `delivered` | Driver | Complete — triggers wallet credit | `refunded` |
| `cancelled` | Anyone (with rules) | Order cancelled | Terminal |
| `refunded` | Admin | Post-delivery refund | Terminal |

### Transition Rules (Code)

From `order_state_machine.dart:9-21`:

```dart
static const _canonicalPipeline = {
  OrderStatus.placed: [OrderStatus.accepted, OrderStatus.cancelled],
  OrderStatus.pending: [OrderStatus.accepted, OrderStatus.cancelled],
  OrderStatus.accepted: [OrderStatus.preparing, OrderStatus.cancelled],
  OrderStatus.preparing: [OrderStatus.ready, OrderStatus.cancelled],
  OrderStatus.ready: [OrderStatus.readyForDriver, OrderStatus.cancelled],
  OrderStatus.readyForDriver: [OrderStatus.dispatched, OrderStatus.cancelled],
  OrderStatus.dispatched: [OrderStatus.pickedUp, OrderStatus.cancelled],
  OrderStatus.pickedUp: [OrderStatus.delivered, OrderStatus.cancelled],
  OrderStatus.delivered: [OrderStatus.refunded],
  OrderStatus.cancelled: [],
  OrderStatus.refunded: [],
};
```

### Who Can Do What

| Actor | Can Transition To | Cannot Transition To |
|---|---|---|
| Customer | `cancelled` (from `placed`/`pending`) | Any other state |
| Restaurant | `accepted`, `preparing`, `ready`, `readyForDriver`, `cancelled` | `dispatched`, `pickedUp`, `delivered` |
| Driver | `pickedUp`, `delivered` | `accepted`, `preparing`, `ready` |
| System | `dispatched` (via Cloud Function) | `placed`, `accepted`, `preparing` |
| Admin | `refunded`, `cancelled` (any state) | — |

### Side Effects on Transition

When `OrderStateMachine.transition()` is called:

1. **Validates** the transition is allowed
2. **Updates** the order document (status + statusHistory)
3. **If `delivered`**: Credits driver wallet via `DeliveryEarningsService`
4. **If any status**: Sends push notification to customer via `PushNotificationService`

### What Needs Fixing

| Problem | Fix |
|---|---|
| `pending` is a legacy alias that confuses the state machine | Remove `pending` from UI, keep only in `canonicalValue` mapping |
| No notification to restaurant on status changes | Add `sendPartnerNotification()` calls |
| No notification to driver on dispatch assignment | Call `sendDriverNotification()` (currently dead code) |
| Status history has no location on pickup/delivery | Capture GPS in transition calls |

---

## Subsystem 2: Dispatch System

### The Dispatch Lifecycle

```
Customer places order
    ↓
Restaurant marks "readyForDriver"
    ↓
OrderStateMachine sets status: readyForDriver
    ↓
Someone (MISSING) creates dispatch_request in Firestore
    ↓
Cloud Function onDispatchCreated triggers
    ↓
AutoDispatcher.findAndAssignDriver() runs
    ↓
DriverScorer evaluates candidates
    ↓
Best driver gets: awaiting_acceptance
    ↓
Driver accepts → Cloud Function onDispatchAccepted
    ↓
Order status → dispatched
    ↓
Driver picks up → pickedUp
    ↓
Driver delivers → delivered → wallet credited
```

### The Missing Link

**Problem**: Who creates the `dispatch_request`?

Looking at the code:
- `OrderStateMachine.transition()` updates order to `readyForDriver` but does NOT create a dispatch request
- The Cloud Function `onDispatchCreated` listens for new `dispatch_requests` documents
- But nothing creates that document automatically

**Current Flow (Broken)**:
```
Order → readyForDriver → ??? → dispatch_request created → AutoDispatcher runs
```

**Required Fix**:
```
Order → readyForDriver → OrderStateMachine creates dispatch_request → AutoDispatcher runs
```

### Dispatch Request Schema

From `domain-model.md:203-245`:

| Field | Type | Source |
|---|---|---|
| id | String | Auto-generated |
| orderId | String | From order |
| brandId | String | From restaurant |
| branchId | String | From restaurant |
| storeId | String | From restaurant |
| pickupLat/pickupLon | double | Restaurant location |
| dropoffLat/dropoffLon | double | Customer address |
| status | String | Lifecycle status |
| assignedDriverId | String? | Set by scorer |
| candidateScores | List? | Ranked drivers |
| skippedDriverIds | List? | For reassignment |
| acceptanceDeadline | Timestamp | 45s from assignment |
| acceptanceTimeoutSeconds | int | Default 45 |

### Dispatch Status Lifecycle

```
pending → scoring → awaiting_acceptance → accepted
    │         │              │
    │         │              └──→ timedOut → reassigning → scoring (loop)
    │         │              └──→ unassigned → reassigning → scoring (loop)
    │         └──→ overloaded
    └──→ fallback_waiting → scoring (platform drivers)
```

### The Fix: Auto-Dispatch Trigger

Add to `OrderStateMachine.transition()` at `readyForDriver`:

```dart
case OrderStatus.readyForDriver:
  updates['readyForDriverAt'] = DateTime.now().toIso8601String();
  // CREATE DISPATCH REQUEST
  await _createDispatchRequest(
    orderId: orderId,
    restaurantId: data['restaurantId'],
    customerId: data['customerId'],
    deliveryAddress: data['deliveryAddress'],
  );
```

This is the single most important missing piece.

---

## Subsystem 3: Driver Matching Engine

### The 5-Factor Scoring Model

From `driver_scorer.dart:12-16`:

| Factor | Weight | What It Measures | Normalization | Optimal |
|---|---|---|---|---|
| Distance to pickup | 40% | Physical km from driver to restaurant | 0.5-20km range | Closer = better |
| Rating | 20% | Customer rating (1-5) | rating / 5.0 | Higher = better |
| Completed deliveries | 20% | Experience level | 0-5000 range | More = better |
| Workload | 10% | Current active deliveries | 1.0 − (count × 0.25) | Fewer = better |
| Subscription | 10% | Has active subscription | 1.0 or 0.0 | Subscribed = better |

### Scoring Formula

```
score = (distanceScore × 0.40) +
        (ratingScore × 0.20) +
        (completionScore × 0.20) +
        (workloadScore × 0.10) +
        (subscriptionScore × 0.10)
```

### Where It Reads Driver Data

| Data Point | Source Collection | Problem |
|---|---|---|
| `currentLocation` | `users` doc | ✅ Works |
| `rating` | `users` doc | ✅ Works |
| `completedDeliveries` | `users` doc | ✅ Works |
| `activeDeliveries` | `users` doc | ⚠️ Race condition (outside transaction) |
| `isSubscribed` | `users` doc | ✅ Works |
| `isOnline` | `driver_locations` collection | ❌ **WRONG** — Dispatcher reads from `users` |
| `driverType` | `users` doc | ✅ Works |

### Online/Offline State Bug

**Current**:
- Driver app writes `isOnline` to `driver_locations/{driverId}`
- AutoDispatcher reads `isOnline` from `users/{driverId}` (via `FirebaseDriverRepository.watchOnlinePlatformDrivers()`)

**Fix**:
- Write `isOnline` to BOTH `users/{driverId}` AND `driver_locations/{driverId}`
- OR change dispatcher to read from `driver_locations`

### Overload Detection

From `auto_dispatcher.dart:137-142`:

```dart
bool _isOverloaded(List<Driver> drivers) {
  final activeCount = drivers.where((d) => d.activeDeliveries >= 3).length;
  final totalOnline = drivers.length;
  if (totalOnline == 0) return true;
  return (activeCount / totalOnline) > 0.8;
}
```

If >80% of online drivers have 3+ active deliveries, the system marks the dispatch as `overloaded` instead of assigning.

### Reassignment Logic

From `auto_dispatcher.dart:282-373`:

When a driver rejects or times out:
1. Add driver to `skippedDriverIds` list
2. Re-run scoring excluding skipped drivers
3. If no drivers left → mark `unassigned`
4. If unassigned → admin needs to intervene

---

## Subsystem 4: Notification System

### How Notifications Flow

```
Business logic writes to Firestore:
  notifications/{id}
    ↓
Cloud Function onNotificationCreated triggers
    ↓
Looks up recipient's fcmToken from users/{recipientId}
    ↓
Sends FCM push via admin.messaging().send()
    ↓
Invalid tokens → set fcmToken = null
```

### Notification Types

From `notification_templates.dart`:

| Type | Recipient | When |
|---|---|---|
| `order_update` | Customer | Any order status change |
| `partner_order_update` | Restaurant | Order status change |
| `driver_notification` | Driver | Dispatch assignment |
| `sos_emergency` | Admin | Driver SOS alert |

### What's Missing

| Missing Notification | When It Should Fire | Who Receives |
|---|---|---|
| Dispatch assignment | Driver gets `awaiting_acceptance` | Driver |
| Order ready for pickup | Restaurant marks `readyForDriver` | Driver (if assigned) |
| Driver arrived | Driver taps "arrived at restaurant" | Customer |
| Driver en route | Driver taps "picked up" | Customer |
| Delivery complete | Driver marks `delivered` | Customer + Restaurant |
| New order received | Order placed | Restaurant |
| Order cancelled | Any cancellation | Restaurant + Driver |

### The Dead Code Problem

`PushNotificationService.sendDriverNotification()` exists at `push_notification_service.dart:34-47` but is **never called** by the AutoDispatcher.

**Fix**: When `_scoreAndAssign()` sets status to `awaiting_acceptance`, also call:

```dart
await PushNotificationService().sendDriverNotification(
  driverId: best.driverId,
  orderId: dispatchRequestId,
  action: 'new_dispatch',
);
```

---

## Subsystem 5: Money & Settlement Engine

### How Money Flows

```
Customer pays order total
    ↓
Payment recorded in payments/{id}
    ↓
On delivery: DeliveryEarningsService.creditEarnings()
    ↓
Driver wallet: balance += deliveryFee × (1 - commission/100)
    ↓
Restaurant payout: order total − commission
    ↓
Daily: processPayouts Cloud Function generates payout docs
```

### Commission Model

| Component | Default | Notes |
|---|---|---|
| Platform commission | 15% | Configurable per restaurant |
| Driver earnings | deliveryFee × (1 − commission/100) | Credited on `delivered` |
| Restaurant receives | orderTotal − commission | Settled daily |

### What's Broken

| Issue | Impact |
|---|---|
| Anything delivery completion never calls `creditEarnings()` | Drivers lose money |
| `CommissionCalculator` exists but is never used | Revenue tracking incomplete |
| `RevenueService.generatePayout()` never called | Payouts are manual |
| Default delivery fee is hardcoded (5000) | Should come from dispatch zone |

---

## The Connection Map: How Apps Talk Through the Engine

### Customer App → Engine

| Customer Action | Engine Service | Firestore Write | Engine Response |
|---|---|---|---|
| Places order | `OrderPlacementService` | `orders/{id}` | Validates, sets `placed` |
| Cancels order | `OrderStateMachine.transition()` | `orders/{id}` | Sets `cancelled` |
| Rates delivery | `ReviewService` | `reviews/{id}` | Updates driver rating |
| Tracks order | `AutoDispatcher.watchDispatchRequest()` | Reads `dispatch_requests` | Streams location |

### Partner App → Engine

| Partner Action | Engine Service | Firestore Write | Engine Response |
|---|---|---|---|
| Accepts order | `OrderStateMachine.transition()` | `orders/{id}` | Sets `accepted` |
| Marks preparing | `OrderStateMachine.transition()` | `orders/{id}` | Sets `preparing` |
| Marks ready | `OrderStateMachine.transition()` | `orders/{id}` | Sets `ready` |
| Marks ready for driver | `OrderStateMachine.transition()` | `orders/{id}` | Sets `readyForDriver` + **creates dispatch** |
| Rejects order | `OrderStateMachine.rejectOrder()` | `orders/{id}` | Sets `cancelled` + notifies customer |

### Driver App → Engine

| Driver Action | Engine Service | Firestore Write | Engine Response |
|---|---|---|---|
| Goes online | `DriverLocationService` | `users/{id}` + `driver_locations/{id}` | Sets `isOnline = true` |
| Accepts dispatch | `DispatchProvider.acceptDispatch()` | `dispatch_requests/{id}` | Sets `accepted` + order → `dispatched` |
| Rejects dispatch | `DispatchProvider.rejectDispatch()` | `dispatch_requests/{id}` | Triggers `reassignDriver()` |
| Picks up order | `DispatchProvider.markPickedUp()` | `dispatch_requests/{id}` | Sets `pickedUp` |
| Completes delivery | `DispatchProvider.completeDelivery()` | `dispatch_requests/{id}` | Sets `delivered` + credits wallet |
| Sends SOS | `onSOSEmergency` Cloud Function | `sos_alerts/{id}` | Notifies admin |

### Admin App → Engine

| Admin Action | Engine Service | Firestore Write | Engine Response |
|---|---|---|---|
| Overrides order | `OrderStateMachine.transition()` | `orders/{id}` | Any transition allowed |
| Manages drivers | Direct Firestore | `users/{id}` | Updates driver status |
| Views analytics | `RevenueService` | Reads collections | Aggregates data |
| Processes payouts | `processPayouts` Cloud Function | `payouts/{id}` | Generates payout docs |

---

## The 7 Critical Fixes

These are ordered by impact. Fix them in this order.

### Fix 1: Auto-Dispatch Trigger (CRITICAL)

**Problem**: Nobody creates `dispatch_requests` when order reaches `readyForDriver`.

**Location**: `order_state_machine.dart:115-116`

**Fix**: Add dispatch creation in the `readyForDriver` case:

```dart
case OrderStatus.readyForDriver:
  updates['readyForDriverAt'] = DateTime.now().toIso8601String();
  // After transaction completes:
  await _createDispatchRequest(
    orderId: orderId,
    storeId: data['restaurantId'],
    pickupLat: data['restaurantLocation']?['latitude'],
    pickupLon: data['restaurantLocation']?['longitude'],
    dropoffLat: data['deliveryAddress']?['location']?['latitude'],
    dropoffLon: data['deliveryAddress']?['location']?['longitude'],
  );
```

### Fix 2: Driver Push Notifications (CRITICAL)

**Problem**: Drivers never get notified of new dispatches.

**Location**: `auto_dispatcher.dart:186-203` (inside `_scoreAndAssign`)

**Fix**: After setting `awaiting_acceptance`, call:

```dart
await PushNotificationService().sendDriverNotification(
  driverId: best.driverId,
  orderId: dispatchRequestId,
  action: 'new_dispatch',
);
```

### Fix 3: Online/Offline State (CRITICAL)

**Problem**: Dispatcher reads `isOnline` from `users/`, driver writes to `driver_locations/`.

**Location**: Driver app toggle + `auto_dispatcher.dart`

**Fix**: Write to BOTH collections when toggling online status:

```dart
// When driver goes online/offline:
await FirebaseFirestore.instance.collection('users').doc(driverId).update({
  'isOnline': isOnline,
});
await FirebaseFirestore.instance.collection('driver_locations').doc(driverId).update({
  'isOnline': isOnline,
});
```

### Fix 4: Background GPS Tracking (CRITICAL)

**Problem**: GPS stops when app is minimized.

**Location**: `driver_live_map_screen.dart`

**Fix**: Use `geolocator` background mode:

```dart
await Geolocator.getCurrentPosition(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 50, // Update every 50 meters
    timeLimit: Duration(seconds: 30),
  ),
);
```

Or use `flutter_background_geolocation` for persistent background tracking.

### Fix 5: Timeout Enforcement (HIGH)

**Problem**: `checkDispatchTimeouts` runs every 30 minutes. A driver can wait 30 min for reassignment.

**Location**: `dispatch.js:42-43`

**Fix**: Change schedule to every 30 seconds AND add real-time timeout via Cloud Function:

```javascript
// Option A: Change schedule
.onSchedule('*/30 * * * * *', ...) // Every 30 seconds

// Option B: Trigger timeout from AutoDispatcher
// When setting awaiting_acceptance, schedule a timeout callback
```

### Fix 6: Anything Wallet Credit (HIGH)

**Problem**: `DeliveryEarningsService.creditEarnings()` is only called from `OrderStateMachine.transition()`. Anything pipeline never calls it.

**Location**: `anything_provider.dart` completion handler

**Fix**: After Anything delivery completes:

```dart
await DeliveryEarningsService.instance.creditEarnings(
  driverId: driverId,
  orderId: anythingRequestId,
  totalAmount: totalAmount,
  deliveryFee: deliveryFee,
  commissionPercent: 15.0,
);
```

### Fix 7: Race Condition in Assignment (HIGH)

**Problem**: In `_scoreAndAssign()`, the `users` doc update is inside the Firestore transaction but the dispatch update and user update are separate writes. If the transaction fails, the user doc may already be updated.

**Location**: `auto_dispatcher.dart:198-201`

**Fix**: Move BOTH updates inside a single transaction, or use a two-phase approach:

```dart
return _firestore.runTransaction((txn) async {
  // Both reads first
  final dispatchSnap = txn.get(dispatchRef);
  final userSnap = txn.get(userRef);
  
  // Validate both
  if (!dispatchSnap.exists || userSnap.data()?['activeDeliveries'] >= 4) {
    return false;
  }
  
  // Both writes together
  txn.update(dispatchRef, { ... });
  txn.update(userRef, { ... });
  return true;
});
```

---

## The Order Journey: Complete Flow

### Happy Path (Everything Works)

```
1. Customer opens app
   → Browses restaurants (reads from Firestore)
   
2. Customer places order
   → OrderPlacementService validates
   → Creates order doc (status: placed)
   → Server-side pricing validation (Cloud Function)
   
3. Restaurant receives notification
   → Push notification via FCM
   → Restaurant sees order in dispatch center
   
4. Restaurant accepts
   → OrderStateMachine.transition(accepted)
   → Notification to customer: "Order accepted"
   
5. Restaurant prepares
   → OrderStateMachine.transition(preparing)
   → Notification to customer: "Preparing your order"
   
6. Restaurant marks ready
   → OrderStateMachine.transition(ready)
   → Notification to customer: "Ready for pickup"
   
7. Restaurant marks ready for driver
   → OrderStateMachine.transition(readyForDriver)
   → AUTO-DISPATCH TRIGGERS
   → DispatchRequest created in Firestore
   → Cloud Function onDispatchCreated fires
   → AutoDispatcher.findAndAssignDriver() runs
   → DriverScorer evaluates 5 factors
   → Best driver gets dispatch_request (status: awaiting_acceptance)
   → PUSH NOTIFICATION TO DRIVER: "New order available"
   
8. Driver accepts
   → DispatchProvider.acceptDispatch()
   → Cloud Function onDispatchAccepted fires
   → Order status → dispatched
   → Notification to customer: "Driver on the way"
   → GPS tracking starts
   
9. Driver picks up
   → DispatchProvider.markPickedUp()
   → Order status → pickedUp
   → Notification to customer: "Order picked up"
   
10. Driver delivers
    → DispatchProvider.completeDelivery()
    → Order status → delivered
    → DeliveryEarningsService.creditEarnings()
    → Driver wallet updated
    → Notification to customer: "Order delivered"
    → Notification to restaurant: "Order completed"
```

### Failure Path: No Drivers Available

```
7. AutoDispatcher runs
   → No online drivers found
   → Dispatch status → unassigned
   → Notification to restaurant: "No drivers available"
   → Restaurant can: wait, cancel, or assign manually
```

### Failure Path: Driver Rejects

```
8. Driver rejects dispatch
   → DispatchProvider.rejectDispatch()
   → AutoDispatcher.reassignDriver()
   → Skips rejected driver
   → Scores remaining drivers
   → If found: assigns to next best
   → If not found: marks unassigned
```

### Failure Path: Driver Times Out

```
8. Driver doesn't respond in 45 seconds
   → checkDispatchTimeouts (Cloud Function)
   → Dispatch status → timedOut
   → Decrement driver's activeDeliveries
   → Trigger reassignment
   → Loop until assigned or unassigned
```

---

## The Data Flow: Firestore Collections

### Write Patterns

| Collection | Written By | When |
|---|---|---|
| `orders` | Customer app, Partner app, Cloud Functions | Order lifecycle |
| `dispatch_requests` | Core Engine (AutoDispatcher) | Driver assignment |
| `users` | Auth, Driver app, Admin | Profile, online status, active deliveries |
| `driver_locations` | Driver app | GPS updates |
| `driver_wallets` | DeliveryEarningsService | On delivery completion |
| `notifications` | Core Engine | All status changes |
| `payments` | PaymentOrchestrator | On order placement |

### Read Patterns

| Collection | Read By | Purpose |
|---|---|---|
| `orders` | All apps | Display order data |
| `dispatch_requests` | Driver app, Customer app | Track assignment, delivery |
| `users` | Core Engine | Driver availability, ratings |
| `driver_locations` | Customer app | Live tracking |
| `restaurants` | All apps | Store info, menu, config |
| `driver_wallets` | Driver app | Balance display |

### Index Requirements

From `firestore.indexes.json`:

```
dispatch_requests:
  - status + assignedDriverId (for driver's dispatches)
  - status + acceptanceDeadline (for timeout check)
  - orderId (for order→dispatch lookup)

users:
  - isOnline + driverType (for platform driver query)
  - restaurantId + isOnline (for store driver query)

driver_locations:
  - storeId + isOnline (for store driver query)
  - geohash (for proximity queries)
```

---

## Testing the Engine

### Unit Tests

| Test | What It Validates |
|---|---|
| `OrderStateMachine.isValidTransition()` | All 11 states + transitions |
| `DriverScorer.scoreDrivers()` | Weighted scoring with mock drivers |
| `AutoDispatcher._isOverloaded()` | Overload detection threshold |
| `DeliveryEarningsService.creditEarnings()` | Wallet calculation accuracy |
| `CommissionCalculator` | Commission = total × percent / 100 |

### Integration Tests

| Test | What It Validates |
|---|---|
| Order placed → restaurant notified | End-to-end order creation |
| Restaurant accepts → customer notified | Status propagation |
| Ready for driver → dispatch created | **THE critical integration** |
| Driver accepts → order dispatched | Dispatch → order connection |
| Driver delivers → wallet credited | Money flow |
| Driver rejects → reassignment | Reassignment loop |
| Timeout → reassignment | Timeout enforcement |

### Edge Cases

| Case | Expected Behavior |
|---|---|
| All drivers offline | Dispatch → `unassigned` |
| All drivers overloaded | Dispatch → `overloaded` |
| Driver goes offline mid-dispatch | Reassignment triggered |
| Driver app killed mid-dispatch | Timeout after 45s |
| Network loss during transition | Offline queue syncs |
| Double accept (race condition) | Transaction prevents |
| Double deliver (dedup) | `creditEarnings` checks existing txn |

---

## Implementation Priority

### Phase 1: Make It Work (Sprint 0-1)

| Fix | Effort | Impact |
|---|---|---|
| Auto-dispatch trigger | 2 hours | Unblocks entire flow |
| Driver push notifications | 1 hour | Drivers get notified |
| Online/offline state | 1 hour | Dispatcher finds drivers |
| Timeout enforcement (30s) | 2 hours | Fast reassignment |

### Phase 2: Make It Reliable (Sprint 2-3)

| Fix | Effort | Impact |
|---|---|---|
| Background GPS | 4 hours | Real-time tracking |
| Anything wallet credit | 1 hour | Drivers paid correctly |
| Race condition fix | 2 hours | Data integrity |
| Restaurant notifications | 1 hour | Full notification loop |

### Phase 3: Make It Optimal (Sprint 4+)

| Feature | Effort | Impact |
|---|---|---|
| Batched deliveries | 2 weeks | Fleet efficiency |
| AI route optimization | 3 weeks | Faster delivery |
| Demand prediction | 2 weeks | Better driver allocation |
| Geofencing | 1 week | Auto status updates |

---

## Summary

The Core Logistics Engine already exists in code. It is 80% built.

What is missing:
1. The trigger that creates dispatch_requests (2 hours of work)
2. The notification to drivers when assigned (1 hour of work)
3. The online state consistency (1 hour of work)
4. The background GPS persistence (4 hours of work)

These 4 fixes turn the system from "pretty screens" into "working logistics platform".

Everything else — scoring, state machine, wallet, payments — already works.

The engine is the skeleton. These fixes are the tendons that make it move.
