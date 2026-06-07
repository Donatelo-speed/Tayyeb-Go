# Roles & Permissions Matrix — Tayybe Go

## Role Definitions

| Role | Value | Description |
|---|---|---|
| Super Admin | `superAdmin` | Full system access. Override any state. |
| Restaurant Owner | `restaurantOwner` | Owns one or more stores. Manages menu, staff, and operations. |
| Cashier | `cashier` | Store-level order acceptance and terminal operations. |
| Driver | `driver` | Delivery execution. Accept/reject orders, update status, send GPS. |
| Customer | `customer` | Browse, order, track, and pay. |

## Authority Rules

### Customer

| Permission | Scope | Notes |
|---|---|---|
| Create order | Self | Only valid if active and not banned |
| Cancel order | Self | Only before `accepted` status |
| Track order | Self | Real-time view of order + dispatch status |
| Update profile | Self | Name, phone, photo, addresses |
| Add payment method | Self | Stripe or Sham Cash |
| View order history | Self | |
| Write reviews | Self | On completed orders only |
| Redeem loyalty points | Self | Subject to balance |

**Cannot:**
- Assign drivers
- Alter delivery state
- Edit pricing or payment records
- Access other users' data

### Driver

| Permission | Scope | Notes |
|---|---|---|
| Accept order | Self-assigned via dispatch | From `assigned` dispatch status |
| Reject order | Self | Triggers reassignment |
| Update delivery status | Self | pickedUp → delivered |
| Update GPS location | Self | Continuous during active delivery |
| View earnings | Self | Driver wallet and payout history |
| Go online/offline | Self | Availability toggle |

**Cannot:**
- Edit pricing
- Edit payment records
- Override assignments
- Cancel orders independently
- View other drivers' data

### Store / Restaurant Owner

| Permission | Scope | Notes |
|---|---|---|
| Manage menu items | Own stores | Create, update, delete menu items and modifiers |
| Receive orders | Own stores | View incoming orders in real time |
| Accept/reject orders | Own stores | Before `preparing` |
| Mark order ready | Own stores | `preparing` → `ready` |
| Manage store profile | Own stores | Name, hours, address, delivery mode |
| View earnings | Own stores | Payout history and revenue |
| Manage staff | Own stores | Add/remove cashiers |
| View analytics | Own stores | Order volume, revenue, ratings |

**Cannot:**
- Assign drivers (dispatch is automatic)
- Alter settlements
- Access other stores' data
- Override platform-level settings

### Cashier

| Permission | Scope | Notes |
|---|---|---|
| Accept orders | Assigned store | |
| Mark orders ready | Assigned store | |
| Process cash payments | Assigned store | |
| View current orders | Assigned store | |
| Operate terminal | Assigned store | Cashier-specific UI |

**Cannot:**
- Manage menu items
- View earnings/payouts
- Manage staff
- Access platform admin features

### Admin

| Permission | Scope | Notes |
|---|---|---|
| Manage users | All | Activate/deactivate, change roles |
| Manage stores | All | Create, edit, deactivate |
| Manage drivers | All | Verify, approve, deactivate |
| Override orders | All | Force state transitions |
| Resolve disputes | All | Cancel, refund, adjust |
| View analytics | All | Platform-wide metrics |
| Manage promotions | All | |
| View audit log | All | Activity log, order history |
| Manage platform config | All | Settings, maintenance mode |
| Export data | All | CSV/PDF |

## Order State Transition Authority

```
State            → Next State          → Authorized Actor
──────────────────────────────────────────────────────────
placed           → accepted            → Store (Owner/Cashier)
placed           → cancelled           → Customer (before acceptance)
accepted         → preparing           → Store
accepted         → cancelled           → Store, Admin
preparing        → ready               → Store
preparing        → cancelled           → Store, Admin
ready            → dispatched          → System (auto-dispatch)
dispatched       → pickedUp            → Driver
pickedUp         → delivered           → Driver
any              → cancelled           → Admin (always)
any              → [any]               → Admin (override)
```

## Permission Matrix (Compact)

| Action | Customer | Driver | Cashier | Owner | Admin | SuperAdmin |
|---|---|---|---|---|---|---|
| Create order | ✓ | — | — | — | ✓ | ✓ |
| Cancel order (pre-accept) | ✓ | — | — | — | ✓ | ✓ |
| Cancel order (any state) | — | — | — | partial | ✓ | ✓ |
| Accept order (store) | — | — | ✓ | ✓ | ✓ | ✓ |
| Accept delivery | — | ✓ | — | — | — | — |
| Update delivery status | — | ✓ | — | — | ✓ | ✓ |
| Update GPS | — | ✓ | — | — | — | — |
| Manage menu | — | — | — | ✓ | ✓ | ✓ |
| Mark order ready | — | — | ✓ | ✓ | ✓ | ✓ |
| Manage store profile | — | — | — | ✓ | ✓ | ✓ |
| Manage staff | — | — | — | ✓ | ✓ | ✓ |
| View earnings | — | ✓ | — | ✓ | ✓ | ✓ |
| Manage users | — | — | — | — | ✓ | ✓ |
| Manage drivers | — | — | — | — | ✓ | ✓ |
| Override orders | — | — | — | — | ✓ | ✓ |
| View analytics | — | — | — | own | all | all |
| Manage platform config | — | — | — | — | ✓ | ✓ |
| View audit log | — | — | — | — | ✓ | ✓ |

## Implementation Notes

- **Authorization is enforced at the Firestore security rules level** (`firestore.rules`) using helper functions: `isAuthenticated()`, `isAdmin()`, `isOwner(uid)`, `hasRole(role)`, `isRestaurantOwner(restaurantId)`, `isDriver()`, `isCashier(restaurantId)`, `isCustomer()`.
- **Custom claims** are set via `setUserRole` Cloud Function for Firebase Auth tokens.
- **The Core Engine** (services in `infrastructure/services/`) performs authorization checks before executing business logic. Apps should never trust client-side role checks alone.
