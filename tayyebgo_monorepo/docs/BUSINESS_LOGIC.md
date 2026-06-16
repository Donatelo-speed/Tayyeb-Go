# Business Logic Documentation

## Order Flow

### End-to-End Order Lifecycle

1. **Customer places order** — Selects items, chooses delivery address, selects payment method, optionally applies promo code. Order status: `placed`.
2. **Restaurant receives notification** — Push notification sent to the partner app. Restaurant can accept or reject.
3. **Restaurant accepts** — Status transitions to `accepted`. Restaurant begins preparing the order.
4. **Restaurant marks ready** — Status: `preparing` → `ready` → `readyForDriver`.
5. **Auto-dispatch triggers** — System finds the best available driver using weighted scoring algorithm.
6. **Driver accepts dispatch** — Status: `dispatched`. Driver navigates to restaurant.
7. **Driver picks up order** — Status: `pickedUp`. Driver heads to customer.
8. **Driver delivers** — Status: `delivered`. Customer can rate the delivery.

### Order Cancellation

- Customers can cancel orders in `placed`, `pending`, or `accepted` states.
- Once `preparing` or later, cancellation requires restaurant approval.
- Refunds are handled based on the original payment method.

### Scheduled Orders

Customers can schedule orders for a future time. The order is created with status `placed` but the dispatch timer is set to trigger closer to the scheduled delivery time.

## Driver Dispatch Algorithm

### Auto-Dispatch Scoring

The `DriverScorer` (`packages/tayyebgo_core/lib/infrastructure/services/driver_scorer.dart`) evaluates each available driver on four factors:

```
Score = (ETA_norm × -0.40) + (rating_norm × 0.25) + (load_factor × 0.20) + (distance_norm × -0.15)
```

| Factor | Weight | What It Measures | Optimal |
|---|---|---|---|
| ETA to pickup | 40% | Estimated minutes to reach restaurant (500m/min assumption) | Lower = better |
| Driver rating | 25% | Average customer rating (out of 5.0) | Higher = better |
| Current load | 20% | Capacity: 1.0 − (activeDeliveries × 0.25) | Less busy = better |
| Distance to pickup | 15% | Physical distance in km | Closer = better |

- Drivers with no current location are excluded.
- ETA is clamped between 2 and 60 minutes.
- Load factor floors at 0 (a driver with 4+ active deliveries scores 0 on load).
- The highest-scoring driver receives the dispatch offer.

### Dispatch Timeout

If a driver doesn't accept within the timeout window, the system re-dispatches to the next-best driver. This is managed via Cloud Functions (`checkDispatchTimeouts`).

## Commission Model

**Default platform commission: 15%**

- `CommissionCalculator` computes: `commission = grossAmount × commissionPercent / 100`
- Restaurant receives: `netAmount = grossAmount − commission`
- Commission rate is configurable per restaurant via subscription tier.

### Revenue Split Example

| Order Total | Commission (15%) | Restaurant Receives |
|---|---|---|
| $20.00 | $3.00 | $17.00 |
| $50.00 | $7.50 | $42.50 |
| $100.00 | $15.00 | $85.00 |

## Subscription Plans

### Plan Comparison

| Feature | Basic | Plus | Premium |
|---|---|---|---|
| Duration | 1 month | 3 months | 6 months |
| Price | 10,000 | 25,000 | 45,000 |
| Discount | 5% | 10% | 15% |
| Free delivery | Yes | Yes | Yes |
| Priority offers | Yes | — | — |
| Monthly offers | — | Yes | Yes |
| Priority support | — | Yes | Yes |
| Exclusive deals | — | — | Yes |
| Early access | — | — | Yes |

### Subscription Benefits

- Discounts are applied automatically at checkout for subscribers.
- Free delivery applies to all orders regardless of distance.
- Subscription status is checked via `SubscriptionService` before applying benefits.

## Payment Methods

### Supported Methods

| Method | Provider | Availability |
|---|---|---|
| Cash on Delivery | Local (no API) | All markets |
| ShamCash Wallet | ShamCash API | Supported regions |
| Credit/Debit Card | Stripe | Stripe-supported countries |

### PaymentOrchestrator

Routes payment to the correct provider based on `PaymentMethodType`:

```dart
// Pseudocode
switch (paymentMethod) {
  case cash:  CashPaymentProvider.process()
  case shamCash: ShamCashPaymentProvider.process()
  case stripe: StripePaymentProvider.process()
}
```

All providers implement `IPaymentProvider` for consistency.

### Stripe Integration

- Payment intents are created via Cloud Functions (`createStripePaymentIntent`).
- Wallet top-ups use `createWalletTopUpIntent`.
- Driver payouts are processed via `processDriverPayout`.

## Promo Code System

### Validation Rules

1. **One-time use** — Each promo code can only be used once per user.
2. **Expiry** — Codes have an expiration date; expired codes are rejected.
3. **Minimum order** — Some codes require a minimum order amount.
4. **Discount type** — Percentage-based or fixed-amount discounts.
5. **Abuse detection** — `PromoAbuseService` and `FraudScoringService` detect abuse via device fingerprinting, IP analysis, and usage patterns.

### Flow

1. Customer enters promo code at checkout.
2. `validatePromo` Cloud Function checks validity.
3. If valid, discount is applied to the order total.
4. On order completion, the promo usage is recorded.

## Safety Features

- **SOS Emergency** — `onSOSEmergency` Cloud Function triggers alerts for drivers.
- **Order Pricing Validation** — `validateOrderPricing` verifies totals before payment.
- **Fake Order Detection** — `FakeOrderDetector` flags suspicious order patterns.
- **Fraud Scoring** — `FraudScoringService` assigns risk scores to orders.
