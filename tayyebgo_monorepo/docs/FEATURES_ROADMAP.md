# TayyebGo — Features & Roadmap

## Feature Status Legend

| Status | Meaning |
|---|---|
| ✅ | Completed and shipped |
| 🔄 | In progress / active development |
| 📋 | Planned / specified |
| 💡 | Idea / backlog |
| 🚫 | Blocked / on hold |
| 🗑️ | Deprecated / removed |

---

## 1. Completed Features

### Core Platform

- [x] **Monorepo structure** — 4 apps + core package + cloud functions
- [x] **Clean architecture** — Domain/Infrastructure/Presentation layers
- [x] **Dependency injection** — Service locator pattern in `tayyebgo_core`
- [x] **Repository pattern** — Abstract interfaces with Firestore implementations
- [x] **Result type utility** — Monadic error handling for async operations
- [x] **GoRouter navigation** — Declarative routing with route guards
- [x] **Barrel file exports** — Single import for all shared symbols

### Domain Layer

- [x] **User entity** — Unified identity with role-based access
- [x] **Order entity** — Full order lifecycle with status history
- [x] **Driver entity** — GPS tracking, availability, multi-delivery support
- [x] **Restaurant entity** — Store profile, menu, delivery modes
- [x] **Brand entity** — Multi-branch brand support
- [x] **Branch entity** — Physical location with operating hours
- [x] **Menu item entity** — Items with modifiers, pricing, availability
- [x] **Dispatch request entity** — Driver assignment tracking
- [x] **Dispatch zone entity** — Delivery area configuration
- [x] **Payment method entity** — Saved payment methods
- [x] **Promotion entity** — Discount codes and campaigns
- [x] **Payout entity** — Partner settlement tracking
- [x] **Value objects** — Money, Address, GeoLocation, Geohash, OperatingHours
- [x] **Enums** — OrderStatus, UserRole, DriverType, PaymentMethodType, FulfillmentType

### Business Logic

- [x] **Order state machine** — Validated state transitions with audit trail
- [x] **Auto-dispatch algorithm** — 4-factor weighted scoring (ETA, rating, load, distance)
- [x] **Driver scoring** — Normalized composite scores with clamping
- [x] **Commission calculator** — Tiered commission by partner subscription
- [x] **Revenue service** — Aggregated revenue analytics
- [x] **ETA service** — Distance-based time estimates
- [x] **Driver location service** — Real-time GPS tracking
- [x] **Payment gateway** — Stripe + ShamCash + Cash abstraction
- [x] **Order placement service** — End-to-end order creation
- [x] **Push notification service** — FCM-based multi-role notifications
- [x] **Notification templates** — Role-specific notification messages
- [x] **Menu sync service** — Cross-branch menu synchronization
- [x] **Geolocation service** — Haversine distance, geohash encoding
- [x] **Connectivity service** — Network status monitoring
- [x] **Offline queue** — Pending operations persisted locally
- [x] **Sync engine** — Reconnect sync for offline operations
- [x] **Skill execution engine** — Extensible task execution framework

### Design System

- [x] **Color tokens** — Light/dark theme with context extensions
- [x] **Typography scale** — 12 text styles (headings, body, labels, special)
- [x] **Spacing scale** — 8pt grid (8 values: xxs to xxxl)
- [x] **Border radius tokens** — Scale + semantic aliases
- [x] **Shadow system** — 4 elevation levels
- [x] **Gradient system** — Primary, premium, dark, surface gradients
- [x] **Theme provider** — Dark/light mode with persistence
- [x] **TGB** — Button system (primary, secondary, ghost, destructive, icon, social)
- [x] **TGC** — Card system (surface, elevated, outlined, gradient, KPI)
- [x] **TGBadge** — Status badges (active, inactive, pending, error, count, role, category)
- [x] **TGAvatar** — User avatars with fallback, online dot
- [x] **TGF** — Text field with validation
- [x] **TGChip** — Filter, action, input, and category chips
- [x] **TGSwitch** — Toggle with label/subtitle
- [x] **TGCircularProgress** — Spinner with optional label
- [x] **TGLinearProgress** — Progress bar with value label
- [x] **TGSearchBar** — Search input
- [x] **TGRating / TGRatingBar** — Display and input ratings
- [x] **TGBanner** — Info, success, warning, error banners
- [x] **TGDialog** — Confirmation dialogs
- [x] **TGBottomSheet / TGConfirmSheet** — Bottom sheet modals
- [x] **TGEmptyState** — Empty screen placeholder
- [x] **TGErrorWidget** — Error state with retry
- [x] **AppLoader** — Loading spinner
- [x] **TGS / TGSGroup** — Skeleton loading placeholders
- [x] **TGDivider, TGSpacer, TGText, TGContainer** — Utility components

### Animations

- [x] **HeroSlideRoute / HeroFadeRoute / HeroScaleRoute** — Page transitions
- [x] **AnimatedFadeSlide** — Fade + slide entry
- [x] **AnimatedStagger** — Staggered list entry
- [x] **AnimatedScaleIn** — Scale pop-in
- [x] **AnimatedPulse** — Pulsing opacity
- [x] **ShimmerWrapper** — Shimmer loading effect
- [x] **TGPressScale** — Press feedback
- [x] **PulseAnimation** — Breathing pulse
- [x] **AnimatedCounter** — Number counting

### Customer App

- [x] **Splash screen** — Brand animation on launch
- [x] **Onboarding** — First-time user walkthrough
- [x] **Authentication** — Email/password + Google sign-in
- [x] **Phone verification** — OTP-based phone verification
- [x] **Home screen** — Store discovery with categories
- [x] **Store listing** — Browse stores by cuisine/category
- [x] **Store detail** — Menu, hours, reviews, info
- [x] **Menu browsing** — Items with modifiers, combos
- [x] **Cart** — Add/remove items, quantity adjustment
- [x] **Checkout** — Address selection, payment, promo codes
- [x] **Order placement** — End-to-end order flow
- [x] **Order tracking** — Real-time status + driver map
- [x] **Order history** — Past orders with reorder
- [x] **Profile management** — Name, phone, photo
- [x] **Address management** — Saved addresses with geolocation
- [x] **Payment methods** — Add/remove Stripe cards, ShamCash
- [x] **Notifications** — Push notification center
- [x] **Ratings & reviews** — Rate completed orders
- [x] **Loyalty points** — Earn and redeem points
- [x] **Promo codes** — Apply discounts at checkout
- [x] **Scheduled orders** — Order for future delivery
- [x] **Anything requests** — Custom delivery tasks

### Driver App

- [x] **Online/offline toggle** — Availability management
- [x] **Dispatch offers** — Accept/reject incoming orders
- [x] **Navigation** — Turn-by-turn to pickup/dropoff
- [x] **Order status updates** — Picked up → Delivering → Delivered
- [x] **Live GPS tracking** — Continuous location broadcast
- [x] **Earnings dashboard** — Daily/weekly/monthly earnings
- [x] **Driver wallet** — Balance and transaction history
- [x] **Payout history** — Payment records
- [x] **SOS emergency** — One-tap emergency alert
- [x] **Multi-delivery batching** — Up to 4 concurrent orders
- [x] **Offline mode** — Queue operations for sync

### Partner App

- [x] **Real-time order feed** — Incoming orders with countdown
- [x] **Accept/reject orders** — With reason codes
- [x] **Menu management** — CRUD for items, modifiers, categories
- [x] **Store profile** — Edit name, hours, photos, description
- [x] **Operating hours** — Per-day scheduling
- [x] **Multi-brand support** — Manage multiple brands
- [x] **Multi-branch support** — Multiple locations per brand
- [x] **Staff management** — Add/remove cashiers
- [x] **Order ready notification** — Alert customer when ready
- [x] **Sales analytics** — Revenue, order volume, ratings
- [x] **Payout tracking** — Settlement history
- [x] **Subscription management** — View/change plans
- [x] **Delivery mode config** — Store-only, platform, hybrid

### Admin App

- [x] **User management** — Activate/deactivate, role assignment
- [x] **Store management** — Create, edit, deactivate stores
- [x] **Driver management** — Verify, approve, deactivate
- [x] **Order override** — Force state transitions
- [x] **Dispute resolution** — Cancel, refund, adjust orders
- [x] **Platform analytics** — KPIs, revenue, growth metrics
- [x] **Promotion management** — Create, schedule, retire promos
- [x] **Commission configuration** — Set rates per tier
- [x] **Driver payouts** — Batch processing
- [x] **Audit log** — Activity tracking
- [x] **Platform settings** — Feature flags, maintenance mode
- [x] **Data export** — CSV/PDF reports

### Firebase Backend

- [x] **Firestore security rules** — Role-based access control
- [x] **Firestore indexes** — Composite indexes for queries
- [x] **Cloud Functions (Node.js)** — Notifications, dispatch, Stripe, admin
- [x] **Cloud Functions (TypeScript)** — Extended functions
- [x] **Firebase Auth** — Email/password, Google, phone
- [x] **Firebase Storage** — Image uploads
- [x] **Firebase Cloud Messaging** — Push notifications
- [x] **Firebase Hosting** — Web app deployment
- [x] **CI/CD pipeline** — GitHub Actions (analyze, test, build, deploy)

### Testing

- [x] **214+ unit tests** — Core package test suite
- [x] **Order state machine tests** — All transition paths
- [x] **Driver scorer tests** — Scoring algorithm validation
- [x] **Commission calculator tests** — Tier calculation tests
- [x] **Value object tests** — Money, GeoLocation, Address
- [x] **Repository mock tests** — Abstract interface contracts

---

## 2. In-Progress Features

### 🔄 Website (`tayyebgo_web`)

- [ ] Public landing page
- [ ] Store discovery (SEO-optimized)
- [ ] Web-based ordering (Flutter Web)
- [ ] Blog and help center
- [ ] Partner sign-up page

### 🔄 Partner Portal (`tayyebgo_portal`)

- [ ] Partner registration flow
- [ ] Document upload and verification
- [ ] Subscription plan selection
- [ ] Self-service menu management
- [ ] Analytics dashboard

### 🔄 Multi-Tenant Expansion

- [ ] Tenant entity and management
- [ ] Vertical type support (food, grocery, pharmacy, parcel)
- [ ] Per-tenant commission rates
- [ ] Service area configuration

---

## 3. Planned Features

### Q2 2026: Intelligence

| Feature | Priority | Description |
|---|---|---|
| AI menu image processing | High | Auto-generate menu items from photos |
| Smart delivery routing | High | Multi-stop optimization for drivers |
| Demand prediction | Medium | Forecast order volume for partners |
| Customer segmentation | Medium | Targeted promotions by behavior |
| Driver performance analytics | Medium | Scorecard and coaching insights |
| Reorder suggestions | Low | ML-based order recommendations |

### Q3 2026: Engagement

| Feature | Priority | Description |
|---|---|---|
| Real-time chat | High | Customer-driver and customer-store messaging |
| Group ordering | Medium | Multiple customers, one order |
| Referral program | Medium | Customer and driver referral bonuses |
| Push notification campaigns | Medium | Targeted marketing via FCM |
| In-app wallet | Low | Prepaid balance for faster checkout |
| Order scheduling v2 | Low | Recurring orders (daily/weekly) |

### Q4 2026: Marketplace

| Feature | Priority | Description |
|---|---|---|
| Multi-vertical marketplace | High | Grocery, pharmacy, parcel in one app |
| Marketplace model | High | Multi-vendor within single vertical |
| SaaS analytics dashboard | Medium | Self-serve analytics for partners |
| White-label licensing | Medium | Platform for other MENA markets |
| Driver advances | Low | Pre-payment on expected earnings |
| Partner working capital | Low | Small business loans via partners |

### Q1 2027: Scale

| Feature | Priority | Description |
|---|---|---|
| Cross-border delivery | Medium | Syria ↔ Lebanon ↔ Iraq |
| Dynamic pricing | Medium | AI-powered surge and discount pricing |
| Loyalty program 2.0 | Medium | Gamification, tiers, challenges |
| Enterprise API | Low | Third-party integrations |
| Multi-language | Low | Arabic, Kurdish, English, French |
| Accessibility audit | Medium | WCAG 2.1 AA compliance |

---

## 4. Technical Debt

### High Priority

| Item | Location | Impact |
|---|---|---|
| Barrel file has 162 exports without grouping | `tayyebgo_core.dart` | Developer experience, tree-shaking |
| `src/` directory is a migration zone | `tayyebgo_core/lib/src/` | Mixed legacy and modern code |
| Legacy repositories in `src/repositories/` | `auth_repository.dart`, `user_repository.dart`, `order_repository.dart` | Duplication with infrastructure layer |
| Empty domain events directory | `domain/events/` | Missing event-driven architecture |
| `tayyebgo_payment` and `tayyebgo_payout` are stubs | `packages/` | Not fully implemented |

### Medium Priority

| Item | Location | Impact |
|---|---|---|
| No integration tests | Root | Limited end-to-end validation |
| No golden tests for design system | `presentation/` | UI regression risk |
| No performance benchmarks | Root | No baseline for optimization |
| Inconsistent error handling patterns | Multiple | Some services use Result, others throw |
| Missing input validation on some entities | `domain/entities/` | Potential runtime errors |

### Low Priority

| Item | Location | Impact |
|---|---|---|
| No API documentation generator | Root | Manual doc maintenance |
| No code generation for models | `src/models/` | Manual serialization |
| No localization setup | Root | Single-language currently |
| No accessibility annotations | `ui/` | Limited screen reader support |
| No golden test CI step | `.github/workflows/` | Manual visual regression checks |

---

## 5. Feature Request Backlog

| ID | Feature | Votes | Status |
|---|---|---|---|
| FR-001 | Dark mode | — | ✅ Done |
| FR-002 | Offline mode | — | ✅ Done |
| FR-003 | Multi-language (Arabic) | 12 | 📋 Planned Q1 2027 |
| FR-004 | Live chat | 8 | 📋 Planned Q3 2026 |
| FR-005 | Group ordering | 6 | 📋 Planned Q3 2026 |
| FR-006 | Subscription for customers | 5 | 💡 Backlog |
| FR-007 | Scheduled recurring orders | 4 | 📋 Planned Q3 2026 |
| FR-008 | Driver multi-stop optimization | 9 | 📋 Planned Q2 2026 |
| FR-009 | In-app wallet | 3 | 📋 Planned Q3 2026 |
| FR-010 | Referral program | 7 | 📋 Planned Q3 2026 |
