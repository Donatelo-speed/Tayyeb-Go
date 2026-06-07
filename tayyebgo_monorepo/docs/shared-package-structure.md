# Shared Package Structure Proposal — Tayybe Go

## Current State

All shared code lives in a single `tayybe`go_core` package. The barrel file (`tayybe`go_core.dart`) exports 162 symbols across domain, infrastructure, presentation, and src layers. Some concerns (e.g., `tayybe`go_payment`, `tayybe`go_payout`) exist as separate packages but are minimal stubs.

## Proposed Organization

### Option A: Single Package with Namespaced Modules (Recommended)

Keep `tayybe`go_core` as a single package but enforce stricter module boundaries within it. This avoids the overhead of managing multiple packages while maintaining separation of concerns.

```
packages/tayybe  go_core/lib/
│
├── tayybe  go_core.dart              # Barrel export (well-organized by section)
│
├── domain/                           # NO external dependencies
│   ├── entities/                     # Core domain objects
│   │   ├── user.dart
│   │   ├── order.dart
│   │   ├── driver.dart
│   │   ├── restaurant.dart
│   │   ├── brand.dart
│   │   ├── branch.dart
│   │   ├── menu_item.dart
│   │   ├── menu_modifier.dart
│   │   ├── dispatch_request.dart
│   │   ├── dispatch_zone.dart
│   │   ├── payment_method.dart
│   │   ├── promotion.dart
│   │   ├── payout.dart
│   │   ├── skill.dart
│   │   └── skill_execution.dart
│   ├── enums/
│   │   ├── user_role.dart
│   │   ├── order_status.dart
│   │   ├── fulfillment_type.dart
│   │   ├── driver_type.dart
│   │   ├── payment_method_type.dart
│   │   ├── pending_operation_type.dart
│   │   └── skill_execution_status.dart
│   ├── value_objects/
│   │   ├── address.dart
│   │   ├── geo_location.dart
│   │   ├── geohash.dart
│   │   ├── money.dart
│   │   ├── operating_hours.dart
│   │   ├── pending_operation.dart
│   │   └── skill_input_schema.dart
│   ├── repositories/                 # Abstract interfaces
│   │   ├── i_auth_repository.dart
│   │   ├── i_brand_repository.dart
│   │   ├── i_branch_repository.dart
│   │   ├── i_driver_repository.dart
│   │   ├── i_menu_repository.dart
│   │   ├── i_order_repository.dart
│   │   ├── i_payment_repository.dart
│   │   ├── i_promotion_repository.dart
│   │   └── i_restaurant_repository.dart
│   ├── services/                     # Abstract service interfaces
│   │   ├── i_auto_dispatcher.dart
│   │   ├── i_menu_sync_service.dart
│   │   ├── i_payment_service.dart
│   │   └── i_skill_registry.dart
│   └── events/                       # (EMPTY — reserved for domain events)
│
├── infrastructure/                   # Concrete implementations
│   ├── repositories/                 # Firestore implementations
│   │   ├── firebase_auth_repository.dart
│   │   ├── firebase_brand_repository.dart
│   │   ├── firebase_branch_repository.dart
│   │   ├── firebase_driver_repository.dart
│   │   ├── firebase_menu_repository.dart
│   │   ├── firebase_order_repository.dart
│   │   ├── firebase_payment_repository.dart
│   │   ├── firebase_promotion_repository.dart
│   │   ├── firebase_restaurant_repository.dart
│   │   └── offline_order_repository.dart
│   ├── services/                     # Business logic services
│   │   ├── order_state_machine.dart
│   │   ├── auto_dispatcher.dart
│   │   ├── driver_scorer.dart
│   │   ├── driver_location_service.dart
│   │   ├── eta_service.dart
│   │   ├── payment_gateway.dart
│   │   ├── stripe_checkout_service.dart
│   │   ├── sham_cash_service.dart
│   │   ├── commission_calculator.dart
│   │   ├── revenue_service.dart
│   │   ├── order_placement_service.dart
│   │   ├── push_notification_service.dart
│   │   ├── notification_templates.dart
│   │   ├── menu_sync_service.dart
│   │   ├── geolocation_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── offline_queue.dart
│   │   ├── sync_engine.dart
│   │   └── skill_execution_engine.dart
│   └── analytics/                    # (FUTURE — analytics service)
│
├── presentation/                     # UI layer shared across apps
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_gradients.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── theme_provider.dart
│   ├── shared_widgets/
│   │   ├── animated_button.dart
│   │   ├── glass_card.dart
│   │   ├── otp_field.dart
│   │   ├── press_scale.dart
│   │   ├── ui_feedback.dart
│   │   ├── slide_transition.dart
│   │   ├── brand_logo.dart
│   │   ├── page_transitions.dart
│   │   ├── skill_card.dart
│   │   ├── skill_execution_view.dart
│   │   └── destructive_action_overlay.dart
│   └── router/
│       ├── app_router.dart
│       └── route_guards.dart
│
├── src/                              # Legacy / migration zone
│   ├── providers/                    # Shared state providers
│   │   ├── auth_provider.dart
│   │   ├── cart_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── address_provider.dart
│   │   ├── anything_provider.dart
│   │   ├── loyalty_provider.dart
│   │   ├── driver_wallet_provider.dart
│   │   └── skill_registry_provider.dart
│   ├── models/                       # Firestore DTOs
│   │   ├── user_model.dart
│   │   ├── order_model.dart
│   │   ├── driver_model.dart
│   │   ├── vendor.dart
│   │   ├── product.dart
│   │   ├── cart_line_item.dart
│   │   ├── modifier.dart
│   │   ├── promo_model.dart
│   │   ├── saved_address.dart
│   │   ├── smart_address.dart
│   │   ├── loyalty_transaction.dart
│   │   ├── driver_wallet_model.dart
│   │   └── anything_request_model.dart
│   ├── repositories/                 # Legacy repository classes
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   └── order_repository.dart
│   ├── services/
│   │   ├── auth_gate.dart
│   │   └── auth_listenable.dart
│   ├── screens/                      # Shared screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── access_denied_screen.dart
│   │   ├── app_scaffold.dart
│   │   ├── auth_state_redirector.dart
│   │   ├── payment_selection_sheet.dart
│   │   └── cashier_terminal_screen.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── route_names.dart
│   ├── utils/
│   │   └── result.dart
│   ├── firebase/
│   │   └── firebase_options.dart
│   └── widgets/                      # Legacy shared widgets
│       ├── order_status_badge.dart
│       ├── shimmer_loading.dart
│       ├── empty_state.dart
│       ├── driver_live_map.dart
│       ├── auto_dispatch_listener.dart
│       ├── async_screen_builder.dart
│       ├── error_boundary.dart
│       ├── error_retry_widget.dart
│       ├── order_rating.dart
│       └── triple_state_widget.dart
```

### Option B: Multi-Package with Domain / Infrastructure / Presentation Separation

Split into three packages for stricter dependency enforcement. Use if the monorepo team size grows beyond 5 engineers.

```
packages/
├── tayybe  go_core_domain/           # Pure Dart, zero Flutter dependency
│   ├── entities/
│   ├── enums/
│   ├── value_objects/
│   ├── repositories/ (abstract)
│   └── services/ (abstract)
│
├── tayybe  go_core_infrastructure/   # Flutter + Firebase dependencies
│   ├── repositories/ (Firestore)
│   └── services/ (implementations)
│   └── depends on: tayybe  go_core_domain
│
├── tayybe  go_core_presentation/     # Flutter widgets, theme, router
│   ├── theme/
│   ├── shared_widgets/
│   └── router/
│   └── depends on: tayybe  go_core_domain
│
├── tayybe  go_multi_tenant/
│   └── depends on: tayybe  go_core_domain
│
├── tayybe  go_payment/
│   └── depends on: tayybe  go_core_domain
│
└── tayybe  go_payout/
    └── depends on: tayybe  go_core_domain
```

**Pros:** Enforces clean architecture at the dependency level. Pure domain package can be unit-tested without Flutter.  
**Cons:** Package management overhead, version coordination, more complex tooling.

---

## Rule: What Lives Where

### Belongs in `tayybe`go_core`

| Artifact | Justification |
|---|---|
| All domain entities | Shared by every app |
| All enums | Single source of truth |
| All value objects | Type safety across apps |
| Abstract repository interfaces | Contracts all repos must implement |
| Abstract service interfaces | Contracts for business services |
| Theme system | Brand consistency |
| Shared widgets | Avoid duplication |
| State providers | Auth, cart, locale, address, etc. |
| Firestore DTOs | Consistent serialization |
| Result\<T\> utility | Used by all async operations |
| Router + guards | Consistent navigation |

### Belongs in App-Specific Code

| Artifact | Justification |
|---|---|
| App-specific screens | Layout varies per app |
| App-specific providers | State not shared across apps |
| App-specific widgets | Not reusable |
| App entry point (main.dart) | One per app |

### Belongs in Separate Packages (Future)

| Package | Contents | Priority |
|---|---|---|
| `tayybe`go_multi_tenant` | Tenant entity, VerticalType, CommissionRate, ServiceArea | Already exists — needs expansion |
| `tayybe`go_payment` | Payment processing entities and gateway | Stub — needs expansion |
| `tayybe`go_payout` | Payout processing entities | Stub — needs expansion |
| `tayybe`go_analytics` | Analytics service (future) | Low |
| `tayybe`go_loyalty` | Loyalty program (future) | Low |

---

## Barrel File Guidelines

### Current Issue
`tayybe`go_core.dart` exports 162 symbols without grouping, making it hard to understand what's available.

### Recommendation

Organize barrel exports by layer with clear section headers:

```dart
// ============================================================
// Domain Layer
// ============================================================
export 'domain/enums/user_role.dart';
export 'domain/enums/order_status.dart';
// ...

// ============================================================
// Infrastructure Layer
// ============================================================
export 'infrastructure/services/order_state_machine.dart';
// ...

// ============================================================
// Presentation Layer
// ============================================================
export 'presentation/theme/app_colors.dart';
// ...
```

---

## Migration Path

1. **Current:** Single `tayybe`go_core` with 162 exports (no migration needed)
2. **Phase 1:** Reorganize barrel file with section headers for readability
3. **Phase 2:** Extract `tayybe`go_payment` and `tayybe`go_payout` from stubs to full implementations
4. **Phase 3 (if needed):** Split `domain/` into a pure-Dart package if testing or dependency isolation becomes a bottleneck

---

## Dependency Table

| Package | Depends On | Dart-only? |
|---|---|---|
| tayybe`go_core`| cloud_firestore, firebase_*, flutter | No |
| tayybe`go_multi_tenant`| tayybe`go_core`, cloud_firestore | No |
| tayybe`go_payment`| tayybe`go_core`, cloud_firestore | No |
| tayybe`go_payout`| tayybe`go_core`, cloud_firestore | No |
| tayybe`go_customer`| tayybe`go_core`, tayybe`go_multi_tenant` | No |
| tayybe`go_partner`| tayybe`go_core` | No |
| tayybe`go_driver`| tayybe`go_core` | No |
| tayybe`go_admin`| tayybe`go_core`, tayybe`go_multi_tenant` | No |
