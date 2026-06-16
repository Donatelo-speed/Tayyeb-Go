# Developer Setup Guide

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Flutter SDK | 3.41.7+ | Mobile/web app development |
| Dart SDK | 3.11.5+ | Core language |
| Node.js | 20+ | Cloud Functions |
| npm | 9+ | Package management |
| Firebase CLI | Latest | Deployment & emulator |
| Git | 2.30+ | Version control |
| Android Studio / Xcode | Latest | Emulator (for mobile testing) |

## Clone and Setup

```bash
git clone https://github.com/your-org/tayyebgo.git
cd tayyebgo
```

### Install Flutter dependencies

```bash
# Install dependencies for each app
cd apps/tayyebgo_customer && flutter pub get && cd ../..
cd apps/tayyebgo_driver && flutter pub get && cd ../..
cd apps/tayyebgo_partner && flutter pub get && cd ../..
cd apps/tayyebgo_admin && flutter pub get && cd ../..

# Install dependencies for packages
cd packages/tayyebgo_core && flutter pub get && cd ../..
cd packages/tayyebgo_multi_tenant && flutter pub get && cd ../..
```

### Install Cloud Functions dependencies

```bash
cd cloud_functions/functions
npm ci
cd ../..
```

## Firebase Project Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable these services:
   - Firebase Authentication (Email/Password + Google Sign-In)
   - Cloud Firestore
   - Firebase Storage
   - Firebase Hosting
   - Cloud Functions
   - Firebase Cloud Messaging

3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place in the respective app directories.

4. Initialize Firebase for each app:
   ```bash
   firebase use --add <your-project-id>
   ```

## Environment Variables

Create a `.env` file in the project root (do not commit):

```
# Firebase
FIREBASE_PROJECT_ID=tayyebgo
FIREBASE_API_KEY=your-api-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# ShamCash (optional, for local payment testing)
SHAMCASH_API_URL=https://shamcash.example.com/api
SHAMCASH_API_KEY=your-key

# Feature flags
ENABLE_STRIPE=false
ENABLE_SHAMCASH=true
```

## Running Locally

### Flutter Web Apps

```bash
# Customer app
cd apps/tayyebgo_customer
flutter run -d chrome

# Driver app
cd apps/tayyebgo_driver
flutter run -d chrome

# Partner app
cd apps/tayyebgo_partner
flutter run -d chrome

# Admin app
cd apps/tayyebgo_admin
flutter run -d chrome
```

### Cloud Functions (local emulator)

```bash
cd cloud_functions/functions
npm run build
cd ../..
firebase emulators:start
```

## Running Tests

```bash
# Run tests for the core package (214+ tests)
cd packages/tayyebgo_core
flutter test

# Run tests with coverage report
flutter test --coverage

# Run a specific test file
flutter test test/infrastructure/services/order_state_machine_test.dart

# Run tests for a specific app
cd apps/tayyebgo_customer
flutter test
```

## Deploying to Firebase Hosting

### First-time setup

```bash
firebase login
firebase init hosting  # Select your project
```

### Deploy

```bash
# Build and deploy the customer app
cd apps/tayyebgo_customer
flutter build web --release
cd ../..
firebase deploy --only hosting
```

### Deploy Cloud Functions

```bash
cd cloud_functions/functions
npm run build
cd ../..
firebase deploy --only functions
```

### Deploy via CI/CD

Push to `main` branch — the GitHub Actions workflow will automatically:
1. Analyze code across all apps
2. Run unit tests with coverage
3. Build web versions
4. Deploy the customer app to Firebase Hosting
5. Rollback on failure

## IDE Setup

### VS Code

Install these extensions:
- Flutter
- Dart
- Firebase Explorer
- Error Lens

### Android Studio

Install the Flutter and Dart plugins. Set the Flutter SDK path in Settings → Languages & Frameworks → Flutter.
