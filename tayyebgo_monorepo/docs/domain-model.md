# Domain Model Specification — Tayybe Go

## 1. User

The unified identity for every actor in the system. All roles are stored in a single `Users` collection.

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | Firebase Auth UID |
| email | String | yes | |
| displayName | String | yes | |
| photoUrl | String? | no | Profile image |
| phone | String | no | |
| role | UserRole | yes | Enum: superAdmin, restaurantOwner, cashier, driver, customer |
| isActive | bool | no | Default true. Admin deactivates |
| createdAt | DateTime | yes | |
| updatedAt | DateTime | no | Server timestamp |
| restaurantId | String? | no | Links to Restaurant for owner/cashier roles |
| fcmToken | String? | no | Firebase Cloud Messaging token |
| currentOrderId | String? | no | Driver's active order |

**Source:** `packages/tayyebgo_core/lib/domain/entities/user.dart`

---

## 2. Customer

A customer is a `User` with `role = customer`. Customer-specific data is embedded in the Order (profile snapshot at time of order) or stored in the `Users` document. No separate customer entity exists in the domain layer.

**Key attributes inherited from User:**
- id, email, displayName, phone
- saved addresses (subcollection of Users)
- loyalty points (field on Users)

**Source:** Orders embed `customerId`, `customerName`, `customerPhone`, `customerEmail` at creation time (snapshot pattern).

---

## 3. Driver

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | Firebase Auth UID |
| name | String | yes | |
| email | String | yes | |
| phone | String | no | |
| vehicle | String | no | e.g. "Car", "Motorcycle" |
| driverType | DriverType | no | enum: platform, store |
| storeId | String? | no | Only for store-affiliated drivers |
| isOnline | bool | no | Driver availability toggle |
| isActive | bool | no | Admin deactivation flag |
| currentLocation | GeoLocation? | no | Live GPS coordinates |
| rating | double | no | 1.0-5.0, default 5.0 |
| activeDeliveries | int | no | Count of in-progress deliveries |
| createdAt | DateTime | yes | |

**Enums:**
- `DriverType.platform` — platform-affiliated driver, can serve any store
- `DriverType.store` — store-affiliated driver, only serves specific store

**Source:** `packages/tayyebgo_core/lib/domain/entities/driver.dart`

---

## 4. Store (Restaurant / Brand / Branch)

### Brand
Multi-branch brand entity.

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | |
| name | String | yes | |
| description | String? | no | |
| logoUrl | String? | no | |
| coverImageUrl | String? | no | |
| cuisineTypes | List\<String\> | no | |
| website | String? | no | |
| contactEmail | String? | no | |
| contactPhone | String? | no | |
| isActive | bool | no | |

### Branch
Physical location for a brand.

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | |
| brandId | String | yes | Parent brand |
| name | String | yes | |
| slug | String? | no | URL-friendly name |
| address | Address? | no | |
| location | GeoLocation? | no | |
| geohash | String? | no | For proximity queries |
| phone | String? | no | |
| imageUrl | String? | no | |
| isActive | bool | no | |
| operatingHours | List\<OperatingHours\> | no | Per-day schedule |
| timezone | String? | no | |

### Restaurant (Vendor)
Legacy single-location store entity. Still used for primary store operations.

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | |
| name | String | yes | |
| cuisineType | String | yes | |
| isActive | bool | no | |
| ownerId | String | yes | FK to User |
| phone | String | no | |
| address | Address | yes | |
| location | GeoLocation | yes | |
| imageUrl | String? | no | |
| commissionPercent | double | no | Default 15.0 |
| createdAt | DateTime | yes | |
| deliveryMode | DeliveryMode | no | store_only, platform_only, hybrid |
| allowPlatformFallback | bool | no | |
| fallbackDelaySeconds | int | no | |

**Enums:**
- `DeliveryMode.storeOnly` — only store drivers
- `DeliveryMode.platformOnly` — only platform drivers
- `DeliveryMode.hybrid` — store drivers first, fallback to platform

**Source:**
- `packages/tayyebgo_core/lib/domain/entities/restaurant.dart`
- `packages/tayyebgo_core/lib/domain/entities/brand.dart`
- `packages/tayyebgo_core/lib/domain/entities/branch.dart`
- `packages/tayyebgo_core/lib/src/models/vendor.dart`

---

## 5. Order

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | Document ID |
| customerId | String | yes | FK to User |
| customerName | String | yes | Snapshot at order time |
| customerPhone | String | no | |
| customerEmail | String? | no | |
| restaurantId | String | yes | FK to Restaurant |
| restaurantName | String | yes | |
| status | OrderStatus | no | Default: placed |
| items | List\<OrderItem\> | no | |
| subtotal | Money | no | In cents |
| deliveryFee | Money | no | |
| tax | Money | no | |
| totalAmount | Money | no | |
| fulfillmentType | FulfillmentType | no | delivery or pickup |
| deliveryAddress | Address? | no | |
| restaurantLocation | GeoLocation? | no | |
| driverId | String? | no | FK to User (driver) |
| driverName | String? | no | |
| statusHistory | List\<StatusTransition\> | no | Immutable audit log |
| createdAt | DateTime | yes | |
| acceptedAt | DateTime? | no | |
| readyAt | DateTime? | no | |
| dispatchedAt | DateTime? | no | |
| deliveredAt | DateTime? | no | |
| rejectionReason | String? | no | |
| promoCode | String? | no | |
| discount | Money? | no | |
| updatedAt | DateTime? | no | Server timestamp |

### OrderItem
| Field | Type | Notes |
|---|---|---|
| name | String | |
| price | Money | In cents |
| quantity | int | |
| modifiers | List\<String\> | Modifier names |

### StatusTransition
| Field | Type | Notes |
|---|---|---|
| fromStatus | OrderStatus | |
| toStatus | OrderStatus | |
| timestamp | DateTime | |
| actorId | String | Who performed the transition |
| location | GeoLocation? | GPS at time of transition |
| note | String? | Reason or comment |

### OrderStatus (State Machine)
```
placed → accepted → preparing → ready → readyForDriver → dispatched → pickedUp → delivered
  ↓         ↓           ↓          ↓            ↓              ↓           ↓
  └── cancelled ←───────┴──────────┴────────────┴──────────────┴───────────┴── (any non-terminal state)
```

Terminal states: `delivered`, `cancelled`

**Source:** `packages/tayyebgo_core/lib/domain/entities/order.dart`  
**State machine:** `packages/tayyebgo_core/lib/infrastructure/services/order_state_machine.dart`

---

## 6. Delivery

Delivery is managed through the **DispatchRequest** and **DispatchZone** entities.

### DispatchRequest

| Field | Type | Required | Notes |
|---|---|---|---|
| id | String | yes | |
| orderId | String | yes | FK to Order |
| brandId | String | yes | |
| branchId | String | yes | |
| pickupLocation | GeoLocation | yes | |
| dropoffLocation | GeoLocation | yes | |
| assignedDriverId | String? | no | |
| status | DispatchStatus | yes | pending, scoring, assigned, accepted, unassigned, overloaded, fallback_waiting |
| candidateScores | List\<DriverScore\> | no | Ranked driver candidates |
| deliveryMode | DeliveryMode | no | |

### DriverScore
| Field | Type | Notes |
|---|---|---|
| driverId | String | |
| driverName | String | |
| driverType | String | platform / store |
| etaMinutes | double | |
| distanceKm | double | |
| rating | double | |
| activeDeliveries | int | |
| score | double | Composite score |

### DispatchZone

| Field | Type | Notes |
|---|---|---|
| id | String | |
| branchId | String | |
| name | String | |
| centerLat / centerLon | double | |
| radiusKm | double | |
| minimumOrder | Money | |
| deliveryFee | Money | |
| estimatedMinutes | int | |
| isActive | bool | |

**Source:** `packages/tayyebgo_core/lib/domain/entities/dispatch_request.dart`  
`packages/tayyebgo_core/lib/domain/entities/dispatch_zone.dart`

---

## 7. Payment

### PaymentMethod (Saved)
| Field | Type | Notes |
|---|---|---|
| id | String | |
| userId | String | |
| type | PaymentMethodType | stripe or shamCash |
| lastFourDigits | String? | |
| cardBrand | String? | |
| isDefault | bool | |

### Payment Processing (via PaymentGateway)
Payments are processed through a gateway abstraction that supports:
- **Stripe** — card payments via Stripe Checkout
- **Sham Cash** — cash-on-delivery model

**Enums:**
- `PaymentMethodType.stripe` — card payment
- `PaymentMethodType.shamCash` — cash payment

**Source:** `packages/tayyebgo_core/lib/domain/entities/payment_method.dart`  
`packages/tayyebgo_core/lib/infrastructure/services/payment_gateway.dart`  
`packages/tayyebgo_core/lib/domain/services/i_payment_service.dart`

---

## 8. Menu

### MenuItem
| Field | Type | Notes |
|---|---|---|
| id | String | |
| brandId | String? | |
| branchId | String? | |
| sharedItemId | String? | For shared menus |
| name | String | |
| description | String? | |
| price | Money | |
| originalPrice | Money? | For discounts |
| category | String? | |
| tags | List\<String\> | |
| modifierGroups | List\<MenuModifierGroup\> | |
| isAvailable | bool | |
| isSignature | bool | |
| imageUrl | String? | |
| sortOrder | int | |

### MenuModifierGroup
| Field | Type | Notes |
|---|---|---|
| id | String | |
| name | String | |
| isRequired | bool | |
| minSelections | int | |
| maxSelections | int | |
| modifiers | List\<MenuModifier\> | |

### MenuModifier
| Field | Type | Notes |
|---|---|---|
| id | String | |
| name | String | |
| extraPrice | Money | |
| isDefault | bool | |

**Source:** `packages/tayyebgo_core/lib/domain/entities/menu_item.dart`  
`packages/tayyebgo_core/lib/domain/entities/menu_modifier.dart`

---

## 9. Promotion

| Field | Type | Notes |
|---|---|---|
| id | String | |
| name | String | |
| description | String? | |
| discountPercent | double | |
| maxDiscount | Money? | |
| minOrder | Money? | |
| isActive | bool | |
| usageLimit | int? | |
| usedCount | int | |
| startDate | DateTime? | |
| endDate | DateTime? | |

**Source:** `packages/tayyebgo_core/lib/domain/entities/promotion.dart`

---

## 10. Payout

| Field | Type | Notes |
|---|---|---|
| id | String | |
| restaurantId / vendorId | String | |
| restaurantName / vendorName | String | |
| grossAmount | Money | |
| commissionAmount / fee | Money | |
| netAmount | Money | |
| status | PayoutStatus | pending, processing, paid, failed |
| periodStart / periodEnd | DateTime | |
| notes | String? | |
| paidAt | DateTime? | |

**Source:** `packages/tayyebgo_core/lib/domain/entities/payout.dart`  
`packages/tayyebgo_payout/lib/domain/entities/payout.dart`

---

## 11. Value Objects

| Value Object | Fields | Purpose |
|---|---|---|
| Money | amountInCents (int) | All monetary amounts. Supports +, -, *, formatting |
| Address | street, district, city, additionalInfo, location (GeoLocation) | Physical address |
| GeoLocation | latitude, longitude | GPS coordinates with Haversine distance calculation |
| Geohash | hash (String) | Geohash encoding/decoding with precision-based radius lookup |
| OperatingHours | dayOfWeek, openMinutes, closeMinutes, isClosed | Store operating schedule |
| PendingOperation | type, orderId, newStatus, ... | Offline queue operation for pending state changes |

**Source:** `packages/tayyebgo_core/lib/domain/value_objects/`

---

## 12. Tenant (Multi-Vertical)

| Field | Type | Notes |
|---|---|---|
| id | String | |
| name | String | |
| verticalType | VerticalType | Enum: food, grocery, pharmacy, parcel, etc. |
| isActive | bool | |
| commissionPercent | double | |
| ownerId | String | |
| serviceArea | ServiceArea | Bounding box |
| logoUrl | String? | |
| contactEmail | String? | |
| contactPhone | String? | |

**Source:** `packages/tayyebgo_multi_tenant/`

---

## 13. Entity Relationships

```
User (Users collection)
  ├── role: customer
  │     └── saved_addresses (subcollection)
  │     └── loyalty_transactions (subcollection)
  ├── role: driver
  │     └── references Driver entity
  │     └── driver_wallets (collection)
  ├── role: restaurantOwner
  │     └── owns Restaurant via restaurantId
  ├── role: cashier
  │     └── works at Restaurant via restaurantId
  └── role: superAdmin / admin
        └── no additional relations

Restaurant
  ├── has owner (User.restaurantId)
  ├── has branches (Brand/Branch)
  ├── has menu_items
  └── has dispatch_zones

Order
  ├── references User (customerId, driverId)
  ├── references Restaurant (restaurantId)
  └── has 1:1 DispatchRequest (via orderId)

DispatchRequest
  ├── references Order
  ├── references Driver (assignedDriverId)
  └── references Branch (pickup location)

Payment
  ├── references Order
  └── references User
```

---

## 14. Firestore Collections

| Collection | Document | Key Subcollections |
|---|---|---|
| Users | User data | saved_addresses, loyalty_transactions |
| Restaurants | Restaurant/Vendor | menu_items, reviews |
| Orders | Order + items | — |
| dispatch_requests | DispatchRequest | — |
| dispatch_zones | DispatchZone | — |
| brands | Brand | — |
| branches | Branch (subcollection of brands) | — |
| menu_items | MenuItem | — |
| promotions | Promotion | — |
| payouts | Payout | — |
| transactions | Payment transaction | — |
| notifications | Notification | — |
| activity_log | Audit log entry | — |
| driver_wallets | DriverWallet | — |
| driver_locations | GPS ping | — |
| anything_requests | AnythingRequest | — |
| settings | Platform config singleton | — |

**Source:** `firestore.rules`, `firestore.indexes.json`, code repository implementations
