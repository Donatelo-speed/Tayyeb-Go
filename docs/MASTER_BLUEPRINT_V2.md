# TAYYEB-GO: MASTER DEVELOPMENT BLUEPRINT
## Next-Gen Syrian Food Delivery Ecosystem

---

## VERSION 2.0 - PRO-TIER UPGRADES INCLUDED

---

# TABLE OF CONTENTS

1. [Global App Requirements](#1-global-app-requirements-uiux-settings--design)
2. [Onboarding & Authentication](#2-the-onboarding--authentication-wizard)
3. [The Four Roles](#3-the-four-roles--their-functionality)
4. [Backup Plans & Offline Resilience](#4-backup-plans--offline-resilience-syria-context)
5. [Payments & Integration](#5-payments--integration)
6. [Pro-Tier Upgrades](#6-pro-tier-upgrades--advanced-logic)
7. [Database Schema](#7-database-schema)
8. [Flutter Route Map](#8-flutter-route-map)

---

## 1. GLOBAL APP REQUIREMENTS (UI/UX, SETTINGS, & DESIGN)

### Design Language
- Ultra-modern UI/UX with smooth transitions
- Micro-animations: logo animation on startup, button click animations, page transitions (300ms ease-in-out)
- Dark/Light mode toggle with smooth color palette shift

### Global Navigation
- Persistent Bottom Navigation Bar for customers
- Sidebar navigation for Admin/Restaurant/Driver
- Every button functional with defined state changes

### Universal Settings & Profile Management
- **Profile Screen for ALL 5 account types**
- Edit: Name, Phone, Email, Delivery Addresses (map-based)
- **Language Changer**: Toggle between English (LTR) and Arabic (RTL) - instant translation
- **Log Out Button**: Clears session tokens, returns to Login

### Data Persistence
- Instant save to database
- Cross-device sync capability

---

## 2. THE ONBOARDING & AUTHENTICATION WIZARD

### Splash Screen
- Cool animated logo on startup

### Login Screen
- Email/Phone + Password inputs
- "Forgot Password" (SMS/Email recovery)
- "Sign in with Google" OAuth button

### Sign-Up Flow (Multi-Step)
1. **Step 1**: Phone Number → "Next"
2. **Step 2**: SMS Verification (OTP) → Enter 6-digit code
3. **Step 3**: Profile Setup → Name, Nickname, Email, Password, Location (map picker)

### Guest Mode (Pre-Auth Browsing)
- Browse restaurants without login
- Browse menu, use modifiers, build cart
- **SMS login prompt only at Checkout**

---

## 3. THE FOUR ROLES & THEIR FUNCTIONALITY

### ROLE 1: SUPER ADMIN (God-Mode)
- Add/Edit/Ban restaurants, customers, drivers
- Deep analytics: Sales, income, commissions
- **Live Map**: Real-time delivery tracking
- **Kill Switch**: Emergency system override
- **Push-Notification Blaster**: Marketing tool to send bulk notifications

### ROLE 2: CUSTOMER APP
- Seamless ordering with past orders & live tracking
- **"Free-Will" Customization Engine**:
  - Rich modifier menus for complex items (size, ingredients, sauces)
  - "Custom Request" textbox for special instructions
  - Direct chat thread with restaurant
- **One-Tap Reorder**: Smart reorder from last order
  - Check 1: Restaurant open?
  - Check 2: Items/modifiers still available?
  - Check 3: Price changed? → Alert user of new price
- **Loyalty Points (Digital Wallet)**: "Coins" system - earn % back, spend on checkout

### ROLE 3: RESTAURANT TABLET & ADMIN PANEL

#### Kitchen Tablet (Receiving Orders)
- Large UI showing: Order Price, Items, Customer Phone, Delivery Type
- **Alarm**: Loud beep until "Acknowledge" clicked
- **Smart Kitchen Mode** (Pro-Tier):
  - Toggle for busy hours
  - Auto-accept orders (no endless beeping)
  - Single notification sound
  - Auto-print to thermal printer

#### Restaurant Manager Panel
- **Catalog Wizard**: Easy upload of food images, prices, modifier trees
- **Live Dashboard**: Active orders, drivers on route, pending orders, daily sales
- **Emergency Chat**: Message driver or customer directly

### ROLE 4: DRIVER APP
- Assigned orders with: Pickup Location, Drop-off (Map view), Customer Name, Phone
- Live GPS tracking (updates Customer & Restaurant apps)
- In-app chat/call with customer
- **Batched Deliveries (AI Routing)**: Identify nearby orders from same restaurant → Offer "Batched Route"

---

## 4. BACKUP PLANS & OFFLINE RESILIENCE (SYRIA CONTEXT)

### Offline-First Architecture
- SQLite local caching for: Customer cart, Restaurant menu, Driver routes
- **Fail-Safe Sync**: Queue actions when offline → Auto-sync when connection returns
- **Emergency Ledgers**: Process orders locally if server down → Bulk upload later

---

## 5. PAYMENTS & INTEGRATION

1. **Cash on Delivery (COD)**: Primary default
2. **Syriatel Cash & Sham Cash**: Deep-link integration via `api-syria-sdk`
3. **Credit Card**: UI placeholder (Coming Soon)

---

## 6. PRO-TIER UPGRADES & ADVANCED LOGIC

### Guest Mode (Pre-Auth Browsing)
- Users can open app, browse restaurants, build full cart without login
- SMS login prompt only triggers at Checkout

### UI/UX Smoothness
- Seamless Dark/Light Mode toggle in settings
- 300ms ease-in-out page transitions

### Smart "One-Tap" Reorder
- Display last completed order on Customer Home Screen
- **Logic**:
  1. Is restaurant open?
  2. Are items with same modifiers still on menu?
  3. Has price changed? → Alert user

### Loyalty Points (Digital Wallet)
- "Coins" system: Earn % of order value back
- Tier levels: Bronze (1%), Silver (2%), Gold (3%), Platinum (5%)
- Stored in DB wallet → Apply as discount at checkout

### Push-Notification Engine
- Firebase Cloud Messaging (FCM) integration
- **Super-Admin "Marketing Blaster"** tool
- Send custom text/image notifications to: All users, targeted area, user segments

### Batched Deliveries (AI Routing)
- Driver matching algorithm identifies:
  - Two+ active orders from same restaurant OR nearby
  - Heading to same delivery zone
- Offer driver "Batched Route" → Optimizes fleet efficiency

### Smart Kitchen Mode (Tablet)
- Toggle for busy hours
- When active:
  - Bypasses endless beeping
  - Auto-accepts order
  - Plays single notification sound
  - Triggers thermal printer for physical ticket

---

## 7. DATABASE SCHEMA

### Core Tables
- `users` - All 5 roles
- `restaurants` - Restaurant info, hours, cuisine types
- `categories` - Menu categories per restaurant
- `products` - Items with base price
- `modifier_groups` - Customization groups (sizes, ingredients)
- `modifier_options` - Individual options with price adjustments
- `orders` - Order data with status tracking
- `order_items` - Individual items with selected modifiers
- `user_addresses` - Saved delivery addresses
- `driver_locations` - Real-time GPS tracking
- `payments` - Payment method & status

### Pro-Tier Tables
- `loyalty_wallets` - Coin balance, tier level
- `loyalty_transactions` - Earn/spent history
- `push_notifications` - Marketing campaigns
- `device_tokens` - FCM tokens for notifications
- `guest_carts` - Pre-auth cart storage
- `delivery_batches` - AI routing batches
- `kitchen_settings` - Smart mode & printer config
- `order_reorders` - Reorder tracking & validation
- `theme_settings` - User theme preferences
- `sync_queue` - Offline sync operations
- `system_settings` - Global config (kill switch, etc.)

---

## 8. FLUTTER ROUTE MAP

### Auth Flow
```
/splash → /login → /register → /register/phone → /register/otp → /register/profile
```

### Customer App (Role: customer)
```
/app/customer/home → /app/customer/vendors → /app/customer/vendor/:id
/app/customer/product/:id → /app/customer/cart → /app/customer/checkout
/app/customer/orders → /app/customer/track/:id → /app/customer/profile
/app/customer/addresses → /app/customer/settings → /app/customer/chat/:id
```

### Restaurant App (Role: restaurant_owner, cashier)
```
/app/restaurant/dashboard → /app/restaurant/kitchen → /app/restaurant/kitchen/order/:id
/app/restaurant/menu → /app/restaurant/menu/category → /app/restaurant/menu/product
/app/restaurant/orders → /app/restaurant/analytics → /app/restaurant/staff → /app/restaurant/profile
```

### Driver App (Role: driver)
```
/app/driver/dashboard → /app/driver/orders/available → /app/driver/delivery/active
/app/driver/delivery/history → /app/driver/earnings → /app/driver/profile
/app/driver/settings → /app/driver/navigation/:orderId
```

### Admin App (Role: super_admin)
```
/app/admin/dashboard → /app/admin/users → /app/admin/users/:id
/app/admin/restaurants → /app/admin/restaurants/:id → /app/admin/restaurants/add
/app/admin/drivers → /app/admin/map → /app/admin/commissions
/app/admin/reports → /app/admin/settings → /app/admin/kill-switch → /app/admin/profile
```

---

## DEMO CREDENTIALS

| Role | Email | Password |
|------|-------|----------|
| Super Admin | admin@tayyeb.com | any |
| Restaurant Owner | owner@almandi.com | any |
| Cashier | cashier@almandi.com | any |
| Driver | driver@company.com | any |
| Customer | user@test.com | any |

---

## KEY FILES

### Database
- `database/schema.sql` - Core schema
- `database/pro_tier_schema.sql` - Pro-tier features

### Flutter
- `lib/main.dart` - App entry with routing
- `lib/models/user.dart` - User model with 5 roles
- `lib/providers/auth_provider.dart` - Authentication
- `lib/providers/locale_provider.dart` - i18n
- `lib/providers/theme_provider.dart` - Dark/Light mode
- `lib/providers/loyalty_provider.dart` - Coins system
- `lib/providers/kitchen_settings_provider.dart` - Smart kitchen
- `lib/services/offline_sync_service.dart` - SQLite caching
- `lib/services/reorder_service.dart` - Smart reorder logic
- `lib/services/guest_mode_service.dart` - Pre-auth cart

### Screens
- `screens/splash_screen.dart` - Animated splash
- `screens/login_screen.dart` - Login + demo credentials
- `screens/register_screen.dart` - Multi-step registration
- `screens/admin/admin_dashboard_screen.dart` - Full admin panel
- `screens/restaurant/kitchen_tablet_screen.dart` - Kitchen display
- `screens/profile/universal_profile_screen.dart` - Settings for all roles

---

**Generated**: May 2026
**Platform**: Flutter (iOS/Android/Web) + Node.js Backend + PostgreSQL
**Status**: Production-Ready with Pro-Tier Features