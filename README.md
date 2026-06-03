# TayyebGo

A multi-tenant food delivery platform built with Flutter and Firebase.

## Architecture

- **tayyebgo_monorepo/** — canonical monorepo with 4 Flutter apps (admin, customer, driver, partner)
- **docs/** — reference documentation

### Apps

| App | Description | Tech |
|-----|-------------|------|
| `tayyebgo_admin` | Super admin web panel | Flutter + GoRouter + Firebase |
| `tayyebgo_customer` | Customer ordering app | Flutter + GoRouter + Firebase |
| `tayyebgo_driver` | Driver delivery app | Flutter + GoRouter + Firebase |
| `tayyebgo_partner` | Restaurant partner app | Flutter + GoRouter + Firebase |

### Shared Packages

- `tayyebgo_core` — shared entities, services, theme system, widgets
- `tayyebgo_multi_tenant` — multi-vertical tenant management
- `tayyebgo_payment` — payment gateway
- `tayyebgo_payout` — vendor payout system

### Cloud Functions

- `functions/` — Firebase Cloud Functions (FCM push, OpenAI proxy, cleanup)

## Quick Start

```bash
cd tayyebgo_monorepo
flutter pub get
cd apps/tayyebgo_admin && flutter run -d chrome
```
