# TayyebGo — Architecture Map

## Top-Level Layout

```
tayyebgo_monorepo/
├── apps/
│   ├── tayyebgo_customer/      # Customer ordering app
│   ├── tayyebgo_driver/        # Driver delivery app
│   └── tayyebgo_partner/       # Restaurant partner app
├── packages/
│   ├── tayyebgo_core/          # Shared core library
│   ├── tayyebgo_multi_tenant/  # Multi-tenant/vertical management
│   ├── tayyebgo_payment/       # Payment transaction handling
│   └── tayyebgo_payout/        # Vendor payout system
├── functions/                  # Firebase Cloud Functions (Node.js)
└── scripts/                    # Utility/deployment scripts
```

---

## Apps

### tayyebgo_customer
- **Purpose**: Food ordering, cart, checkout, order tracking, anything-requests
- **Dependencies**: `tayyebgo_core`, `tayyebgo_multi_tenant`
- **Entry**: `main.dart` → `CustomerApp` → `AppRouter.create()`
- **Screens**: 9 total (1 dead: `restaurant_list_screen.dart`)
- **Providers mounted**: AuthProvider, CartProvider, LocaleProvider, AnythingProvider, AddressProvider, LoyaltyProvider

### tayyebgo_driver
- **Purpose**: Delivery dashboard, available requests, active deliveries, earnings, wallet, safety
- **Dependencies**: `tayyebgo_core`
- **Entry**: `main.dart` → `DriverApp` → `AppRouter.create()`
- **Screens**: 6 total
- **Providers mounted**: AuthProvider, LocaleProvider, AnythingProvider, DriverWalletProvider

### tayyebgo_partner
- **Purpose**: Restaurant menu management, AI menu creation, kitchen display, cashier terminal, store customization
- **Dependencies**: `tayyebgo_core`
- **Entry**: `main.dart` → `PartnerApp` → `AppRouter.create()`
- **Screens**: 5 total (partner_gatekeeper + 4 feature screens)
- **Providers mounted**: AuthProvider, LocaleProvider, OfflineQueueProvider (local), PartnerRoleController (local)

---

## Packages

### tayyebgo_core (shared core)
- **Purpose**: All shared business logic, models, services, UI components
- **Size**: ~129 source files, 162-line barrel export
- **Internal structure**:

#### `domain/` — Business logic layer
```
domain/
├── entities/           15 files
│   ├── branch.dart
│   ├── brand.dart
│   ├── dispatch_request.dart
│   ├── dispatch_zone.dart    ← DEAD (zero references)
│   ├── driver.dart
│   ├── menu_item.dart
│   ├── menu_modifier.dart
│   ├── order.dart
│   ├── payment_method.dart
│   ├── payout.dart
│   ├── promotion.dart
│   ├── restaurant.dart
│   ├── skill.dart
│   ├── skill_execution.dart
│   └── user.dart
├── enums/              7 files
│   ├── driver_type.dart
│   ├── fulfillment_type.dart
│   ├── order_status.dart        # 9 states: placed → accepted → preparing → ready → readyForDriver → dispatched → pickedUp → delivered → cancelled
│   ├── payment_method_type.dart
│   ├── pending_operation_type.dart
│   ├── skill_execution_status.dart
│   └── user_role.dart
├── repositories/       9 files (interfaces prefixed i_)
│   ├── i_auth_repository.dart
│   ├── i_branch_repository.dart
│   ├── i_brand_repository.dart
│   ├── i_driver_repository.dart
│   ├── i_menu_repository.dart
│   ├── i_order_repository.dart
│   ├── i_payment_repository.dart
│   ├── i_promotion_repository.dart
│   └── i_restaurant_repository.dart
├── services/           4 files (interfaces prefixed i_)
│   ├── i_auto_dispatcher.dart
│   ├── i_menu_sync_service.dart
│   ├── i_payment_service.dart
│   └── i_skill_registry.dart
├── value_objects/      7 files
│   ├── address.dart
│   ├── geo_location.dart
│   ├── geohash.dart
│   ├── money.dart
│   ├── operating_hours.dart
│   ├── pending_operation.dart
│   └── skill_input_schema.dart
├── engine/             EMPTY
└── events/             EMPTY
```

#### `infrastructure/` — Implementation layer
```
infrastructure/
├── repositories/       10 files
│   ├── firebase_auth_repository.dart
│   ├── firebase_brand_repository.dart
│   ├── firebase_branch_repository.dart
│   ├── firebase_driver_repository.dart
│   ├── firebase_menu_repository.dart
│   ├── firebase_order_repository.dart
│   ├── firebase_payment_repository.dart
│   ├── firebase_promotion_repository.dart
│   ├── firebase_restaurant_repository.dart
│   └── offline_order_repository.dart    ← DEAD (barrel only)
├── services/           19 files
│   ├── auto_dispatcher.dart          # Scoring + dispatch engine
│   ├── commission_calculator.dart    # Percent-based commission math
│   ├── connectivity_service.dart     # Network state monitoring
│   ├── driver_location_service.dart  # GPS tracking (no background mode)
│   ├── driver_scorer.dart            # ETA(40%)/Rating(25%)/Load(20%)/Distance(15%)
│   ├── eta_service.dart              ← DEAD (barrel only)
│   ├── geolocation_service.dart      ← DEAD (barrel only)
│   ├── menu_sync_service.dart        ← DEAD (barrel only)
│   ├── notification_templates.dart   # Push notification message templates
│   ├── offline_queue.dart            # Offline operation queue
│   ├── order_placement_service.dart  # Creates orders + dispatch_requests
│   ├── order_state_machine.dart      # Order status transition validation
│   ├── payment_gateway.dart          # Payment routing
│   ├── push_notification_service.dart# FCM notification sender
│   ├── revenue_service.dart          ← DEAD (barrel only)
│   ├── sham_cash_service.dart        ← DEAD (barrel only)
│   ├── skill_execution_engine.dart   # Skills runtime
│   ├── stripe_checkout_service.dart  ← DEAD (barrel only)
│   └── sync_engine.dart              # Offline/online sync coordinator
```

#### `presentation/` — UI layer
```
presentation/
├── router/              2 files
│   ├── app_router.dart           # GoRouter setup with splash/onboarding/access-denied/notifications
│   └── route_guards.dart         # Auth redirect logic (appRedirect)
├── shared_widgets/      12 files
│   ├── animated_button.dart
│   ├── brand_logo.dart
│   ├── destructive_action_overlay.dart
│   ├── glass_card.dart
│   ├── otp_field.dart
│   ├── page_transitions.dart
│   ├── press_scale.dart
│   ├── skill_card.dart
│   ├── skill_execution_view.dart
│   ├── slide_transition.dart
│   └── ui_feedback.dart
└── theme/               5 files
    ├── app_colors.dart
    ├── app_gradients.dart
    ├── app_spacing.dart
    ├── app_typography.dart
    └── theme_provider.dart
```

#### `src/` — Legacy/transitional layer (58 files, 8 concerns mixed)
```
src/
├── constants/           2 files
│   ├── app_constants.dart
│   └── route_names.dart
├── firebase/            4 files
│   ├── firebase_options.dart         # Env-selection logic
│   ├── firebase_options_dev.dart
│   ├── firebase_options_prod.dart
│   └── firebase_options_staging.dart
├── models/              13 files     ← Duplicates 7 domain entities
│   ├── anything_request_model.dart
│   ├── cart_line_item.dart
│   ├── driver_model.dart
│   ├── driver_wallet_model.dart
│   ├── loyalty_transaction.dart
│   ├── modifier.dart
│   ├── order_model.dart
│   ├── product.dart
│   ├── promo_model.dart
│   ├── saved_address.dart
│   ├── smart_address.dart
│   ├── user_model.dart
│   └── vendor.dart
├── providers/           8 files
│   ├── address_provider.dart
│   ├── anything_provider.dart
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── driver_wallet_provider.dart
│   ├── locale_provider.dart
│   ├── loyalty_provider.dart
│   └── skill_registry_provider.dart
├── repositories/        3 files
│   ├── auth_repository.dart         ← Dead (shadowed by firebase_auth)
│   ├── order_repository.dart         ← Dead (shadowed by firebase_order)
│   └── user_repository.dart          ← Dead (no consumers)
├── screens/             12 files + 1 empty `widgets/`
│   ├── access_denied_screen.dart
│   ├── app_scaffold.dart
│   ├── auth_state_redirector.dart
│   ├── cashier_terminal_screen.dart   ← Shadowed by partner app copy
│   ├── login_screen.dart
│   ├── notifications_screen.dart
│   ├── onboarding_screen.dart
│   ├── payment_selection_sheet.dart
│   ├── profile_screen.dart
│   ├── register_screen.dart
│   ├── settings_screen.dart
│   └── splash_screen.dart
├── services/            2 files
│   ├── auth_gate.dart
│   └── auth_listenable.dart
├── theme/               1 file
│   └── tayyebgo_theme.dart
├── utils/               1 file
│   └── result.dart
└── widgets/             10 files
    ├── async_screen_builder.dart
    ├── auto_dispatch_listener.dart
    ├── driver_live_map.dart
    ├── empty_state.dart
    ├── error_boundary.dart
    ├── error_retry_widget.dart
    ├── order_rating.dart
    ├── order_status_badge.dart
    ├── shimmer_loading.dart
    └── triple_state_widget.dart
```

#### `application/` — EMPTY (scaffolded only)
```
application/
├── commands/            EMPTY
├── contracts/           EMPTY
├── dtos/                EMPTY
├── notifiers/           EMPTY (generated .riverpod.g.part files in .dart_tool)
└── use_cases/           EMPTY
```

---

### tayyebgo_multi_tenant
- **Purpose**: Multi-vertical tenant configuration
- **Size**: 7 source files
- **Exports**: `VerticalType`, `Tenant`, `ServiceArea`, `CommissionRate`, `AdminStatsProvider`
- **Dependencies**: `tayyebgo_core`, `cloud_firestore`, `provider`

### tayyebgo_payment
- **Purpose**: Payment transaction handling (stub)
- **Size**: 4 source files
- **Exports**: `Payment`, `PaymentProvider`
- **Dependencies**: `tayyebgo_core`, `cloud_firestore`

### tayyebgo_payout
- **Purpose**: Vendor payout management (stub)
- **Size**: 4 source files
- **Exports**: `Payout`, `PayoutProvider`
- **Dependencies**: `tayyebgo_core`, `cloud_firestore`

---

## Cloud Functions

- **Location**: `functions/`
- **Runtime**: Node.js (1 file: `index.js`)
- **Dependencies**: `package.json` (Firebase Admin SDK)
- **Purpose**: Minimal — only 1 Cloud Function defined

---

## Firestore Collections

### Core Business Collections
| Collection | Created By | Read By | Notes |
|---|---|---|---|
| `users` | Auth flow | All apps | User profiles, roles, online status |
| `orders` | `OrderPlacementService` | Customer, Partner apps | Food orders |
| `order_items` | (inferred) | (inferred) | Line items per order |
| `dispatch_requests` | `OrderPlacementService` | `AutoDispatcher` | Links orders to dispatch |
| `driverAssignments` | `AutoDispatcher` | Driver app | Driver-to-order assignments |
| `restaurants` | Seed/admin | Customer, Partner apps | Restaurant profiles |
| `brands` | `FirebaseBrandRepository` | Various | Brand entities |
| `branches` | `FirebaseBranchRepository` | Various | Branch/location entities |
| `products` | Partner app | Customer app | Menu items |
| `categories` | Partner app | Customer app | Menu categories |
| `promotions` | Admin | Customer app | Discounts/offers |
| `driver_locations` | Driver app | Dispatcher | Real-time GPS positions |
| `driver_wallets` | Driver app | Driver app | Driver earnings/wallet |
| `driver_wallets/{id}/transactions` | Driver app | Driver app | Wallet transaction history |

### Anything-Request Collections
| Collection | Created By | Read By | Notes |
|---|---|---|---|
| `anything_requests` | Customer app | Customer, Driver apps | Personal shopping requests |
| `anything_chats` | (inferred) | Customer, Driver apps | Chat per request |

### System Collections
| Collection | Purpose |
|---|---|
| `dispatch_zones` | Geo-fencing for dispatch |
| `notifications` | Push notification history |
| `subscriptions` | FCM topic subscriptions |
| `saved_addresses` (subcollection) | Per-user saved delivery addresses |
| `documents` | Uploaded documents (IDs, permits) |
| `loyalty_transactions` | Customer loyalty point history |

---

## Dependency Graph

```
tayyebgo_customer  ─── tayyebgo_core
                  └── tayyebgo_multi_tenant ─── tayyebgo_core

tayyebgo_driver    ─── tayyebgo_core

tayyebgo_partner   ─── tayyebgo_core

tayyebgo_multi_tenant ─── tayyebgo_core
tayyebgo_payment      ─── tayyebgo_core
tayyebgo_payout       ─── tayyebgo_core
```

All packages ultimately depend on `tayyebgo_core`. There is no root workspace pubspec.

---

## Key Data Flows

### Food Order Flow
```
Customer App          Partner App          Firestore              Dispatcher
    │                     │                   │                      │
    ├── placeOrder() ────→│                   │                      │
    │                     │  orders.create()  │                      │
    │                     │  dispatch_requests.create()              │
    │                     │                   │                      │
    │                     │                   ├── dispatch_listener()│
    │                     │                   │    └── findAndAssignDriver()
    │                     │                   │         ├── scoreDrivers()
    │                     │                   │         └── assign()
    │                     │                   │                      │
    │                     │ ←── order updated ── status changes     │
    │                     │                   │                      │
```

### Anything Request Flow
```
Customer App                   Firestore                 Driver App
    │                              │                        │
    ├── anything_requests.create() │                        │
    │                              ├── .snapshots() ───────→│
    │                              │     (pending requests) │
    │                              │                        ├── accept()
    │                              │ ←── driverId assigned  │
    │ ←── status changes ──────────│                        │
    │                              │                        ├── markShopping()
    │                              │                        ├── markEnRoute()
    │                              │                        └── markDelivered()
```

### Sync / Offline Flow
```
Partner App (offline)        OfflineQueue        SyncEngine       Firestore
    │                              │                  │               │
    ├── queueOperation() ─────────→│                  │               │
    │                              │ stored local     │               │
    │                              │                  │               │
    │ ←── online ─────────────────→│ sync() ────────→│               │
    │                              │                  ├── replayAll()─→│
    │                              │                  │               │
```

---

## Service Dependencies

```
AutoDispatcher
  ├── DriverScorer → EtaService (DEAD), Driver (entity)
  └── FirebaseDriverRepository → users collection

OrderStateMachine
  ├── NotificationTemplates
  └── PushNotificationService

SyncEngine
  ├── ConnectivityService
  └── OfflineQueue

SkillExecutionEngine
  └── SkillRegistryProvider
```

---

## Legend

| Symbol | Meaning |
|---|---|
| `DEAD` | File is only referenced from barrel; no actual consumers |
| `EMPTY` | Directory exists but contains zero Dart files |
| `Shadowed` | Core export is overridden by app-level local copy |
| `← DEAD` | Service/provider defined but never called |
