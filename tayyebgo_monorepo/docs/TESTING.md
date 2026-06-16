# Testing Guide

## Running Tests

### Core Package (primary test suite)

```bash
cd packages/tayyebgo_core
flutter test
```

This runs 214+ unit tests covering domain logic, services, and value objects.

### With Coverage Report

```bash
cd packages/tayyebgo_core
flutter test --coverage
# Coverage report at packages/tayyebgo_core/coverage/lcov.info
```

### Specific Test File

```bash
flutter test test/infrastructure/services/order_state_machine_test.dart
```

### Individual App Tests

```bash
cd apps/tayyebgo_customer && flutter test
cd apps/tayyebgo_driver && flutter test
cd apps/tayyebgo_partner && flutter test
cd apps/tayyebgo_admin && flutter test
```

## Test Structure

Tests mirror the source layout in `packages/tayyebgo_core/test/`:

```
test/
├── domain/
│   ├── entities/
│   │   └── customer_subscription_test.dart
│   ├── enums/
│   │   └── order_status_test.dart
│   └── value_objects/
│       ├── money_test.dart
│       └── geo_location_test.dart
├── infrastructure/
│   └── services/
│       ├── order_state_machine_test.dart
│       ├── order_state_machine_store_test.dart
│       ├── payment_orchestrator_test.dart
│       ├── commission_calculator_test.dart
│       ├── cash_payment_provider_test.dart
│       ├── driver_scorer_test.dart
│       └── subscription_service_test.dart
└── src/
    └── models/
        └── promo_model_test.dart
```

## Writing New Tests

### Basic Test Pattern

```dart
import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/value_objects/money.dart';

void main() {
  group('Money', () {
    test('creates from cents', () {
      final money = Money(1500);
      expect(money.amountInCents, 1500);
      expect(money.display, '\$15.00');
    });

    test('adds two amounts', () {
      final a = Money(1000);
      final b = Money(500);
      expect(a + b, Money(1500));
    });
  });
}
```

### Testing with Mocks

Use the `test` package. For Firebase-dependent services, create mock implementations of domain interfaces:

```dart
// Mock a repository interface
class MockOrderStore implements IOrderStore {
  final List<Order> _orders = [];

  @override
  Future<void> saveOrder(Order order) async {
    _orders.add(order);
  }

  @override
  Future<Order?> getOrder(String id) async {
    return _orders.firstWhere((o) => o.id == id, orElse: () => null);
  }
}

// In your test
test('places order through mock store', () async {
  final store = MockOrderStore();
  final service = OrderPlacementService(store);

  await service.placeOrder(/* ... */);

  final saved = await store.getOrder('order-123');
  expect(saved, isNotNull);
  expect(saved!.status, OrderStatus.placed);
});
```

### Grouping Tests

Use `group()` for related tests and descriptive `test()` names:

```dart
group('OrderStateMachine', () {
  test('transitions from placed to accepted', () { ... });
  test('transitions from accepted to preparing', () { ... });
  test('prevents invalid transition from delivered to preparing', () { ... });
  test('allows cancellation from placed state', () { ... });
});
```

## Mock Patterns

### Domain Interface Mocks

Create minimal mock classes that implement domain interfaces (`IOrderStore`, `IPaymentProvider`, etc.) rather than using heavy mocking libraries. This keeps tests readable and fast.

### Firebase Mocks

For services that interact with Firestore, mock the repository layer (e.g., `FirebaseOrderStore`) rather than the Firestore SDK directly. This tests your business logic without needing a live database.

### Value Object Testing

Value objects (`Money`, `GeoLocation`, `Address`) should have thorough equality, arithmetic, and boundary tests since they are used across the entire codebase.

## Target Coverage

| Area | Target | Rationale |
|---|---|---|
| Domain entities & value objects | 90%+ | Core business rules — must be correct |
| Domain services (interfaces) | N/A | Interfaces only, tested via implementations |
| Infrastructure services | 80%+ | Business logic services (order state machine, scoring, payment) |
| Providers | 70%+ | State management, mostly delegation |
| UI widgets | 60%+ | Critical widgets only (order status, payment flow) |
| Overall package | 75%+ | Balanced coverage across layers |

## CI Integration

Tests run automatically in CI (`.github/workflows/ci.yml`):

1. **analyze** job — Runs `flutter analyze` and `dart format --set-exit-if-changed`
2. **test** job — Runs `flutter test --coverage` for each app
3. **test-packages** job — Runs `flutter test --coverage` for `tayyebgo_core` and `tayyebgo_multi_tenant`
4. **build** job — Builds web versions after tests pass
5. Coverage reports are uploaded to Codecov

### Format Checking

```bash
# Check formatting without modifying files
dart format --set-exit-if-changed .
```

This runs in CI and will fail the build if any file is not properly formatted.
