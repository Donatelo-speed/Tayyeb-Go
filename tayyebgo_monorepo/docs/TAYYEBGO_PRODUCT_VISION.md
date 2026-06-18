# TayyebGo — Product Vision

## Mission Statement

TayyebGo is a hyper-local delivery platform built for Syria and the MENA region. We connect customers with local restaurants, pharmacies, grocery stores, and parcel services through a suite of purpose-built apps — making reliable delivery accessible in markets where existing solutions fall short.

**Our belief:** Every city deserves a delivery platform that works for its people, its payment methods, and its infrastructure realities.

---

## Target Market

### Primary: Syria

- **Population:** ~22 million
- **Urban density:** Damascus, Aleppo, Homs, Latakia, Hama — concentrated demand
- **Pain points:** Limited access to global platforms (Uber Eats, Talabat absent), fragmented local delivery, cash-dominant economy, unreliable internet
- **Opportunity:** First-mover advantage in a digitally underserved market with growing smartphone penetration

### Secondary: MENA Expansion

- **Phase 2:** Iraq, Jordan, Lebanon
- **Phase 3:** Egypt, Tunisia, Morocco
- **Phase 4:** Gulf markets (Saudi, UAE, Kuwait) — higher ticket sizes, different competitive landscape

### Market Characteristics

| Factor | Syria | MENA Average |
|---|---|---|
| Smartphone penetration | ~65% | ~75% |
| Cash on delivery | ~90% | ~60% |
| Internet reliability | Variable | Moderate |
| Existing delivery platforms | Minimal | Moderate |
| Average order value | Low-medium | Medium-high |

---

## Platform Overview

### 6 Products, 1 Ecosystem

```
┌─────────────────────────────────────────────────────────┐
│                    TayyebGo Platform                     │
├──────────┬──────────┬──────────┬──────────┬──────┬──────┤
│ Customer │  Driver  │ Partner  │  Admin   │Web   │Portal│
│   App    │   App    │   App    │   App    │Site  │      │
├──────────┴──────────┴──────────┴──────────┴──────┴──────┤
│                    tayyebgo_core                         │
│          (Shared business logic, design system,          │
│           models, services, repositories)                │
├─────────────────────────────────────────────────────────┤
│                 Firebase Backend                         │
│    Auth · Firestore · Functions · Storage · FCM          │
└─────────────────────────────────────────────────────────┘
```

### 1. Customer App (`tayyebgo_customer`)

**Purpose:** End-to-end ordering experience for consumers.

**Key features:**
- Browse stores by cuisine, category, or proximity
- Full menu with modifiers, combos, and options
- Real-time order tracking with live driver map
- Cash on Delivery, ShamCash wallet, Stripe card payments
- Promo codes and loyalty points
- Order history and reorder
- Multi-address management
- Scheduled orders
- Ratings and reviews
- "Anything" requests (custom delivery tasks)

**Platforms:** Android, iOS, Flutter Web

---

### 2. Driver App (`tayyebgo_driver`)

**Purpose:** Delivery execution and driver operations.

**Key features:**
- Online/offline availability toggle
- Real-time dispatch offers with accept/reject
- Turn-by-turn navigation to pickup and dropoff
- Order status updates (picked up → delivering → delivered)
- Live GPS tracking (sent to customer and platform)
- Earnings dashboard and wallet
- Payout history
- SOS emergency button
- Multi-delivery batching (up to 4 concurrent)
- Offline mode with sync queue

**Platforms:** Android, iOS, Flutter Web

---

### 3. Partner App (`tayyebgo_partner`)

**Purpose:** Restaurant/store operations and order management.

**Key features:**
- Real-time incoming order feed
- Accept/reject orders with reason codes
- Menu management (items, modifiers, categories, availability)
- Store profile editing (hours, photos, description)
- Operating hours per day-of-week
- Multi-brand and multi-branch support
- Cashier staff management
- Order ready notification
- Sales analytics and revenue reports
- Payout tracking
- Subscription plan management
- Delivery mode configuration (store-only, platform, hybrid)

**Platforms:** Android, iOS, Flutter Web

---

### 4. Admin App (`tayyebgo_admin`)

**Purpose:** Platform administration and oversight.

**Key features:**
- User management (activate/deactivate, role assignment)
- Store and driver verification/approval
- Order override and dispute resolution
- Platform-wide analytics and KPIs
- Promotion management (create, schedule, retire)
- Commission rate configuration
- Driver payout processing
- Audit log viewer
- Platform settings and feature flags
- Maintenance mode toggle
- Data export (CSV/PDF)

**Platforms:** Flutter Web (primary)

---

### 5. Website (`tayyebgo_web`)

**Purpose:** Public-facing marketing site and customer web ordering.

**Key features:**
- Landing page with value proposition
- Store discovery and menu browsing
- Web-based ordering (responsive Flutter Web)
- SEO-optimized store pages
- Blog and help center
- Careers and partner sign-up

**Platform:** Firebase Hosting (Flutter Web)

---

### 6. Partner Portal (`tayyebgo_portal`)

**Purpose:** Self-service onboarding and management for restaurant partners.

**Key features:**
- Partner registration and document upload
- Store verification workflow
- Subscription plan selection and payment
- Menu import/management
- Analytics dashboard
- Payout configuration
- Support ticket system

**Platform:** Flutter Web

---

## Competitive Landscape

### vs. Talabat

| Factor | TayyebGo | Talabat |
|---|---|---|
| MENA presence | Syria-first | Gulf-focused |
| Cash on delivery | Native, optimized | Supported but secondary |
| Offline support | Full offline queue | Online-only |
| Driver scoring | 4-factor weighted algo | Basic proximity |
| Multi-vertical | Food, grocery, pharmacy, parcel | Food-primary |
| Partner tools | Full self-service portal | Limited |
| Subscription model | 3-tier partner plans | Commission-only |

### vs. Uber Eats

| Factor | TayyebGo | Uber Eats |
|---|---|---|
| Market focus | Syria, underserved MENA | Global, established markets |
| Payment methods | ShamCash + COD + Stripe | Card-primary |
| Driver flexibility | Platform + store drivers | Platform only |
| Commission rates | 5-15% (tiered) | 15-30% |
| Offline capability | Native offline queue | Online-only |
| Local partnerships | Deep local integration | Standardized |

### vs. Local Competitors

| Factor | TayyebGo | Local Apps |
|---|---|---|
| Tech stack | Modern Flutter + Firebase | Legacy or basic |
| Design quality | Consistent design system | Inconsistent |
| Multi-vertical | Unified platform | Single-vertical |
| Analytics | Real-time dashboards | Basic or none |
| Scalability | Cloud-native serverless | Monolith |
| Driver tools | Full feature set | Minimal |

### Key Differentiators

1. **Offline-first architecture** — Works on unreliable networks with automatic sync
2. **Multi-vertical platform** — Food, grocery, pharmacy, parcel in one app
3. **Flexible driver model** — Platform and store-affiliated drivers coexist
4. **Fair commission structure** — 5-15% tiered by subscription level
5. **Cash-native payments** — Built for COD-dominant markets
6. **Hyper-local focus** — Built for Syria's specific infrastructure realities
7. **Self-service partner tools** — Full portal for onboarding and management
8. **AI-powered dispatch** — 4-factor weighted scoring algorithm

---

## Revenue Model

### Primary Revenue Streams

| Stream | Description | Target |
|---|---|---|
| **Delivery fees** | Customer-facing fee per order | $0.50-$3.00 per delivery |
| **Commissions** | Platform fee on order total | 5%-15% by partner tier |
| **Subscriptions** | Partner monthly/quarterly plans | $10-$45 per period |
| **Advertising** | Featured placement, promoted listings | Bidding-based |
| **Anything requests** | Custom delivery premium fee | $2.00-$5.00 premium |

### Commission Tiers

| Partner Tier | Commission Rate | Subscription | Benefits |
|---|---|---|---|
| Standard | 15% | None | Basic platform access |
| Plus | 10% | 25,000/3mo | Priority support, monthly offers |
| Premium | 5% | 45,000/6mo | Exclusive deals, early access, lowest commission |

### Subscription Plans

| Plan | Duration | Price | Discount | Commission |
|---|---|---|---|---|
| Basic | 1 month | 10,000 | 5% | 15% |
| Plus | 3 months | 25,000 | 10% | 10% |
| Premium | 6 months | 45,000 | 15% | 5% |

### Projected Unit Economics (per order)

| Metric | Value |
|---|---|
| Average order value | $12.00 |
| Average delivery fee | $1.50 |
| Average commission (12%) | $1.44 |
| Platform revenue per order | $2.94 |
| Driver payout | $1.00-$2.00 |
| Net platform margin | ~$0.94-$1.94 |

### Future Revenue Streams

- **Marketplace fees** — Multi-vertical expansion (pharmacy, grocery, parcel)
- **SaaS tools** — Analytics, marketing, and operations tools for partners
- **White-label licensing** — TayyebGo platform for other MENA markets
- **Financial services** — Driver advances, partner working capital
- **Data insights** — Anonymized market intelligence for partners

---

## Future Roadmap

### Phase 1: Foundation (Current - Q1 2026)

- [x] Core platform (Customer, Driver, Partner, Admin apps)
- [x] Design system and component library
- [x] Firebase backend with security rules
- [x] Order lifecycle and dispatch algorithm
- [x] Payment integration (Cash, ShamCash, Stripe)
- [x] Subscription plans for partners
- [x] Offline mode with sync queue
- [ ] Website and Partner Portal
- [ ] Production deployment

### Phase 2: Growth (Q2-Q3 2026)

- [ ] AI-powered menu image processing
- [ ] Smart delivery routing (multi-stop optimization)
- [ ] Demand prediction for partners
- [ ] Customer segmentation and targeted promotions
- [ ] Driver performance analytics
- [ ] Real-time chat (customer-driver, customer-store)
- [ ] Group ordering
- [ ] Reorder suggestions (ML-based)

### Phase 3: Expansion (Q4 2026 - Q1 2027)

- [ ] Multi-vertical expansion (pharmacy, grocery, parcel)
- [ ] Marketplace model (multi-vendor)
- [ ] SaaS analytics dashboard for partners
- [ ] White-label platform licensing
- [ ] Driver advances and financial services
- [ ] Partner working capital loans
- [ ] Loyalty program 2.0 (gamification)

### Phase 4: Scale (Q2-Q4 2027)

- [ ] Cross-border delivery (Syria ↔ Lebanon ↔ Iraq)
- [ ] AI-powered dynamic pricing
- [ ] Autonomous delivery pilots (drone/robot where legal)
- [ ] Full fintech integration (digital wallet, bill payments)
- [ ] Enterprise API for third-party integrations
- [ ] Multi-language support (Arabic, Kurdish, English, French)

---

## Success Metrics

### North Star Metrics

| Metric | Target (Year 1) |
|---|---|
| Monthly Active Users | 50,000 |
| Monthly Orders | 100,000 |
| Partner Stores | 500 |
| Active Drivers | 1,000 |
| Average Order Value | $12+ |
| Customer Retention (30-day) | 40%+ |
| Partner Retention (90-day) | 80%+ |

### Operational Metrics

| Metric | Target |
|---|---|
| Average delivery time | <35 minutes |
| Order accuracy | >98% |
| Customer satisfaction | >4.2/5.0 |
| Driver utilization | >60% |
| Dispatch acceptance rate | >85% |
| Cancellation rate | <5% |

### Business Metrics

| Metric | Target (Year 1) |
|---|---|
| Gross Merchandise Value | $15M |
| Platform Revenue | $1.8M |
| Partner Revenue | $13.2M |
| Take rate (blended) | ~12% |
| Customer Acquisition Cost | <$2.00 |
| Lifetime Value | >$50.00 |

---

## Technology Philosophy

### Build vs. Buy

| Category | Choice | Rationale |
|---|---|---|
| Frontend | Flutter | Single codebase for iOS, Android, Web |
| Backend | Firebase | Serverless, fast iteration, low ops overhead |
| Database | Firestore | Real-time sync, offline support |
| Payments | Stripe + ShamCash | Global + local coverage |
| Analytics | Custom + Firebase | Cost-effective, full control |
| CI/CD | GitHub Actions | Standard, free for public repos |

### Core Principles

1. **Offline-first** — Every feature must work on unreliable networks
2. **Mobile-first** — Primary users are on phones, not desktops
3. **Cash-native** — COD is the default, not a fallback
4. **Low-bandwidth** — Minimize data transfer, compress aggressively
5. **Multi-vertical** — Design for extensibility from day one
6. **Multi-tenant** — Support multiple brands and verticals
7. **Clean architecture** — Domain layer with zero external dependencies
8. **Testable** — 214+ unit tests in core package, target >80% coverage
