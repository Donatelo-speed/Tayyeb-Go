# TayyebGo Architecture

## Monorepo Structure

```
tayyebgo_monorepo/
├── apps/
│   ├── tayyebgo_customer/    # Customer-facing app
│   ├── tayyebgo_driver/      # Driver/delivery app
│   ├── tayyebgo_partner/     # Restaurant partner app
│   └── tayyebgo_admin/       # Admin dashboard
├── packages/
│   ├── tayyebgo_core/        # Shared business logic, models, services
│   └── tayyebgo_multi_tenant/# Multi-tenancy support
├── functions/                 # Firebase Cloud Functions (Node.js)
├── cloud_functions/           # Additional cloud functions (TypeScript)
├── firestore.rules            # Firestore security rules
├── firebase.json              # Firebase configuration
└── .github/workflows/ci.yml  # CI/CD pipeline
```

## Clean Architecture Layers

The core business logic lives in `packages/tayyebgo_core/lib/`:

```
lib/
├── domain/                    # Enterprise business rules
│   ├── entities/              # Core domain objects (Order, Driver, Restaurant, etc.)
│   ├── enums/                 # Domain enumerations (OrderStatus, UserRole, etc.)
│   ├── value_objects/         # Immutable value types (Money, GeoLocation, Address)
│   ├── services/              # Repository & service interfaces (contracts)
│   └── repositories/          # Repository interfaces
├── infrastructure/            # Frameworks & drivers
│   ├── services/              # Firebase implementations, business logic services
│   ├── repositories/          # Concrete repository implementations
│   └── firebase/              # Firebase-specific adapters
├── src/                       # Application-level code
│   ├── models/                # Data transfer objects, API models
│   ├── providers/             # ChangeNotifier providers for state
│   ├── di/                    # Dependency injection / service locator
│   └── widgets/               # Reusable shared widgets
├── presentation/              # UI layer
│   ├── theme/                 # AppColors, AppTypography, AppSpacing, etc.
│   └── router/                # GoRouter configuration
└── ui/                        # Design system components (buttons, cards, loaders)
```

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Data access | Repository pattern | Decouples Firebase from business logic |
| State management | Provider (ChangeNotifier) | Simple, proven for Flutter; no extra deps |
| Navigation | GoRouter | Declarative routing, deep-link ready |
| Backend | Firebase (Auth, Firestore, Storage, Functions) | Fast iteration, serverless scaling |
| Payments | Stripe + local ShamCash fallback | Stripe for card/mobile; ShamCash for markets without Stripe |
| Architecture | Clean Architecture | Testability, separation of concerns |
| Code sharing | Monorepo + core package | Single source of truth for business logic |

## Business Logic

### Order State Machine

Orders transition through a finite state machine defined in `OrderStatus`:

```
placed → accepted → preparing → ready → readyForDriver → dispatched → pickedUp → delivered
                                                           ↑
                                                         placed (driver accepts directly)
```

- `placed` — Customer submits order
- `accepted` — Restaurant confirms
- `preparing` — Food is being prepared
- `ready` — Food ready for pickup
- `readyForDriver` — Awaiting driver assignment
- `dispatched` — Driver en route to restaurant
- `pickedUp` — Driver has the order
- `delivered` — Completed
- `cancelled` — Can occur from `placed`, `pending`, or `accepted`
- `refunded` — Post-delivery refund

Terminal states: `delivered`, `cancelled`, `refunded`.

### Auto-Dispatch Algorithm

When an order reaches `readyForDriver`, the `AutoDispatcher` scores available drivers using a 4-factor weighted model:

| Factor | Weight | Formula |
|---|---|---|
| ETA to pickup | 40% | Inverse of estimated time (2–60 min range) |
| Driver rating | 25% | Rating / 5.0 |
| Current load | 20% | 1.0 − (activeDeliveries × 0.25), min 0 |
| Distance to pickup | 15% | Inverse of total distance |

Scores are normalized to [0, 1] and ranked. Highest score wins.

### Payment Abstraction

`PaymentOrchestrator` routes payment to the appropriate provider:

- **CashPaymentProvider** — COD, no external API
- **ShamCashPaymentProvider** — Local wallet (ShamCash), peer-to-peer transfers
- **StripePaymentProvider** — Card/intent-based payments via Stripe API

All providers implement `IPaymentProvider`, making it easy to add new methods.

### Commission Model

- Default commission: **15%** of order total
- `CommissionCalculator` computes platform fee: `grossAmount × commissionPercent / 100`
- Net to restaurant: `grossAmount − commission`

### Subscription Plans

| Plan | Duration | Price | Discount | Key Benefits |
|---|---|---|---|---|
| Basic | 1 month | 10,000 (local) | 5% | Free delivery, priority offers |
| Plus | 3 months | 25,000 | 10% | + Monthly offers, priority support |
| Premium | 6 months | 45,000 | 15% | + Exclusive deals, early access |

### Promo Code System

Promo codes are validated via `PromoAbuseService` and Cloud Functions:
- One-time use per user
- Expiry dates enforced
- Minimum order amounts
- Percentage or fixed-amount discounts
- Abuse detection via device fingerprinting

## Firebase Security Rules

Firestore rules enforce role-based access:
- `isAuthenticated()` — Checks `request.auth != null`
- `hasRole(role)` — Verifies user role from token or Firestore user doc
- `isOwner(uid)` — Confirms document ownership
- Collection-level rules for `users`, `orders`, `restaurants`, `drivers`, `dispatches`

## Cloud Functions

Node.js Cloud Functions handle:
- **Notifications** — FCM token registration, push notifications, cleanup
- **Dispatch** — Dispatch creation, acceptance, timeout checks
- **Stripe** — Payment intents, wallet top-ups, driver payouts
- **Admin** — Role management
- **AI** — Menu image processing
- **Safety** — SOS emergency, order pricing validation
- **Promos** — Promo code validation
- **Payouts** — Batch driver payout processing
