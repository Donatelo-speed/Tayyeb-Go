# TayyebGo — API & Database Reference

## 1. Firestore Collections Map

### Top-Level Collections

| Collection | Document ID | Description |
|---|---|---|
| `Users` | Firebase Auth UID | All user accounts (customers, drivers, owners, admins) |
| `Restaurants` | Auto-generated | Store/vendor entities |
| `Orders` | Auto-generated | Order documents with items |
| `dispatch_requests` | Auto-generated | Driver assignment requests |
| `dispatch_zones` | Auto-generated | Delivery area configurations |
| `brands` | Auto-generated | Multi-branch brand entities |
| `branches` | Auto-generated | Physical store locations |
| `menu_items` | Auto-generated | Menu item definitions |
| `promotions` | Auto-generated | Discount codes and campaigns |
| `payouts` | Auto-generated | Partner settlement records |
| `transactions` | Auto-generated | Payment transaction records |
| `notifications` | Auto-generated | Push notification logs |
| `activity_log` | Auto-generated | Audit trail entries |
| `driver_wallets` | Auto-generated | Driver balance records |
| `driver_locations` | Driver UID | Real-time GPS pings |
| `anything_requests` | Auto-generated | Custom delivery tasks |
| `settings` | Singleton | Platform configuration |

### Subcollections

| Parent Collection | Subcollection | Document ID | Description |
|---|---|---|---|
| `Users` | `saved_addresses` | Auto-generated | Customer saved addresses |
| `Users` | `loyalty_transactions` | Auto-generated | Points earn/redeem history |
| `Restaurants` | `menu_items` | Auto-generated | Restaurant-specific menu |
| `Restaurants` | `reviews` | Auto-generated | Customer reviews |
| `brands` | `branches` | Auto-generated | Brand locations |

---

## 2. Document Schemas

### Users

```javascript
{
  id: "firebase-auth-uid",           // Document ID
  email: "user@example.com",
  displayName: "John Doe",
  photoUrl: "https://...",           // nullable
  phone: "+963...",                   // nullable
  role: "customer",                   // enum: superAdmin|restaurantOwner|cashier|driver|customer
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp,               // server timestamp
  restaurantId: "restaurant-doc-id", // nullable, for owner/cashier
  fcmToken: "device-fcm-token",      // nullable
  currentOrderId: "order-doc-id",    // nullable, driver's active order
  loyaltyPoints: 250                  // integer
}
```

### Orders

```javascript
{
  id: "auto-generated",              // Document ID
  customerId: "user-uid",
  customerName: "John Doe",          // snapshot at order time
  customerPhone: "+963...",
  customerEmail: "user@example.com",
  restaurantId: "restaurant-doc-id",
  restaurantName: "Pizza Palace",
  status: "placed",                   // enum
  items: [                            // array of OrderItem
    {
      name: "Margherita Pizza",
      price: { amountInCents: 1500 }, // Money value object
      quantity: 2,
      modifiers: ["Extra Cheese"]     // array of strings
    }
  ],
  subtotal: { amountInCents: 3000 },
  deliveryFee: { amountInCents: 150 },
  tax: { amountInCents: 150 },
  totalAmount: { amountInCents: 3300 },
  fulfillmentType: "delivery",        // enum: delivery|pickup
  deliveryAddress: {
    street: "123 Main St",
    district: "Downtown",
    city: "Damascus",
    additionalInfo: "Apt 4B",
    location: { latitude: 33.5138, longitude: 36.2765 }
  },
  restaurantLocation: { latitude: 33.5100, longitude: 36.2800 },
  driverId: "driver-uid",            // nullable
  driverName: "Ahmed",               // nullable
  statusHistory: [                   // array of StatusTransition
    {
      fromStatus: "placed",
      toStatus: "accepted",
      timestamp: Timestamp,
      actorId: "store-owner-uid",
      location: { latitude: 33.51, longitude: 36.28 },
      note: "Order confirmed"
    }
  ],
  createdAt: Timestamp,
  acceptedAt: Timestamp,             // nullable
  readyAt: Timestamp,                // nullable
  dispatchedAt: Timestamp,           // nullable
  deliveredAt: Timestamp,            // nullable
  rejectionReason: "string",         // nullable
  promoCode: "SUMMER20",            // nullable
  discount: { amountInCents: 600 },  // nullable
  updatedAt: Timestamp
}
```

### Restaurants

```javascript
{
  id: "auto-generated",
  name: "Pizza Palace",
  cuisineType: "Italian",
  isActive: true,
  ownerId: "owner-uid",
  phone: "+963...",
  address: {
    street: "456 Food St",
    district: "Old Town",
    city: "Damascus",
    location: { latitude: 33.5100, longitude: 36.2800 }
  },
  location: { latitude: 33.5100, longitude: 36.2800 },
  imageUrl: "https://...",
  commissionPercent: 15.0,
  createdAt: Timestamp,
  deliveryMode: "hybrid",            // enum: storeOnly|platformOnly|hybrid
  allowPlatformFallback: true,
  fallbackDelaySeconds: 300
}
```

### Drivers

```javascript
{
  id: "firebase-auth-uid",
  name: "Ahmed Driver",
  email: "ahmed@example.com",
  phone: "+963...",
  vehicle: "Motorcycle",
  driverType: "platform",            // enum: platform|store
  storeId: null,                     // nullable, for store drivers
  isOnline: true,
  isActive: true,
  currentLocation: {
    latitude: 33.5150,
    longitude: 36.2750
  },
  rating: 4.8,
  activeDeliveries: 2,
  createdAt: Timestamp
}
```

### Dispatch Requests

```javascript
{
  id: "auto-generated",
  orderId: "order-doc-id",
  brandId: "brand-doc-id",
  branchId: "branch-doc-id",
  pickupLocation: { latitude: 33.5100, longitude: 36.2800 },
  dropoffLocation: { latitude: 33.5200, longitude: 36.2700 },
  assignedDriverId: "driver-uid",    // nullable
  status: "assigned",                // enum: pending|scoring|assigned|accepted|unassigned|overloaded|fallback_waiting
  candidateScores: [                 // array of DriverScore
    {
      driverId: "driver-uid",
      driverName: "Ahmed",
      driverType: "platform",
      etaMinutes: 5.2,
      distanceKm: 1.3,
      rating: 4.8,
      activeDeliveries: 1,
      score: 0.85
    }
  ],
  deliveryMode: "hybrid"
}
```

### Dispatch Zones

```javascript
{
  id: "auto-generated",
  branchId: "branch-doc-id",
  name: "Central Damascus",
  centerLat: 33.5138,
  centerLon: 36.2765,
  radiusKm: 5.0,
  minimumOrder: { amountInCents: 500 },
  deliveryFee: { amountInCents: 150 },
  estimatedMinutes: 30,
  isActive: true
}
```

### Brands

```javascript
{
  id: "auto-generated",
  name: "Pizza Palace",
  description: "Best pizza in Damascus",
  logoUrl: "https://...",
  coverImageUrl: "https://...",
  cuisineTypes: ["Italian", "Pizza"],
  website: "https://...",
  contactEmail: "info@pizzapalace.com",
  contactPhone: "+963...",
  isActive: true
}
```

### Branches

```javascript
{
  id: "auto-generated",
  brandId: "brand-doc-id",
  name: "Downtown Branch",
  slug: "downtown",
  address: { /* Address value object */ },
  location: { latitude: 33.5138, longitude: 36.2765 },
  geohash: "s3k2h0",                // for proximity queries
  phone: "+963...",
  imageUrl: "https://...",
  isActive: true,
  operatingHours: [
    { dayOfWeek: 1, openMinutes: 480, closeMinutes: 1320, isClosed: false },
    { dayOfWeek: 2, openMinutes: 480, closeMinutes: 1320, isClosed: false }
  ],
  timezone: "Asia/Damascus"
}
```

### Menu Items

```javascript
{
  id: "auto-generated",
  brandId: "brand-doc-id",
  branchId: "branch-doc-id",
  sharedItemId: null,                 // for shared menus
  name: "Margherita Pizza",
  description: "Classic tomato and mozzarella",
  price: { amountInCents: 1500 },
  originalPrice: null,                // nullable, for discounts
  category: "Pizza",
  tags: ["vegetarian", "popular"],
  modifierGroups: [
    {
      id: "mod-group-1",
      name: "Size",
      isRequired: true,
      minSelections: 1,
      maxSelections: 1,
      modifiers: [
        { id: "mod-1", name: "Small", extraPrice: { amountInCents: 0 }, isDefault: true },
        { id: "mod-2", name: "Large", extraPrice: { amountInCents: 500 }, isDefault: false }
      ]
    }
  ],
  isAvailable: true,
  isSignature: false,
  imageUrl: "https://...",
  sortOrder: 1
}
```

### Promotions

```javascript
{
  id: "auto-generated",
  name: "Summer Special",
  description: "20% off all orders",
  discountPercent: 20.0,
  maxDiscount: { amountInCents: 500 },  // nullable
  minOrder: { amountInCents: 1000 },    // nullable
  isActive: true,
  usageLimit: 1000,
  usedCount: 156,
  startDate: Timestamp,                  // nullable
  endDate: Timestamp                     // nullable
}
```

### Payouts

```javascript
{
  id: "auto-generated",
  restaurantId: "restaurant-doc-id",
  restaurantName: "Pizza Palace",
  grossAmount: { amountInCents: 50000 },
  commissionAmount: { amountInCents: 7500 },
  netAmount: { amountInCents: 42500 },
  status: "paid",                        // enum: pending|processing|paid|failed
  periodStart: Timestamp,
  periodEnd: Timestamp,
  notes: null,
  paidAt: Timestamp
}
```

---

## 3. Security Rules Summary

### Helper Functions

```javascript
// Authentication
function isAuthenticated() {
  return request.auth != null;
}

// Role checks
function hasRole(role) {
  return isAuthenticated() &&
    get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role == role;
}

function isAdmin() {
  return hasRole('superAdmin');
}

function isOwner(uid) {
  return isAuthenticated() && request.auth.uid == uid;
}

function isRestaurantOwner(restaurantId) {
  return isAuthenticated() &&
    get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.restaurantId == restaurantId;
}

function isDriver() {
  return hasRole('driver');
}

function isCashier(restaurantId) {
  return isAuthenticated() &&
    get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role == 'cashier' &&
    get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.restaurantId == restaurantId;
}

function isCustomer() {
  return hasRole('customer');
}
```

### Collection Rules

| Collection | Read | Write | Notes |
|---|---|---|---|
| `Users` | `isOwner(uid)` or `isAdmin()` | `isOwner(uid)` or `isAdmin()` | Users can read/write own doc |
| `Users/{uid}/saved_addresses` | `isOwner(uid)` | `isOwner(uid)` | Subcollection of own addresses |
| `Users/{uid}/loyalty_transactions` | `isOwner(uid)` | `isAdmin()` | Read-only for users |
| `Restaurants` | Public read | `isRestaurantOwner(id)` or `isAdmin()` | Public listing, owner/admin write |
| `Restaurants/{id}/menu_items` | Public read | `isRestaurantOwner(id)` or `isAdmin()` | Public menu, owner/admin edit |
| `Restaurants/{id}/reviews` | Public read | `isCustomer()` | Public reviews, customers write |
| `Orders` | `isOwner(customerId)` or `isOwner(driverId)` or `isAdmin()` | Based on status transition rules | Role-based write |
| `dispatch_requests` | `isAdmin()` or `isDriver()` | `isAdmin()` | Drivers read assigned, admin manage |
| `dispatch_zones` | `isRestaurantOwner(brandId)` or `isAdmin()` | `isAdmin()` | Admin configures zones |
| `brands` | Public read | `isAdmin()` or brand owner | Public listing |
| `branches` | Public read | `isAdmin()` or brand owner | Public listing |
| `menu_items` | Public read | `isAdmin()` or restaurant owner | Public menu |
| `promotions` | Public read (active only) | `isAdmin()` | Admin manages promos |
| `payouts` | `isOwner(restaurantId)` or `isAdmin()` | `isAdmin()` | Owner reads, admin writes |
| `transactions` | `isOwner(userId)` or `isAdmin()` | System only | Payment records |
| `notifications` | `isOwner(userId)` | System only | Push notification logs |
| `activity_log` | `isAdmin()` | System only | Audit trail |
| `driver_wallets` | `isOwner(driverId)` or `isAdmin()` | System only | Wallet balances |
| `driver_locations` | `isAdmin()` | `isDriver()` (own location) | GPS pings |
| `anything_requests` | `isOwner(customerId)` or `isAdmin()` | `isCustomer()` or `isAdmin()` | Custom requests |
| `settings` | `isAdmin()` | `isAdmin()` | Platform config |

### Write Validation

| Rule | Enforcement |
|---|---|
| Status transitions | Must follow valid paths in `OrderStateMachine` |
| Commission calculation | Must match `CommissionCalculator` output |
| Payment amounts | Must match order total |
| Role changes | Only admins can change roles |
| Driver assignment | Only system (Cloud Functions) can assign |

---

## 4. Cloud Functions List

### Node.js Functions (`functions/`)

| Function | Trigger | Purpose |
|---|---|---|
| `setUserRole` | Callable | Set custom claims on Firebase Auth token |
| `checkDispatchTimeouts` | Scheduled | Re-dispatch if driver doesn't accept in time |
| `onSOSEmergency` | Callable | Handle driver emergency alerts |
| `validateOrderPricing` | Callable | Verify order totals before payment |
| `validatePromo` | Callable | Check promo code validity |
| `processDriverPayout` | Callable | Initiate driver payment |
| `batchDriverPayouts` | Scheduled | Process multiple driver payouts |

### TypeScript Functions (`cloud_functions/`)

| Function | Trigger | Purpose |
|---|---|---|
| `createStripePaymentIntent` | Callable | Initialize Stripe payment |
| `createWalletTopUpIntent` | Callable | Initialize wallet top-up |
| `onOrderCreated` | Firestore write | Send notification to store |
| `onOrderStatusChanged` | Firestore write | Send status update notifications |
| `onDispatchAssigned` | Firestore write | Notify assigned driver |
| `onOrderDelivered` | Firestore write | Trigger payment settlement + loyalty points |
| `onUserCreated` | Auth create | Initialize user document |
| `cleanupExpiredPromos` | Scheduled | Deactivate expired promotions |
| `generatePayoutReport` | Callable | Generate partner payout reports |

### Function Dependencies

```
Customer App ──► createStripePaymentIntent
             ──► validatePromo
             ──► validateOrderPricing

Partner App  ──► onOrderCreated (triggered by Firestore write)

Driver App   ──► processDriverPayout
             ──► onSOSEmergency

Admin App    ──► setUserRole
             ──► batchDriverPayouts
             ──► generatePayoutReport

System       ──► checkDispatchTimeouts (scheduled)
             ──► cleanupExpiredPromos (scheduled)
```

---

## 5. API Endpoints (Callable Functions)

### Authentication

| Function | Method | Input | Output |
|---|---|---|---|
| `setUserRole` | POST | `{ uid, role, restaurantId? }` | `{ success, message }` |

### Payments

| Function | Method | Input | Output |
|---|---|---|---|
| `createStripePaymentIntent` | POST | `{ orderId, amount, currency }` | `{ clientSecret, paymentIntentId }` |
| `createWalletTopUpIntent` | POST | `{ userId, amount }` | `{ clientSecret, topUpId }` |
| `processDriverPayout` | POST | `{ driverId, amount }` | `{ success, payoutId }` |

### Orders

| Function | Method | Input | Output |
|---|---|---|---|
| `validateOrderPricing` | POST | `{ orderId, expectedTotal }` | `{ valid, actualTotal, difference }` |
| `validatePromo` | POST | `{ code, userId, orderTotal }` | `{ valid, discount, discountType, message }` |

### Safety

| Function | Method | Input | Output |
|---|---|---|---|
| `onSOSEmergency` | POST | `{ driverId, location, orderId? }` | `{ success, alertId }` |

### Admin

| Function | Method | Input | Output |
|---|---|---|---|
| `batchDriverPayouts` | POST | `{ driverIds?, periodStart, periodEnd }` | `{ processed, failed, report }` |
| `generatePayoutReport` | POST | `{ restaurantId, periodStart, periodEnd }` | `{ reportUrl, summary }` |

---

## 6. Environment Variables

### Firebase Configuration

| Variable | Description | Example |
|---|---|---|
| `FIREBASE_PROJECT_ID` | Firebase project ID | `tayyebgo` |
| `FIREBASE_API_KEY` | Web API key | `AIzaSy...` |
| `FIREBASE_AUTH_DOMAIN` | Auth domain | `tayyebgo.firebaseapp.com` |
| `FIREBASE_STORAGE_BUCKET` | Storage bucket | `tayyebgo.appspot.com` |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID | `123456789` |
| `FIREBASE_APP_ID` | App ID | `1:123456789:web:abc123` |

### Stripe

| Variable | Description | Example |
|---|---|---|
| `STRIPE_SECRET_KEY` | Server secret key | `sk_test_...` |
| `STRIPE_PUBLISHABLE_KEY` | Client publishable key | `pk_test_...` |
| `STRIPE_WEBHOOK_SECRET` | Webhook signing secret | `whsec_...` |

### ShamCash

| Variable | Description | Example |
|---|---|---|
| `SHAMCASH_API_URL` | API base URL | `https://shamcash.example.com/api` |
| `SHAMCASH_API_KEY` | API authentication key | `your-key` |
| `SHAMCASH_MERCHANT_ID` | Merchant identifier | `merchant-123` |

### Feature Flags

| Variable | Description | Default |
|---|---|---|
| `ENABLE_STRIPE` | Enable Stripe payments | `false` |
| `ENABLE_SHAMCASH` | Enable ShamCash payments | `true` |
| `ENABLE_DISPATCH_TIMEOUT` | Enable auto re-dispatch | `true` |
| `ENABLE_PROMO_ABUSE_DETECTION` | Enable fraud detection | `true` |
| `ENABLE_LOYALTY` | Enable loyalty program | `true` |
| `MAINTENANCE_MODE` | Platform maintenance flag | `false` |

### Cloud Functions Config

| Variable | Description | Default |
|---|---|---|
| `DISPATCH_TIMEOUT_SECONDS` | Driver accept timeout | `30` |
| `MAX_CONCURRENT_DELIVERIES` | Max orders per driver | `4` |
| `FALLBACK_DELAY_SECONDS` | Store-to-platform fallback delay | `300` |
| `PAYOUT_MINIMUM` | Minimum payout amount (cents) | `5000` |
| `LOYALTY_POINTS_PER_DOLLAR` | Base earning rate | `1` |
| `TAX_RATE` | Default tax rate (percent) | `10` |

---

## 7. Firestore Indexes

### Composite Indexes

| Collection | Fields | Purpose |
|---|---|---|
| `Orders` | `customerId` + `createdAt` (desc) | Customer order history |
| `Orders` | `restaurantId` + `status` + `createdAt` (desc) | Store order feed |
| `Orders` | `driverId` + `status` | Driver active orders |
| `Orders` | `status` + `createdAt` | Admin order queries |
| `dispatch_requests` | `assignedDriverId` + `status` | Driver dispatch offers |
| `dispatch_requests` | `orderId` | Order dispatch lookup |
| `driver_locations` | `isOnline` + `currentLocation` | Nearby driver queries |
| `menu_items` | `brandId` + `category` + `sortOrder` | Menu browsing |
| `menu_items` | `branchId` + `isAvailable` | Branch menu availability |
| `promotions` | `isActive` + `endDate` | Active promo queries |
| `payouts` | `restaurantId` + `status` | Partner payout history |
| `activity_log` | `actorId` + `timestamp` (desc) | User activity audit |

### Single Field Indexes (Excluded)

| Collection | Field | Reason |
|---|---|---|
| `Users` | `email` | Auto-indexed for auth |
| `Users` | `role` | Filtered frequently |
| `Orders` | `status` | Filtered frequently |
| `driver_locations` | `geohash` | Proximity queries |

---

## 8. Storage Rules

### Buckets

| Bucket | Purpose | Access |
|---|---|---|
| `profile-images/` | User profile photos | Public read, owner write |
| `store-images/` | Restaurant/store photos | Public read, owner/admin write |
| `menu-images/` | Menu item photos | Public read, owner/admin write |
| `brand-logos/` | Brand logo images | Public read, admin write |
| `brand-covers/` | Brand cover images | Public read, admin write |
| `driver-documents/` | Driver license/insurance | Owner read, admin read/write |
| `partner-documents/` | Partner business docs | Owner read, admin read/write |
| `exports/` | Generated reports | Admin read, system write |

### Rules

```javascript
// Profile images - owner can write, public read
match /profile-images/{userId}/{fileName} {
  allow read: if true;
  allow write: if isAuthenticated() && request.auth.uid == userId;
}

// Store images - owner/admin can write, public read
match /store-images/{restaurantId}/{fileName} {
  allow read: if true;
  allow write: if isAuthenticated() && (
    isRestaurantOwner(restaurantId) || isAdmin()
  );
}

// Menu images - owner/admin can write, public read
match /menu-images/{restaurantId}/{fileName} {
  allow read: if true;
  allow write: if isAuthenticated() && (
    isRestaurantOwner(restaurantId) || isAdmin()
  );
}
```

---

## 9. Realtime Listeners

### Active Listeners

| App | Collection | Filter | Purpose |
|---|---|---|---|
| Customer | `Orders` | `customerId == uid` | Order status tracking |
| Customer | `driver_locations` | `assignedDriverId == uid` | Live driver map |
| Driver | `dispatch_requests` | `assignedDriverId == uid && status == 'assigned'` | Incoming dispatch offers |
| Driver | `Orders` | `driverId == uid && status IN ['dispatched','pickedUp']` | Active delivery |
| Partner | `Orders` | `restaurantId == rid && status IN ['placed','accepted']` | Incoming orders |
| Admin | `Orders` | `status IN ['placed','dispatched']` | Platform overview |

### Listener Optimization

- **Snapshot listeners** use `snapshots()` for real-time updates
- **Query limits** applied to prevent excessive reads
- **Offline persistence** enabled for mobile clients
- **Delta sync** — only changed documents are transmitted
- **Listener cleanup** — all listeners disposed on screen exit

---

## 10. Data Export Format

### CSV Export (Admin)

| Report | Fields |
|---|---|
| Orders | ID, Date, Customer, Store, Status, Total, Payment Method |
| Revenue | Date, Gross, Commission, Net, Store Count |
| Drivers | ID, Name, Rating, Deliveries, Earnings |
| Partners | ID, Name, Orders, Revenue, Commission Rate |

### PDF Export (Admin)

- Formatted reports with charts
- Store-specific revenue breakdowns
- Driver performance summaries
- Monthly platform reports
