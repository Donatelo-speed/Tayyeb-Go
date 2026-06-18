# TayyebGo Business Logic

## Order Flow

### Customer Journey
```
Browse → Select Items → Add to Cart → Checkout → Payment → Confirmation → Tracking → Delivery → Rating
```

### Order States
1. **Pending** — Order placed, awaiting partner confirmation
2. **Confirmed** — Partner accepted order
3. **Preparing** — Partner is preparing the order
4. **Ready** — Order ready for pickup
5. **Picked Up** — Driver collected order
6. **On the Way** — Driver en route to customer
7. **Delivered** — Order completed
8. **Cancelled** — Order cancelled (by any party)

### Driver Assignment
1. Order placed → Broadcast to nearby available drivers
2. Driver accepts → Driver assigned
3. If no acceptance in 2 min → Expand radius
4. If still no acceptance → Notify partner to delay

---

## Pricing Logic

### Delivery Fee
```
Base Fee: 1,000 SYP
Per KM: 200 SYP
Minimum: 1,500 SYP
Maximum: 5,000 SYP
Free Delivery Threshold: 50,000 SYP (non-subscribers)
```

### Subscription Benefits
- Free delivery on all orders
- 3% discount on orders under 20,000 SYP
- 5% discount on orders 20,000-50,000 SYP
- 10% discount on orders 50,000-100,000 SYP
- 15% discount on orders over 100,000 SYP

### Partner Commission
- Standard: 10% per order
- Promo orders: 5% (subsidized by platform)

---

## Payment Logic

### Supported Methods
1. **Cash on Delivery** — Driver collects
2. **Sham Cash** — Mobile wallet
3. **Credit/Debit Card** — Via payment gateway

### Driver Payouts
- Daily automatic payout to driver wallet
- Instant withdrawal available (1% fee)
- Minimum withdrawal: 5,000 SYP

### Partner Payouts
- Weekly automatic payout
- Net of commission
- Direct bank transfer

---

## Anything Delivery

### Flow
1. Customer selects "Anything Delivery"
2. Customer describes item + provides photo/link
3. Platform estimates cost (item + delivery fee)
4. Customer confirms and pays
5. Driver purchases item
6. Driver delivers to customer

### Pricing
- Item cost + 15% service fee + standard delivery fee
- Maximum item value: 500,000 SYP
- Restricted items: Alcohol, tobacco, weapons

---

## Rating System

### Customer Ratings
- 1-5 stars for: Food quality, Delivery speed, Driver behavior
- Written review optional
- Affects partner visibility and driver performance

### Partner Ratings
- Average of all customer ratings
- Affects search ranking
- Below 4.0 triggers review

### Driver Ratings
- Average of all customer ratings
- Affects order priority
- Below 4.5 triggers coaching

---

## Notification Triggers

### Customer Notifications
- Order confirmed
- Order preparing
- Driver assigned
- Driver approaching
- Order delivered
- Promotional offers
- Subscription reminders

### Driver Notifications
- New order available
- Order assigned
- Route update
- Earnings update
- Safety alerts

### Partner Notifications
- New order received
- Order cancelled
- Low inventory alert
- Daily sales report
- Payout processed

---

## Search & Discovery

### Search Ranking Factors
1. Partner rating (30%)
2. Delivery time (25%)
3. Order volume (20%)
4. Promoted status (15%)
5. Distance (10%)

### Filters
- Category (Food, Grocery, Pharmacy)
- Price range
- Delivery time
- Rating
- Open now
- Free delivery

---

## Fraud Prevention

### Order Fraud
- Maximum 3 orders per hour per account
- Address verification
- Phone number verification
- Suspicious activity alerts

### Payment Fraud
- Card validation
- Address verification system
- Transaction monitoring
- Manual review for high-value orders

### Driver Fraud
- GPS tracking verification
- Photo proof of delivery
- Customer confirmation
- Automated anomaly detection

---

## Multi-City Logic

### City Configuration
- Operating hours
- Delivery zones
- Pricing multipliers
- Partner availability
- Driver supply

### Expansion Criteria
- Minimum 50 partners
- Minimum 100 drivers
- Minimum 1,000 orders/week
- Average delivery time < 30 min
- Customer satisfaction > 4.5
