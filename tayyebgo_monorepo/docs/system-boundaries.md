# System Boundaries — Tayybe Go

## Architecture Principle

**Apps contain NO business logic.** All business rules, decisions, and state mutations live in the Core Engine (`tayybe`go_core` package). Apps are thin presentation shells that delegate to core services, providers, and repositories.

```
┌─────────────────────────────────────────────────────┐
│                   Frontend Apps                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │Customer  │ │ Driver   │ │ Partner  │ │  Admin   │ │
│  │   App    │ │   App    │ │   App    │ │   App    │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ │
│       │            │            │            │        │
├───────┴────────────┴────────────┴────────────┴───────┤
│              Shared Package (tayybe  go_core)           │
│  ┌─────────────────────────────────────────────────┐  │
│  │         Core Engine (Business Logic)             │  │
│  │  ┌───────────┐ ┌──────────┐ ┌────────────────┐  │  │
│  │  │Order State│ │ Dispatch │ │Pricing/Payment  │  │  │
│  │  │  Machine  │ │  System  │ │    Services     │  │  │
│  │  └───────────┘ └──────────┘ └────────────────┘  │  │
│  │  ┌───────────┐ ┌──────────┐ ┌────────────────┐  │  │
│  │  │    ETA    │ │ Location │ │   Notification  │  │  │
│  │  │  Service  │ │ Tracking │ │     Services    │  │  │
│  │  └───────────┘ └──────────┘ └────────────────┘  │  │
│  └─────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────┐  │
│  │         Shared Layer (Reusable Artifacts)        │  │
│  │  Domain Entities │ Enums │ Value Objects │ Models│  │
│  │  Abstract Repos  │ DTOs  │ Validators  │ Utils │  │
│  │  Shared Widgets │ Theme │ Router │ Guards       │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────┐
│              Firebase Backend                         │
│  Firestore │ Cloud Functions │ Auth │ FCM │ Storage  │
└─────────────────────────────────────────────────────┘
```

---

## 1. Frontend (Flutter Apps)

### What belongs to Frontend

| Concern | Description |
|---|---|
| **Presentation** | Screens, widgets, layouts, animations |
| **User Interaction** | Buttons, forms, gestures, navigation |
| **Local State** | UI state (selected tab, form input, scroll position) |
| **Client-side Routing** | Screen navigation with route guards |
| **App-specific Theming** | Per-app color/typography overrides (if any) |
| **Platform Integration** | Camera, image picker, geolocation (triggers, not logic) |

### What MUST NOT be in Frontend

| Prohibited Concern | Reason |
|---|---|
| Dispatch logic | Core Engine owns driver assignment |
| Assignment rules | Core Engine decides who gets what order |
| Pricing calculations | Core Engine computes fees, taxes, discounts |
| Payment decisions | Core Engine processes payments |
| Order state transitions | OrderStateMachine in Core Engine |
| Driver ranking/scoring | DriverScorer in Core Engine |
| Business rule validation | All rules live in Core Engine |

### Frontend Responsibilities by App

#### Customer App
- Display restaurant listings and menus
- Shopping cart management (UI only — pricing from core)
- Order placement (calls `OrderPlacementService`)
- Order tracking (listens to `watchDispatchRequest`)
- Payment selection and processing (calls `PaymentGateway`)
- Profile and address management

#### Driver App
- Display available dispatch requests
- Accept/reject buttons (calls core)
- Delivery status update controls
- Live map with GPS publishing
- Earnings and wallet view

#### Partner App (Store Owner + Cashier)
- Menu and product management
- Order acceptance and status updates
- Kitchen display mode
- Cashier terminal
- Store analytics (from `RevenueService`)

#### Admin App
- User, store, driver management
- Order override controls
- Platform analytics and monitoring
- Settings and configuration

---

## 2. Core Engine (`tayybe`go_core` infrastructure/services/`)

### Ownership

| Service | Ownership | Description |
|---|---|---|
| `OrderStateMachine` | Core Engine | Validates and executes all order transitions. Only source of truth for order status. |
| `AutoDispatcher` | Core Engine | Finds, scores, and assigns drivers to dispatch requests. |
| `DriverScorer` | Core Engine | Ranks drivers by proximity, rating, load, and other factors. |
| `PaymentGateway` | Core Engine | Abstracts payment processing (Stripe, Sham Cash). |
| `CommissionCalculator` | Core Engine | Computes platform commission from order totals. |
| `OrderPlacementService` | Core Engine | Validates and places orders. |
| `DriverLocationService` | Core Engine | Processes GPS updates for driver tracking. |
| `ETAService` | Core Engine | Estimates delivery times based on distance and historical data. |
| `PushNotificationService` | Core Engine | Sends FCM notifications on state changes. |
| `SyncEngine` | Core Engine | Manages offline-to-online data synchronization. |
| `OfflineQueue` | Core Engine | Queues operations when device is offline. |
| `RevenueService` | Core Engine | Aggregates revenue data for analytics. |
| `SkillExecutionEngine` | Core Engine | Executes AI skills (destructive/non-destructive). |

### Core Engine Rules

1. Only the Core Engine reads from and writes to authoritative Firestore collections
2. Apps never directly mutate business-critical collections (`Orders`, `dispatch_requests`, `payouts`)
3. All business decisions produce domain events (via the event system)
4. The Core Engine validates every state transition against the state machine
5. Pricing is always computed server-side in the Core Engine, never in the app

---

## 3. Shared Layer (`tayybe`go_core` domain/` + shared artifacts`)

### What belongs to the Shared Layer

| Category | Contents | Purpose |
|---|---|---|
| **Domain Entities** | User, Order, Driver, Restaurant, MenuItem, etc. | Data models shared across all apps |
| **Enums** | UserRole, OrderStatus, FulfillmentType, etc. | Canonical values |
| **Value Objects** | Money, Address, GeoLocation, Geohash, etc. | Reusable typed primitives |
| **Abstract Repositories** | I*Repository interfaces | Contracts for data access |
| **Abstract Services** | IAutoDispatcher, IMenuSyncService, etc. | Contracts for business services |
| **DTOs/Models** | Vendor, Product, OrderModelEx, etc. | Firestore JSON serialization |
| **Utilities** | Result\<T\>, validators, helpers | Shared code utilities |
| **Theme** | Colors, typography, spacing, gradients | Brand identity |
| **Shared Widgets** | AnimatedButton, GlassCard, OTPField, etc. | Reusable UI components |
| **Router** | AppRouter, RouteGuards | Navigation infrastructure |
| **Auth** | AuthProvider, AuthGate, AuthListenable | Authentication state |

### What MUST NOT be in Shared Layer

- App-specific screens or widgets
- Business logic (see Core Engine)
- UI that depends on app-specific state

---

## 4. Firebase Backend

### Managed by Cloud Functions

| Function | Trigger | Purpose |
|---|---|---|
| `setUserRole` | HTTPS callable | Sets Auth custom claims + Firestore role |
| `onNotificationCreated` | Firestore trigger | Sends FCM push |
| `cleanupNotifications` | Scheduled | Deletes old notifications |
| `processAiMenuImage` | HTTPS callable | OpenAI proxy for menu image parsing |
| `processPayouts` | Scheduled (skeleton) | Generates payout documents |

### Managed by Firestore Security Rules

- Role-based read/write access per collection
- Data validation on write (e.g., status transitions)
- Tenant isolation for multi-vertical data

### Database Ownership

| Collection | Owner | Notes |
|---|---|---|
| Users | Auth system + Admin | Created on signup, managed by admin |
| Restaurants | Store Owner + Admin | |
| Orders | Core Engine (write), Apps (read) | State machine controls writes |
| dispatch_requests | Core Engine (write), Driver App (read) | |
| menu_items | Store Owner + Admin | |
| payouts | Core Engine + Cloud Functions | |
| notifications | Core Engine | Read by all apps |
| activity_log | Core Engine + Admin | Append-only audit trail |
