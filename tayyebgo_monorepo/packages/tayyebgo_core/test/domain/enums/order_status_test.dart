import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/enums/order_status.dart';

void main() {
  group('OrderStatus', () {
    group('fromValue', () {
      test('resolves all known values', () {
        expect(OrderStatus.fromValue('placed'), OrderStatus.placed);
        expect(OrderStatus.fromValue('pending'), OrderStatus.pending);
        expect(OrderStatus.fromValue('accepted'), OrderStatus.accepted);
        expect(OrderStatus.fromValue('preparing'), OrderStatus.preparing);
        expect(OrderStatus.fromValue('ready'), OrderStatus.ready);
        expect(OrderStatus.fromValue('ready_for_driver'), OrderStatus.readyForDriver);
        expect(OrderStatus.fromValue('dispatched'), OrderStatus.dispatched);
        expect(OrderStatus.fromValue('picked_up'), OrderStatus.pickedUp);
        expect(OrderStatus.fromValue('delivered'), OrderStatus.delivered);
        expect(OrderStatus.fromValue('cancelled'), OrderStatus.cancelled);
        expect(OrderStatus.fromValue('refunded'), OrderStatus.refunded);
      });

      test('unknown value defaults to placed', () {
        expect(OrderStatus.fromValue('unknown'), OrderStatus.placed);
        expect(OrderStatus.fromValue(''), OrderStatus.placed);
      });
    });

    group('canonicalValue', () {
      test('pending maps to placed', () {
        expect(OrderStatus.pending.canonicalValue, 'placed');
      });

      test('other statuses map to their own value', () {
        expect(OrderStatus.placed.canonicalValue, 'placed');
        expect(OrderStatus.accepted.canonicalValue, 'accepted');
        expect(OrderStatus.delivered.canonicalValue, 'delivered');
        expect(OrderStatus.cancelled.canonicalValue, 'cancelled');
      });
    });

    group('isTerminal', () {
      test('delivered is terminal', () {
        expect(OrderStatus.delivered.isTerminal, isTrue);
      });

      test('cancelled is terminal', () {
        expect(OrderStatus.cancelled.isTerminal, isTrue);
      });

      test('refunded is terminal', () {
        expect(OrderStatus.refunded.isTerminal, isTrue);
      });

      test('placed is not terminal', () {
        expect(OrderStatus.placed.isTerminal, isFalse);
      });

      test('accepted is not terminal', () {
        expect(OrderStatus.accepted.isTerminal, isFalse);
      });

      test('dispatched is not terminal', () {
        expect(OrderStatus.dispatched.isTerminal, isFalse);
      });
    });

    group('isActive', () {
      test('placed is active', () {
        expect(OrderStatus.placed.isActive, isTrue);
      });

      test('delivered is not active', () {
        expect(OrderStatus.delivered.isActive, isFalse);
      });

      test('cancelled is not active', () {
        expect(OrderStatus.cancelled.isActive, isFalse);
      });
    });

    group('isCancellable', () {
      test('placed is cancellable', () {
        expect(OrderStatus.placed.isCancellable, isTrue);
      });

      test('pending is cancellable', () {
        expect(OrderStatus.pending.isCancellable, isTrue);
      });

      test('accepted is cancellable', () {
        expect(OrderStatus.accepted.isCancellable, isTrue);
      });

      test('preparing is not cancellable', () {
        expect(OrderStatus.preparing.isCancellable, isFalse);
      });

      test('dispatched is not cancellable', () {
        expect(OrderStatus.dispatched.isCancellable, isFalse);
      });

      test('delivered is not cancellable', () {
        expect(OrderStatus.delivered.isCancellable, isFalse);
      });
    });
  });
}
