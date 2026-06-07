# Architecture Ownership Diagram — Tayybe Go

## Module Ownership Map

```
tayyebgo_monorepo/
│
├── apps/                                              OWNER
│   ├── tayyebgo_customer/        (Customer App)       App Team
│   ├── tayyebgo_driver/          (Driver App)          App Team
│   ├── tayyebgo_partner/         (Partner App)         App Team
│   └── tayyebgo_admin/           (Admin App)           App Team
│
├── packages/
│   ├── tayyebgo_core/                                  Core Team
│   │   ├── domain/               (Entities, Enums,     Core Team
│   │   │                         Value Objects,
│   │   │                         Abstract Repos/Services)
│   │   ├── infrastructure/       (Firestore Repos,     Core Team
│   │   │                         Services, State Machine,
│   │   │                         Dispatch, Payments)
│   │   ├── presentation/         (Theme, Widgets,      Core Team
│   │   │                         Router)
│   │   └── src/                  (Providers, Models,   Core Team
│   │                             Screens, Utils)
│   │
│   ├── tayyebgo_multi_tenant/    (Tenant Management)   Core Team
│   ├── tayyebgo_payment/         (Payment Stub)        Core Team
│   └── tayyebgo_payout/          (Payout Stub)         Core Team
│
├── cloud_functions/              (TypeScript Functions) Backend Team
├── functions/                    (JS Cloud Functions)  Backend Team
├── scripts/                      (Deployment/Seed)     DevOps/Backend
├── docs/                         (Architecture Docs)   Core Team
│
├── firebase.json                 (Firebase Config)     DevOps
├── firestore.rules               (Security Rules)      Backend/Core
├── firestore.indexes.json        (DB Indexes)          Backend/Core
└── storage.rules                 (Storage Rules)       Backend/Core
```

---

## Ownership Responsibilities

### Core Team
Responsible for `tayybe`go_core` and all shared packages:

| Module | Responsibility |
|---|---|
| `domain/entities/` | All domain entity definitions, serialization, and business invariants |
| `domain/enums/` | Canonical enum values used across the platform |
| `domain/value_objects/` | Typed primitives with validation and operations |
| `domain/repositories/` | Abstract data access interfaces |
| `domain/services/` | Abstract service interfaces for business operations |
| `infrastructure/repositories/` | Concrete Firestore implementations of repository interfaces |
| `infrastructure/services/` | All business logic services (state machine, dispatch, payments, etc.) |
| `presentation/theme/` | Brand design system (colors, typography, spacing) |
| `presentation/shared_widgets/` | Reusable UI components |
| `presentation/router/` | Navigation infrastructure |
| `src/providers/` | Shared state management (auth, cart, locale, etc.) |
| `src/models/` | Firestore DTOs and view models |
| `src/utils/` | Shared utilities (Result type, etc.) |
| `src/repositories/` | Legacy repository implementations |
| `package exports` | Barrel file governance |

### App Team
Responsible for each application:

| Module | Responsibility |
|---|---|
| `lib/main.dart` | App entry point, dependency injection |
| `lib/screens/` | App-specific screens and pages |
| `lib/widgets/` | App-specific widgets |
| `lib/providers/` | App-specific state providers |
| `web/` | Web-specific configuration (index.html, manifest) |

### Backend Team
Responsible for cloud infrastructure:

| Module | Responsibility |
|---|---|
| `cloud_functions/functions/src/` | TypeScript cloud functions |
| `functions/index.js` | JavaScript cloud functions |
| `firestore.rules` | Security rules for all collections |
| `firestore.indexes.json` | Composite index definitions |
| `storage.rules` | Firebase Storage access rules |

### DevOps
Responsible for deployment and tooling:

| Module | Responsibility |
|---|---|
| `scripts/deploy.ps1` | Deployment pipeline |
| `scripts/seed_firestore.js` | Test data seeding |
| `scripts/create_indexes.sh` | Index creation |
| `firebase.json` | Firebase project configuration |
| `.firebaserc` | Firebase project aliases |
| `.github/workflows/` | CI/CD pipeline |

---

## Module Dependency Rules

```
apps/* ──────────► tayyebgo_core ◄─── tayyebgo_multi_tenant
                      │                      │
                      │                      │
                      ▼                      ▼
              tayyebgo_payment ───► tayyebgo_payout
```

**Rule 1:** Apps may only depend on `tayyebgo_core` (and optionally `tayyebgo_multi_tenant`).  
**Rule 2:** `tayyebgo_core` must NOT depend on any app.  
**Rule 3:** `tayyebgo_multi_tenant` may depend on `tayyebgo_core`.  
**Rule 4:** `tayyebgo_payment` and `tayyebgo_payout` may depend on `tayyebgo_core`.  
**Rule 5:** No circular dependencies between packages.  

---

## Data Flow: Order Lifecycle

```
1. Customer places order
   Customer App ──call──► OrderPlacementService (core)
                                     │
                                     ▼
                          Firestore: Orders (placed)
                                     │
                                     ▼
2. Store accepts order
   Partner App ──call──► OrderStateMachine (core)
                                     │
                                     ▼
                          Firestore: Orders (accepted)
                                     │
                                     ▼
3. Store prepares & marks ready
   Partner App ──call──► OrderStateMachine (core)
                                     │
                                     ▼
                          Firestore: Orders (ready)
                                     │
                                     ▼
4. System dispatches to driver
   AutoDispatcher (core) ──► DriverScorer (core)
                                     │
                                     ▼
                          Firestore: dispatch_requests (assigned)
                                     │
                                     ▼
5. Driver picks up
   Driver App ──call──► OrderStateMachine (core)
                                     │
                                     ▼
                          Firestore: Orders (pickedUp)
                                     │
                                     ▼
6. Driver delivers
   Driver App ──call──► OrderStateMachine (core)
                                     │
                                     ▼
                          Firestore: Orders (delivered)
                                     │
                                     ▼
7. Payment settlement + notification
   PaymentGateway (core) + PushNotificationService (core)
```

---

## Service Responsibilities

| Service | Reads | Writes | Triggered By |
|---|---|---|---|
| OrderStateMachine | Orders | Orders | App calls `transition()` |
| AutoDispatcher | dispatch_requests, Drivers, Restaurants | dispatch_requests, Users | `findAndAssignDriver()` |
| DriverScorer | Drivers, dispatch_requests | (none — returns scores) | AutoDispatcher |
| PaymentGateway | Orders, PaymentMethods | transactions, Orders | App calls `processPayment()` |
| OrderPlacementService | Restaurants, menu_items | Orders | App calls `placeOrder()` |
| DriverLocationService | driver_locations | driver_locations | Driver app GPS pings |
| ETAService | dispatch_zones, driver_locations | (none — returns ETA) | AutoDispatcher, Customer App |
| PushNotificationService | Users | notifications | OrderStateMachine, others |
| RevenueService | Orders | (none — aggregates) | Admin App queries |
| CommissionCalculator | Orders, Restaurants | (none — returns amount) | PaymentGateway, Payout |
| OfflineQueue | SharedPreferences | SharedPreferences, Firestore | App queued operations |
| SyncEngine | OfflineQueue | Orders, dispatch_requests | Connectivity change |

---

## Domain Events (Future — `domain/events/`)

The `domain/events/` directory is currently empty. It is reserved for a future event-driven layer:

| Event | Payload | Consumers |
|---|---|---|
| OrderPlaced | orderId, customerId, restaurantId, totalAmount | Notification, Analytics, Dispatch |
| OrderAccepted | orderId, storeId, actorId | Notification, Analytics |
| OrderReady | orderId, storeId | Dispatch, Notification |
| DriverAssigned | dispatchRequestId, driverId, eta | Notification, Customer App |
| DriverArrived | orderId, driverId, location | Notification |
| OrderDelivered | orderId, driverId, deliveredAt | Payment, Payout, Loyalty, Analytics |
| OrderCancelled | orderId, reason, actorId | Payment (refund), Analytics |
| PaymentProcessed | orderId, amount, method, status | Order, Payout, Analytics |
| DriverLocationUpdated | driverId, lat, lng, timestamp | Customer App, Dispatch |

---

## Layer Isolation Rules

```
┌──────────────────────────────────────────┐
│            Presentation Layer             │
│  Screens / Widgets / Providers           │
│  (depends on: domain, services, repos)   │
├──────────────────────────────────────────┤
│            Application Layer              │
│  Providers / ViewModels / Use Cases      │
│  (depends on: domain)                     │
├──────────────────────────────────────────┤
│            Domain Layer                   │
│  Entities / Value Objects / Enums        │
│  Abstract Repositories / Services        │
│  (NO dependencies)                        │
├──────────────────────────────────────────┤
│         Infrastructure Layer              │
│  Firestore Repos / Services / Engine     │
│  (depends on: domain)                     │
└──────────────────────────────────────────┘
```

**Rule:** Domain layer has zero external dependencies. Infrastructure and Presentation layers depend on Domain, never on each other.
