import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/enums/order_status.dart';
import 'package:tayyebgo_core/infrastructure/services/order_state_machine.dart';

void main() {
  group('OrderStateMachine.isValidTransition', () {
    group('placed/pending → next states', () {
      test('placed → accepted is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.placed, OrderStatus.accepted), isTrue);
      });

      test('placed → cancelled is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.placed, OrderStatus.cancelled), isTrue);
      });

      test('pending → accepted is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.pending, OrderStatus.accepted), isTrue);
      });

      test('pending → cancelled is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.pending, OrderStatus.cancelled), isTrue);
      });

      test('placed → preparing is INVALID (skipping)', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.placed, OrderStatus.preparing), isFalse);
      });

      test('placed → delivered is INVALID (skipping)', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.placed, OrderStatus.delivered), isFalse);
      });

      test('placed → dispatched is INVALID (skipping)', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.placed, OrderStatus.dispatched), isFalse);
      });
    });

    group('accepted → next states', () {
      test('accepted → preparing is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.accepted, OrderStatus.preparing), isTrue);
      });

      test('accepted → cancelled is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.accepted, OrderStatus.cancelled), isTrue);
      });

      test('accepted → ready is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.accepted, OrderStatus.ready), isFalse);
      });

      test('accepted → delivered is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.accepted, OrderStatus.delivered), isFalse);
      });
    });

    group('preparing → next states', () {
      test('preparing → ready is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.preparing, OrderStatus.ready), isTrue);
      });

      test('preparing → cancelled is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.preparing, OrderStatus.cancelled), isTrue);
      });

      test('preparing → dispatched is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.preparing, OrderStatus.dispatched), isFalse);
      });
    });

    group('ready → readyForDriver → dispatched', () {
      test('ready → readyForDriver is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.ready, OrderStatus.readyForDriver), isTrue);
      });

      test('readyForDriver → dispatched is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.readyForDriver, OrderStatus.dispatched), isTrue);
      });

      test('ready → dispatched is INVALID (skipping readyForDriver)', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.ready, OrderStatus.dispatched), isFalse);
      });
    });

    group('dispatched → pickedUp → delivered', () {
      test('dispatched → pickedUp is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.dispatched, OrderStatus.pickedUp), isTrue);
      });

      test('pickedUp → delivered is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.pickedUp, OrderStatus.delivered), isTrue);
      });

      test('dispatched → delivered is INVALID (skipping pickedUp)', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.dispatched, OrderStatus.delivered), isFalse);
      });
    });

    group('terminal states', () {
      test('delivered → refunded is valid', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.delivered, OrderStatus.refunded), isTrue);
      });

      test('delivered → cancelled is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.delivered, OrderStatus.cancelled), isFalse);
      });

      test('delivered → accepted is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.delivered, OrderStatus.accepted), isFalse);
      });

      test('cancelled has no transitions', () {
        for (final status in OrderStatus.values) {
          expect(OrderStateMachine.isValidTransition(OrderStatus.cancelled, status), isFalse);
        }
      });

      test('refunded has no transitions', () {
        for (final status in OrderStatus.values) {
          expect(OrderStateMachine.isValidTransition(OrderStatus.refunded, status), isFalse);
        }
      });
    });

    group('reverse transitions', () {
      test('delivered → placed is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.delivered, OrderStatus.placed), isFalse);
      });

      test('cancelled → placed is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.cancelled, OrderStatus.placed), isFalse);
      });

      test('pickedUp → accepted is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.pickedUp, OrderStatus.accepted), isFalse);
      });

      test('dispatched → preparing is INVALID', () {
        expect(OrderStateMachine.isValidTransition(OrderStatus.dispatched, OrderStatus.preparing), isFalse);
      });
    });
  });

  group('OrderStateMachine.timelineLabels', () {
    test('returns 6 labels', () {
      final labels = OrderStateMachine.timelineLabels();
      expect(labels, hasLength(6));
      expect(labels, ['Placed', 'Accepted', 'Preparing', 'Ready', 'On the way', 'Delivered']);
    });
  });

  group('OrderStateMachine.buildTimeline', () {
    test('step 0 is completed when status is accepted', () {
      final result = OrderStateMachine.buildTimeline(OrderStatus.accepted, 0);
      expect(result.isCompleted, isTrue);
      expect(result.isCurrent, isFalse);
      expect(result.label, 'Placed');
    });

    test('step 1 is current when status is accepted', () {
      final result = OrderStateMachine.buildTimeline(OrderStatus.accepted, 1);
      expect(result.isCompleted, isFalse);
      expect(result.isCurrent, isTrue);
      expect(result.label, 'Accepted');
    });

    test('step 0 is current when status is placed', () {
      final result = OrderStateMachine.buildTimeline(OrderStatus.placed, 0);
      expect(result.isCurrent, isTrue);
      expect(result.isCompleted, isFalse);
    });

    test('all steps before dispatched are completed when dispatched', () {
      for (var i = 0; i < 4; i++) {
        final result = OrderStateMachine.buildTimeline(OrderStatus.dispatched, i);
        expect(result.isCompleted, isTrue, reason: 'Step $i should be completed');
      }
      final current = OrderStateMachine.buildTimeline(OrderStatus.dispatched, 4);
      expect(current.isCurrent, isTrue);
    });

    test('readyForDriver maps to step 3 (ready)', () {
      final result = OrderStateMachine.buildTimeline(OrderStatus.readyForDriver, 3);
      expect(result.isCurrent, isTrue);
    });

    test('pickedUp maps to step 4 (dispatched)', () {
      final result = OrderStateMachine.buildTimeline(OrderStatus.pickedUp, 4);
      expect(result.isCurrent, isTrue);
    });
  });

  group('complete pipeline validation', () {
    test('full happy path: placed → delivered', () {
      final pipeline = [
        (OrderStatus.placed, OrderStatus.accepted),
        (OrderStatus.accepted, OrderStatus.preparing),
        (OrderStatus.preparing, OrderStatus.ready),
        (OrderStatus.ready, OrderStatus.readyForDriver),
        (OrderStatus.readyForDriver, OrderStatus.dispatched),
        (OrderStatus.dispatched, OrderStatus.pickedUp),
        (OrderStatus.pickedUp, OrderStatus.delivered),
      ];

      for (final (from, to) in pipeline) {
        expect(
          OrderStateMachine.isValidTransition(from, to),
          isTrue,
          reason: '${from.value} → ${to.value} should be valid',
        );
      }
    });

    test('can cancel at any active stage', () {
      final cancellableStates = [
        OrderStatus.placed,
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.readyForDriver,
        OrderStatus.dispatched,
        OrderStatus.pickedUp,
      ];

      for (final state in cancellableStates) {
        expect(
          OrderStateMachine.isValidTransition(state, OrderStatus.cancelled),
          isTrue,
          reason: '${state.value} → cancelled should be valid',
        );
      }
    });
  });
}
