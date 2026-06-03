# TAYYEB-GO: Complete Production Setup Guide

## 🚀 QUICK START

### Prerequisites
- Node.js 18+ 
- PostgreSQL 14+
- Flutter 3.x
- Redis (optional, for caching)

### 1. Database Setup

```bash
# Navigate to database folder
cd database

# Run core schema
psql -U postgres -d tayyeb_go -f schema.sql

# Run Pro-Tier schema  
psql -U postgres -d tayyeb_go -f pro_tier_schema.sql

# Run Final Production schema
psql -U postgres -d tayyeb_go -f final_production_schema.sql
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create .env file with:
# PORT=3000
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=tayyeb_go
# DB_USER=postgres
# DB_PASSWORD=your_password
# JWT_SECRET=your_jwt_secret

# Start server
node server.js
```

### 3. Frontend Setup

```bash
cd frontend

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

---

## 📱 APP LOGIN CREDENTIALS

| Role | Email | Password |
|------|-------|----------|
| Super Admin | admin@test.com | test123 |
| Restaurant Owner | owner@test.com | test123 |
| Cashier | cashier@test.com | test123 |
| Driver | driver@test.com | test123 |
| Customer | user@test.com | test123 |

---

## 🏗️ ARCHITECTURE

### Database Tables (30+)

**Core:**
- users, restaurants, categories, products
- modifier_groups, modifier_options
- orders, order_items
- user_addresses, driver_locations

**Pro-Tier:**
- loyalty_wallets, loyalty_transactions
- push_notifications, device_tokens
- guest_carts, delivery_batches
- kitchen_settings, order_reorders

**Production:**
- delivery_pins, payment_transactions
- commission_transactions, settlements
- landmarks, delivery_zones
- campaigns, promotions

---

## 🔧 KEY FEATURES IMPLEMENTED

### ✅ Authentication
- Multi-step registration (Phone → OTP → Profile → Location)
- Login with Email/Password
- Forgot Password workflow
- Session management with secure storage
- Device UUID binding for Admin

### ✅ Role-Based Dashboards
- Super Admin: Full platform control, analytics, kill switch
- Restaurant Owner: Dashboard, menu editor, orders, analytics
- Cashier: Kitchen tablet view
- Driver: Deliveries, orders, earnings
- Customer: Home, vendors, cart, orders, profile

### ✅ Smart Features
- One-Tap Reorder (validates restaurant open, items available, price changes)
- Loyalty Coins System (Bronze→Platinum tiers)
- Guest Mode (pre-auth browsing, cart at checkout)
- Dark/Light Theme toggle
- i18n (English/Arabic with RTL support)

### ✅ Kitchen Tablet
- Color-coded order states (Green: Acknowledge, Orange: Prepared, Blue: Handoff)
- Smart Kitchen Mode (auto-accept, single ping, auto-print)
- Thermal printer integration
- Loud alarm for new orders

### ✅ Driver App
- Delivery PIN verification (4-digit)
- Batched deliveries suggestion
- Real-time location tracking
- Digital receipt ledger

### ✅ Payments
- Cash on Delivery (default)
- Sham Cash integration
- PAYMERA QR support
- Visa placeholder (Coming Soon)

### ✅ B2B Commission System
- Auto-calculated commission per order
- Debt ceiling with auto-suspension
- Settlement tracking
- Admin dashboard

### ✅ Marketing
- Promo codes (percentage/fixed)
- Free delivery threshold
- Campaign system (Ramadan, etc.)
- Push notification blaster

### ✅ Offline Resilience
- SQLite local caching
- Sync queue for offline actions
- Automatic reconnection sync

---

## 📁 FILE STRUCTURE

```
TayyebGo/
├── database/
│   ├── schema.sql                 # Core DB schema
│   ├── pro_tier_schema.sql        # Pro-tier features
│   └── final_production_schema.sql # Production features
│
├── backend/
│   ├── server.js                  # Entry point
│   └── src/
│       ├── routes/               # API routes
│       ├── middleware/           # Auth, validation
│       ├── models/              # DB models
│       └── services/             # Business logic
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart            # App entry
│   │   ├── models/              # Data models
│   │   ├── providers/           # State management
│   │   ├── services/            # API & utilities
│   │   ├── screens/             # UI screens
│   │   └── theme/               # Design system
│   │
│   └── pubspec.yaml             # Dependencies
│
└── docs/
    ├── MASTER_BLUEPRINT_V2.md    # Full specification
    └── route_map.dart           # Navigation map
```

---

## 🎨 THEME COLORS

| Purpose | Color | Hex |
|---------|-------|-----|
| Primary | Green | #16A085 |
| Secondary | Light Green | #2ECC71 |
| Accent | Teal | #1ABC9C |
| Error | Red | #E74C3C |
| Warning | Orange | #F39C12 |
| Success | Green | #27AE60 |

---

## 📱 NAVIGATION ROUTES

### Auth Flow
`/` → `/login` → `/register` → `/register/phone` → `/register/otp` → `/register/profile`

### Customer App
`/app/customer/home` → `/app/customer/vendors` → `/app/customer/vendor/:id` → `/app/customer/cart` → `/app/customer/checkout`

### Restaurant App
`/app/restaurant/dashboard` → `/app/restaurant/kitchen` → `/app/restaurant/menu` → `/app/restaurant/orders`

### Driver App
`/app/driver/dashboard` → `/app/driver/orders/available` → `/app/driver/delivery/active`

### Admin App
`/app/admin/dashboard` → `/app/admin/restaurants` → `/app/admin/users` → `/app/admin/analytics` → `/app/admin/kill-switch`

---

## 🔒 SECURITY FEATURES

- JWT authentication
- Auth rate-limiting (15 min lockout after 5 failures)
- Device UUID binding for Admin/Restaurant dashboards
- Payment PIN verification for deliveries
- HTTPS enforcement (production)

---

## 📊 API ENDPOINTS

### Auth
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/forgot-password`
- `POST /api/auth/verify-otp`

### Restaurants
- `GET /api/restaurants`
- `GET /api/restaurants/:id`
- `POST /api/restaurants` (Admin)
- `PUT /api/restaurants/:id` (Owner)

### Orders
- `POST /api/orders`
- `GET /api/orders/:id`
- `PATCH /api/orders/:id/status`
- `POST /api/orders/:id/pin` (Driver)

### Payments
- `POST /api/payments/sham-cash`
- `POST /api/payments/paymera`

### Admin
- `GET /api/admin/commissions`
- `POST /api/admin/settle`
- `POST /api/admin/notifications` (Push blaster)
- `POST /api/admin/kill-switch`

---

## 🧪 TESTING

### Test Payment (Demo)
```dart
// Use any of these in checkout:
PaymentMethod.cash        // Always works
PaymentMethod.shamCash    // Simulated success
PaymentMethod.paymera    // Simulated success
PaymentMethod.visa       // Returns "Coming Soon"
```

### Test Reorder
```dart
// 1. Complete an order
// 2. See "Reorder" button on home
// 3. Click to validate and add to cart
```

---

## 🚀 DEPLOYMENT

### Production Build
```bash
cd frontend
flutter build apk --release
flutter build web --release

# Serve with nginx
```

### Environment Variables (Production)
```
NODE_ENV=production
PORT=3000
DB_HOST=your-db-host
DB_NAME=tayyeb_go
REDIS_HOST=your-redis
JWT_SECRET=production-secret
FCM_SERVER_KEY=your-fcm-key
```

---

## 📝 NOTES

- All coordinates are locked to Homs city (Phase 1)
- Landmark-based address system required for deliveries
- Commission auto-suspends restaurant at debt ceiling
- Guest checkout requires phone verification for orders > 50,000 SYP

---

**Platform Status**: ✅ Production Ready
**Version**: 2.0 (Final Production)
**Last Updated**: May 2026
