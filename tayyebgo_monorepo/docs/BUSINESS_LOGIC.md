# TayyebGo — Business Logic Reference

## 1. Order Lifecycle

### Order State Machine

Orders follow a strict finite state machine defined in `OrderStatus` (`domain/enums/order_status.dart`) and enforced by `OrderStateMachine` (`infrastructure/services/order_state_machine.dart`).

```
                    ┌──────────────┐
                    │   placed     │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            │            ▼
        ┌──────────┐       │     ┌────────────┐
        │cancelled │       │     │  accepted   │
        └──────────┘       │     └─────┬───────┘
                           │           │
                           │     ┌─────┴───────┐
                           │     │  preparing   │
                           │     └─────┬───────┘
                           │           │
                           │     ┌─────┴───────┐
                           │     │    ready      │
                           │     └─────┬───────┘
                           │           │
                           │     ┌─────┴──────────┐
                           │     │ readyForDriver  │
                           │     └─────┬──────────┘
                           │           │
                           │     ┌─────┴───────┐
                           │     │  dispatched   │
                           │     └─────┬───────┘
                           │           │
                           │     ┌─────┴───────┐
                           │     │  pickedUp    │
                           │     └─────┬───────┘
                           │           │
                           │     ┌─────┴───────┐
                           │     │  delivered   │ ← Terminal
                           │     └─────────────┘
```

### State Definitions

| State | Code | Description | Entry Trigger |
|---|---|---|---|
| `placed` | Initial | Customer submits order | `OrderPlacementService.placeOrder()` |
| `accepted` | Active | Restaurant confirms order | Store owner/cashier accepts |
| `preparing` | Active | Food is being prepared | Store marks as preparing |
| `ready` | Active | Food ready for pickup | Store marks as ready |
| `readyForDriver` | Active | Awaiting driver assignment | Auto-dispatch triggers |
| `dispatched` | Active | Driver en route to restaurant | Driver accepts dispatch |
| `pickedUp` | Active | Driver has the order | Driver confirms pickup |
| `delivered` | Terminal | Order completed | Driver confirms delivery |
| `cancelled` | Terminal | Order cancelled | Any non-terminal state |

### Status Transition Rules

| From | To | Authorized Actor | Conditions |
|---|---|---|---|
| `placed` | `accepted` | Store (Owner/Cashier) | — |
| `placed` | `cancelled` | Customer | Before acceptance |
| `accepted` | `preparing` | Store | — |
| `accepted` | `cancelled` | Store, Admin | — |
| `preparing` | `ready` | Store | — |
| `preparing` | `cancelled` | Store, Admin | Requires reason |
| `ready` | `readyForDriver` | System | Auto-triggered |
| `readyForDriver` | `dispatched` | System | Auto-dispatch assigns driver |
| `dispatched` | `pickedUp` | Driver | Driver confirms pickup |
| `pickedUp` | `delivered` | Driver | Driver confirms delivery |
| Any non-terminal | `cancelled` | Admin | Admin override always allowed |

### Status History

Every state transition is recorded as a `StatusTransition` entry in `order.statusHistory`:

```dart
StatusTransition(
  fromStatus: OrderStatus.accepted,
  toStatus: OrderStatus.preparing,
  timestamp: DateTime.now(),
  actorId: 'store-owner-uid',
  location: GeoLocation(latitude: 33.5138, longitude: 36.2765),
  note: 'Order received by kitchen',
)
```

This provides a complete audit trail for every order.

### Order Creation Flow

1. **Customer selects items** — Cart populated with `OrderItem` entries
2. **Customer chooses address** — From saved addresses or new
3. **Customer selects payment** — Cash, ShamCash, or Stripe
4. **Customer applies promo** (optional) — Validated via `validatePromo` Cloud Function
5. **Pricing calculated** — Subtotal + delivery fee + tax - discount = total
6. **Order placed** — `OrderPlacementService` creates Firestore document
7. **Restaurant notified** — FCM push notification sent
8. **Restaurant accepts/rejects** — Status transitions to `accepted` or `cancelled`

---

## 2. Dispatch Algorithm

### Auto-Dispatch Scoring

The `DriverScorer` (`infrastructure/services/driver_scorer.dart`) evaluates each available driver using a 4-factor weighted model:

```
Score = (ETA_norm × 0.40) + (rating_norm × 0.25) + (load_factor × 0.20) + (distance_norm × 0.15)
```

### Factor Breakdown

| Factor | Weight | Measurement | Normalization | Optimal |
|---|---|---|---|---|
| ETA to pickup | 40% | Estimated minutes (500m/min) | `1 - (eta - 2) / 58` | Lower = better |
| Driver rating | 25% | Average rating (1.0-5.0) | `rating / 5.0` | Higher = better |
| Current load | 20% | Active deliveries count | `1.0 - (count × 0.25)` | Less busy = better |
| Distance to pickup | 15% | Physical distance (km) | `1 - (dist / maxDist)` | Closer = better |

### Scoring Constraints

- **ETA clamp:** 2-60 minutes (values outside are clamped)
- **Load floor:** 0 (drivers with 4+ active deliveries score 0 on load)
- **Max deliveries:** 4 concurrent (hard limit)
- **Location required:** Drivers without current GPS location are excluded
- **Online only:** Only drivers with `isOnline = true` are candidates
- **Active filter:** Only drivers with `isActive = true` are considered

### Dispatch Flow

1. Order reaches `readyForDriver` status
2. `AutoDispatcher.findAndAssignDriver()` is called
3. Query all online, active drivers within dispatch zone
4. Calculate composite score for each candidate
5. Rank candidates by score (highest first)
6. Send dispatch offer to top candidate
7. Driver has timeout window to accept/reject
8. If rejected or timeout → next candidate
9. If no candidates → order enters `fallback_waiting` state

### Dispatch Statuses

| Status | Description |
|---|---|
| `pending` | Dispatch request created, awaiting scoring |
| `scoring` | Evaluating driver candidates |
| `assigned` | Driver offered the dispatch |
| `accepted` | Driver accepted, en route to pickup |
| `unassigned` | Driver rejected, re-dispatching |
| `overloaded` | No available drivers in zone |
| `fallback_waiting` | Awaiting fallback driver (store → platform) |

### Delivery Mode

Restaurants can configure delivery mode per store:

| Mode | Description | Behavior |
|---|---|---|
| `store_only` | Only store-affiliated drivers | No platform driver fallback |
| `platform_only` | Only platform drivers | No store drivers considered |
| `hybrid` | Store drivers first, platform fallback | Try store drivers, fallback after timeout |

---

## 3. Pricing Engine

### Order Pricing Formula

```
Total = Subtotal + DeliveryFee + Tax - Discount
```

Where:

| Component | Calculation | Description |
|---|---|---|
| **Subtotal** | `Σ(item.price × quantity)` | Sum of all items |
| **DeliveryFee** | Zone-based + distance | See delivery fee rules |
| **Tax** | `subtotal × taxRate` | Configurable per region |
| **Discount** | Promo code or subscription | Applied before tax |

### Delivery Fee Rules

| Factor | Rule |
|---|---|
| Base fee | Configured per dispatch zone |
| Distance surcharge | Per-km rate beyond base radius |
| Minimum order | Enforced per dispatch zone |
| Free delivery | Subscribers get free delivery |
| Peak hours | Optional surge multiplier |

### Dispatch Zone Pricing

Each `DispatchZone` defines:

```dart
DispatchZone(
  minimumOrder: Money(amountInCents: 500),    // $5.00 minimum
  deliveryFee: Money(amountInCents: 150),      // $1.50 base fee
  estimatedMinutes: 30,                         // ETA estimate
  radiusKm: 5.0,                               // Delivery radius
)
```

### Subscription Discounts

| Plan | Discount Applied |
|---|---|
| Basic | 5% off subtotal |
| Plus | 10% off subtotal |
| Premium | 15% off subtotal |

Discounts are applied at checkout via `SubscriptionService` and reflected in the order total.

---

## 4. Loyalty System

### Points Earning

| Action | Points Earned | Notes |
|---|---|---|
| Order completed | 1 point per $1 spent | Rounded down |
| First order bonus | 50 points | One-time |
| Referral (referrer) | 100 points | Per successful referral |
| Referral (referred) | 50 points | One-time |
| Review submitted | 10 points | Per review |
| Profile completed | 25 points | One-time |

### Points Redemption

| Redemption | Points Required | Value |
|---|---|---|
| $1 discount | 100 points | Applied at checkout |
| Free delivery | 50 points | One-time per order |
| Premium item discount | 200 points | 20% off premium items |

### Tier System

| Tier | Points Required | Benefits |
|---|---|---|
| **Bronze** | 0 | Base earning rate (1pt/$1) |
| **Silver** | 500 | 1.2x earning rate, free delivery every 5th order |
| **Gold** | 2,000 | 1.5x earning rate, free delivery every 3rd order, priority support |
| **Platinum** | 5,000 | 2x earning rate, free delivery every order, exclusive deals, early access |

### Tier Progression

- Tiers are evaluated monthly based on rolling 90-day points
- Tier downgrades happen if points fall below threshold for 2 consecutive months
- Tier benefits are applied automatically at checkout
- Points expire after 12 months of account inactivity

### Implementation

- Points are stored in `Users.loyaltyPoints` field
- Transactions are stored in `Users.loyalty_transactions` subcollection
- `LoyaltyProvider` manages client-side state
- Points are awarded via Cloud Functions on order completion

---

## 5. Commission Structure

### Default Commission

**Platform commission: 15%** of order gross amount

### Commission by Partner Tier

| Partner Tier | Commission Rate | Subscription Requirement |
|---|---|---|
| Standard (no subscription) | 15% | None |
| Basic subscriber | 15% | 10,000/month |
| Plus subscriber | 10% | 25,000/3 months |
| Premium subscriber | 5% | 45,000/6 months |

### Commission Calculation

```dart
commission = grossAmount × commissionPercent / 100
netAmount = grossAmount - commission
```

### Revenue Split Examples

| Order Total | Standard (15%) | Plus (10%) | Premium (5%) |
|---|---|---|---|
| $10.00 | $1.50 / $8.50 | $1.00 / $9.00 | $0.50 / $9.50 |
| $20.00 | $3.00 / $17.00 | $2.00 / $18.00 | $1.00 / $19.00 |
| $50.00 | $7.50 / $42.50 | $5.00 / $45.00 | $2.50 / $47.50 |
| $100.00 | $15.00 / $85.00 | $10.00 / $90.00 | $5.00 / $95.00 |

### Payout Schedule

| Tier | Payout Frequency | Minimum Payout |
|---|---|---|
| Standard | Weekly | $50 |
| Basic | Weekly | $25 |
| Plus | Bi-weekly | $10 |
| Premium | Weekly | $5 |

### Payout Statuses

| Status | Description |
|---|---|
| `pending` | Payout calculated, awaiting processing |
| `processing` | Bank transfer initiated |
| `paid` | Successfully transferred |
| `failed` | Transfer failed, retry scheduled |

---

## 6. Subscription Plans

### Plan Comparison

| Feature | Basic | Plus | Premium |
|---|---|---|---|
| **Duration** | 1 month | 3 months | 6 months |
| **Price** | 10,000 | 25,000 | 45,000 |
| **Monthly cost** | 10,000 | ~8,333 | ~7,500 |
| **Discount** | 5% | 10% | 15% |
| **Commission rate** | 15% | 10% | 5% |
| **Free delivery** | ✓ | ✓ | ✓ |
| **Priority offers** | ✓ | ✓ | ✓ |
| **Monthly offers** | — | ✓ | ✓ |
| **Priority support** | — | ✓ | ✓ |
| **Exclusive deals** | — | — | ✓ |
| **Early access** | — | — | ✓ |

### Subscription Benefits

- **Automatic discounts** applied at customer checkout
- **Free delivery** on all orders regardless of distance
- **Lower commission** for the partner
- **Priority in dispatch** — subscribers get drivers assigned faster
- **Analytics access** — higher tiers get more detailed reports

### Subscription Management

- Subscriptions are stored in the Restaurant entity
- `SubscriptionService` validates active subscriptions
- Auto-renewal can be enabled/disabled
- Grace period: 7 days after expiration before benefits are removed
- Early upgrade: Prorated cost for plan changes

---

## 7. Payment Methods

### Supported Methods

| Method | Provider | Availability | Notes |
|---|---|---|---|
| Cash on Delivery | Local (no API) | All markets | Default method |
| ShamCash Wallet | ShamCash API | Supported regions | Pre-funded wallet |
| Credit/Debit Card | Stripe | Stripe-supported countries | Card payments |

### PaymentOrchestrator

Routes payment to the correct provider based on `PaymentMethodType`:

```dart
switch (paymentMethod) {
  case cash:       CashPaymentProvider.process()       // No external API
  case shamCash:   ShamCashPaymentProvider.process()   // ShamCash API
  case stripe:     StripePaymentProvider.process()     // Stripe API
}
```

All providers implement `IPaymentProvider` interface.

### Stripe Integration

| Function | Cloud Function | Purpose |
|---|---|---|
| Create payment intent | `createStripePaymentIntent` | Initialize card payment |
| Wallet top-up | `createWalletTopUpIntent` | Add funds to ShamCash |
| Driver payout | `processDriverPayout` | Transfer to driver account |

### Cash on Delivery

- No external API call
- Driver collects cash from customer
- Amount is tracked in order record
- Settlement happens via driver payout cycle

### ShamCash Wallet

- Customer pre-funds wallet via top-up
- Balance deducted on order placement
- Insufficient balance → fallback to COD
- Wallet transactions logged in `driver_wallets` collection

---

## 8. Promo Code System

### Validation Rules

1. **One-time use** — Each code can only be used once per user
2. **Expiry** — Codes have expiration date; expired codes are rejected
3. **Minimum order** — Some codes require minimum order amount
4. **Discount type** — Percentage-based or fixed-amount
5. **Usage limit** — Global usage cap per code
6. **Abuse detection** — Device fingerprinting, IP analysis, usage patterns

### Promo Code Flow

1. Customer enters promo code at checkout
2. `validatePromo` Cloud Function checks:
   - Code exists and is active
   - Not expired
   - User hasn't used it before
   - Minimum order met
   - Usage limit not reached
3. If valid, discount is applied to order total
4. On order completion, usage is recorded
5. `PromoAbuseService` monitors for abuse patterns

### Fraud Detection

`FraudScoringService` assigns risk scores based on:

| Factor | Weight | Detection |
|---|---|---|
| Device fingerprint | High | Multiple accounts on same device |
| IP analysis | Medium | VPN/proxy detection, IP clustering |
| Usage patterns | Medium | Rapid promo usage, abnormal ordering |
| Order patterns | Low | Unusual order sizes, cancellation history |

### Discount Application

| Type | Calculation | Cap |
|---|---|---|
| Percentage | `subtotal × discountPercent / 100` | Capped at `maxDiscount` |
| Fixed amount | `min(discountAmount, subtotal)` | Cannot exceed order total |

---

## 9. Safety Features

### SOS Emergency

- One-tap emergency button in driver app
- `onSOSEmergency` Cloud Function triggers:
  - Alert to platform admin
  - Last known GPS location shared
  - Emergency contact notified (if configured)
  - Order status frozen until resolved

### Order Pricing Validation

- `validateOrderPricing` Cloud Function verifies:
  - Total matches sum of items
  - Delivery fee is within expected range
  - Tax calculation is correct
  - Discount is valid and applied correctly
- Discrepancies are flagged for admin review

### Fake Order Detection

`FakeOrderDetector` flags suspicious patterns:

| Pattern | Risk Score | Action |
|---|---|---|
| Multiple cancellations from same user | High | Flag account |
| Orders with invalid addresses | Medium | Require verification |
| Unusual order volumes | Medium | Admin review |
| Payment failures in succession | High | Temporary block |

### Fraud Scoring

`FraudScoringService` combines multiple signals:

- Device fingerprinting
- IP reputation
- Order history analysis
- Payment pattern analysis
- Behavioral biometrics (future)

---

## 10. Multi-Vertical Support

### Vertical Types

| Vertical | Description | Special Handling |
|---|---|---|
| `food` | Restaurant delivery | Standard order flow |
| `grocery` | Grocery delivery | Weight-based pricing, substitution rules |
| `pharmacy` | Pharmacy delivery | Prescription verification, regulated items |
| `parcel` | Package delivery | Size/weight limits, signature required |

### Tenant Configuration

Each vertical is configured as a `Tenant` entity:

```dart
Tenant(
  verticalType: VerticalType.food,
  commissionPercent: 15.0,
  serviceArea: ServiceArea(/* bounding box */),
  isActive: true,
)
```

### Cross-Vertical Features

- Shared driver pool (platform drivers can serve multiple verticals)
- Unified payment processing
- Common design system
- Shared analytics dashboard
- Unified notification system

---

## 11. Offline Mode

### Offline Queue

When connectivity is lost, operations are queued in `OfflineQueue`:

| Operation | Queued | Sync Behavior |
|---|---|---|
| Order status update | Yes | Synced on reconnect |
| Driver location ping | Yes | Latest location sent |
| Cart modification | No | Local only |
| Profile update | Yes | Synced on reconnect |

### Sync Engine

On connectivity restore:

1. `SyncEngine` reads pending operations from `OfflineQueue`
2. Operations are ordered by timestamp (FIFO)
3. Each operation is retried with exponential backoff
4. Conflicts are resolved by latest timestamp
5. Successful syncs are removed from queue
6. Failed syncs are retried up to 3 times

### Connectivity Service

- Monitors network status via `connectivity_plus`
- Emits events on connectivity changes
- Drivers: GPS pings continue offline, batched on reconnect
- Orders: Status updates queued, synced on reconnect

---

## 12. Analytics & Revenue

### Platform Analytics (Admin)

| Metric | Calculation | Period |
|---|---|---|
| Gross Merchandise Value | Sum of all order totals | Daily/Weekly/Monthly |
| Platform Revenue | Sum of commissions + delivery fees | Daily/Weekly/Monthly |
| Order Volume | Count of delivered orders | Daily/Weekly/Monthly |
| Active Users | Users with ≥1 order in period | Daily/Weekly/Monthly |
| Active Drivers | Drivers with ≥1 delivery in period | Daily/Weekly/Monthly |
| Active Partners | Partners with ≥1 order in period | Daily/Weekly/Monthly |
| Average Order Value | GMV / Order Volume | Daily/Weekly/Monthly |
| Customer Retention | Users with orders in consecutive periods | Monthly |
| Partner Retention | Partners with orders in consecutive periods | Monthly |

### Partner Analytics

| Metric | Description |
|---|---|
| Store revenue | Total sales for the store |
| Order count | Number of orders received |
| Average order value | Revenue / orders |
| Popular items | Top-selling menu items |
| Peak hours | Busiest times of day |
| Rating trend | Average rating over time |
| Cancellation rate | Cancelled / total orders |
| Repeat customer rate | Returning / total customers |

### Revenue Service

`RevenueService` (`infrastructure/services/revenue_service.dart`) aggregates:

- Platform-wide revenue (commissions + delivery fees)
- Per-store revenue breakdowns
- Per-vertical revenue (multi-vertical mode)
- Time-series data for trend analysis
- Export capability (CSV/PDF)
