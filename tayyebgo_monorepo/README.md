<div align="center">

<!-- Logo placeholder -->
<!-- ![TayyebGo Logo](docs/brand/logo.png) -->

# TayyebGo

**Everything Delivered**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-orange?logo=firebase)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## Overview

TayyebGo is a full-stack, multi-vertical delivery platform built as a Flutter monorepo. It powers ordering, dispatch, driver management, restaurant partnerships, and admin operations — all backed by Firebase and Stripe.

## Architecture

```
tayyebgo_monorepo/
├── apps/                          # Flutter applications
│   ├── tayyebgo_customer/         # Customer ordering app
│   ├── tayyebgo_driver/           # Driver delivery app
│   ├── tayyebgo_partner/          # Restaurant partner app
│   ├── tayyebgo_admin/            # Super admin web panel
│   └── tayyebgo_portal/           # Unified login & role routing
├── packages/                      # Shared Dart packages
│   ├── tayyebgo_core/             # Business logic, models, services, providers
│   └── tayyebgo_multi_tenant/     # Multi-tenant vertical management
├── functions/                     # Firebase Cloud Functions (Node.js)
├── scripts/                       # DevOps & seed scripts
├── docs/                          # Architecture docs, audits, setup guides
├── website/                       # Marketing landing page
├── firebase.json                  # Firebase project config
├── firestore.rules                # Firestore security rules
└── storage.rules                  # Firebase Storage security rules
```

### Clean Architecture (Core Package)

The shared `tayyebgo_core` package follows Clean Architecture:

- **`domain/`** — Entities, enums, value objects, repository interfaces
- **`infrastructure/`** — Firebase implementations, concrete repositories
- **`src/`** — Models, providers (state), dependency injection, shared widgets
- **`presentation/`** — Theme, router (GoRouter)
- **`ui/`** — Design system components (buttons, cards, loaders)

## Apps

| App | Description | Platform |
|-----|-------------|----------|
| **tayyebgo_customer** | Customer-facing ordering, cart, and live tracking | Mobile & Web |
| **tayyebgo_driver** | Driver app with live maps, order acceptance, and delivery management | Mobile & Web |
| **tayyebgo_partner** | Restaurant partner app for menu management, order dispatch, and analytics | Mobile & Web |
| **tayyebgo_admin** | Super admin dashboard for commissions, user management, and platform analytics | Web |
| **tayyebgo_portal** | Unified login portal with role-based dashboard routing | Web |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x, Dart 3.11+, Provider, GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, Cloud Functions, Cloud Messaging) |
| Payments | Stripe + ShamCash (local wallet fallback) |
| Maps | FlutterMap + latlong2, Geolocator |
| State | Provider (ChangeNotifier) |
| CI/CD | GitHub Actions |
| Hosting | Firebase Hosting |

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.41.7+ | App development |
| Dart SDK | 3.11.5+ | Core language |
| Node.js | 20+ | Cloud Functions |
| Firebase CLI | Latest | Deployment & emulator |
| Git | 2.30+ | Version control |
| Android Studio / Xcode | Latest | Mobile emulators |

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/your-org/tayyebgo.git
cd tayyebgo
```

### 2. Install Flutter dependencies

```bash
# Core packages first
cd packages/tayyebgo_core && flutter pub get && cd ../..
cd packages/tayyebgo_multi_tenant && flutter pub get && cd ../..

# Apps
for app in tayyebgo_customer tayyebgo_driver tayyebgo_partner tayyebgo_admin tayyebgo_portal; do
  cd apps/$app && flutter pub get && cd ../..
done
```

### 3. Install Cloud Functions dependencies

```bash
cd functions && npm ci && cd ..
```

### 4. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable: Authentication (Email/Password + Google Sign-In), Cloud Firestore, Firebase Storage, Firebase Hosting, Cloud Functions, Cloud Messaging
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) into respective app directories
4. Initialize:

```bash
firebase use --add <your-project-id>
```

### 5. Set environment variables

Create a `.env` file in the project root:

```
# Firebase
FIREBASE_PROJECT_ID=tayyebgo
FIREBASE_API_KEY=your-api-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# ShamCash (optional)
SHAMCASH_API_URL=https://shamcash.example.com/api
SHAMCASH_API_KEY=your-key

# Feature flags
ENABLE_STRIPE=false
ENABLE_SHAMCASH=true
```

> **Note:** Never commit `.env` to version control.

## Running Locally

### Flutter apps

```bash
cd apps/tayyebgo_customer
flutter run -d chrome      # Web
flutter run -d emulator    # Android/iOS emulator
```

Repeat for `tayyebgo_driver`, `tayyebgo_partner`, `tayyebgo_admin`, and `tayyebgo_portal`.

### Cloud Functions (emulator)

```bash
cd functions && npm run build && cd ..
firebase emulators:start
```

## Testing

```bash
# Core package tests (214+ tests)
cd packages/tayyebgo_core && flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/infrastructure/services/order_state_machine_test.dart

# App tests
cd apps/tayyebgo_customer && flutter test
```

## Deployment

### Firebase Hosting

```bash
# Build
cd apps/tayyebgo_customer && flutter build web --release && cd ../..

# Deploy hosting
firebase deploy --only hosting
```

### Cloud Functions

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

### CI/CD

Pushing to `main` triggers GitHub Actions which:
1. Analyzes code across all apps
2. Runs unit tests with coverage
3. Builds web versions
4. Deploys to Firebase Hosting
5. Rolls back on failure

### Quick deploy (PowerShell)

```bash
./scripts/deploy.ps1
```

## Project Structure Highlights

- **Order State Machine** — Finite state transitions: `placed → accepted → preparing → ready → readyForDriver → dispatched → pickedUp → delivered`
- **Auto-Dispatch** — 4-factor weighted scoring (ETA, rating, load, distance) for driver assignment
- **Payment Abstraction** — `PaymentOrchestrator` routes to Cash, ShamCash, or Stripe providers
- **Multi-Tenancy** — `tayyebgo_multi_tenant` package supports multiple verticals and service areas
- **Firestore Security Rules** — Role-based access with 30+ collection rules and abuse prevention

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Guidelines

- Follow the existing code style and architecture patterns
- Write tests for new business logic in `packages/tayyebgo_core`
- Run `flutter analyze` before submitting
- Keep PRs focused — one feature or fix per PR
- Update documentation if adding new Firebase collections or Cloud Functions

## Documentation

Detailed docs live in the `docs/` directory:

- [Architecture](docs/ARCHITECTURE.md) — System design and key decisions
- [Setup Guide](docs/SETUP.md) — Developer onboarding
- [Business Logic](docs/BUSINESS_LOGIC.md) — Domain rules and state machines
- [Design System](docs/DESIGN_SYSTEM.md) — UI tokens and component library
- [Roles & Permissions](docs/roles-permissions.md) — Access control matrix
- [Domain Model](docs/domain-model.md) — Entity relationships
- [Testing](docs/TESTING.md) — Test strategy and patterns

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with care by the TayyebGo team

</div>
