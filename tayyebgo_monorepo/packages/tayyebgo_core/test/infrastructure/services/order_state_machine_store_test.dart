import 'package:test/test.dart';
import 'package:tayyebgo_core/domain/enums/order_status.dart';
import 'package:tayyebgo_core/domain/services/i_order_store.dart';
import 'package:tayyebgo_core/infrastructure/services/order_state_machine.dart';

class InMemoryOrderStore implements IOrderStore {
  final Map<String, Map<String, dynamic>> orders = {};

  @override
  Future<Map<String, dynamic>?> readOrder(String orderId) async =>
      orders[orderId];

  @override
  Future<void> updateOrder(
      String orderId, Map<String, dynamic> updates) async {
    if (orders.containsKey(orderId)) {
      orders[orderId]!.addAll(updates);
    }
  }

  @override
  Future<T> runTransaction<T>(
      Future<T> Function(IOrderStore txn) callback) async {
    return await callback(this);
  }
}

void main() {
  late InMemoryOrderStore store;

  setUp(() {
    store = InMemoryOrderStore();
  });

  Map<String, dynamic> _baseOrder({String status = 'placed'}) => {
        'status': status,
        'customerId': 'cust-1',
        'restaurantName': 'Burger House',
        'driverId': 'driver-1',
        'totalAmount': 15000.0,
        'deliveryFee': 5000.0,
        'commissionPercent': 15.0,
        'statusHistory': <Map<String, dynamic>>[],
      };

  group('full happy path: placed → delivered', () {
    test('transitions through every status', () async {
      store.orders['o1'] = _baseOrder();

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.accepted,
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'accepted');
      expect(store.orders['o1']!['acceptedAt'], isNotNull);

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.preparing,
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'preparing');

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.ready,
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'ready');
      expect(store.orders['o1']!['readyAt'], isNotNull);

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.readyForDriver,
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'ready_for_driver');
      expect(store.orders['o1']!['readyForDriverAt'], isNotNull);

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.dispatched,
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'dispatched');
      expect(store.orders['o1']!['dispatchedAt'], isNotNull);

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.pickedUp,
        actorId: 'driver-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'picked_up');
      expect(store.orders['o1']!['pickedUpAt'], isNotNull);

      await OrderStateMachine.transition(
        orderId: 'o1',
        newStatus: OrderStatus.delivered,
        actorId: 'driver-1',
        store: store,
      );
      expect(store.orders['o1']!['status'], 'delivered');
      expect(store.orders['o1']!['deliveredAt'], isNotNull);
    });
  });

  group('invalid transitions throw', () {
    test('placed → delivered throws', () async {
      store.orders['o2'] = _baseOrder();

      expect(
        () => OrderStateMachine.transition(
          orderId: 'o2',
          newStatus: OrderStatus.delivered,
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid transition'),
        )),
      );
    });

    test('placed → dispatched throws', () async {
      store.orders['o3'] = _baseOrder();

      expect(
        () => OrderStateMachine.transition(
          orderId: 'o3',
          newStatus: OrderStatus.dispatched,
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid transition'),
        )),
      );
    });

    test('placed → preparing throws (must accept first)', () async {
      store.orders['o4'] = _baseOrder();

      expect(
        () => OrderStateMachine.transition(
          orderId: 'o4',
          newStatus: OrderStatus.preparing,
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid transition'),
        )),
      );
    });

    test('delivered → accepted throws (terminal state)', () async {
      store.orders['o5'] = _baseOrder(status: 'delivered');

      expect(
        () => OrderStateMachine.transition(
          orderId: 'o5',
          newStatus: OrderStatus.accepted,
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid transition'),
        )),
      );
    });

    test('nonexistent order throws', () async {
      expect(
        () => OrderStateMachine.transition(
          orderId: 'nonexistent',
          newStatus: OrderStatus.accepted,
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not found'),
        )),
      );
    });
  });

  group('cancellation at each stage', () {
    test('can cancel from placed', () async {
      store.orders['c1'] = _baseOrder();

      await OrderStateMachine.rejectOrder(
        orderId: 'c1',
        actorId: 'cust-1',
        reason: 'Changed mind',
        store: store,
      );
      expect(store.orders['c1']!['status'], 'cancelled');
      expect(store.orders['c1']!['rejectionReason'], 'Changed mind');
    });

    test('can cancel from accepted', () async {
      store.orders['c2'] = _baseOrder(status: 'accepted');

      await OrderStateMachine.rejectOrder(
        orderId: 'c2',
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['c2']!['status'], 'cancelled');
    });

    test('can cancel from preparing', () async {
      store.orders['c3'] = _baseOrder(status: 'preparing');

      await OrderStateMachine.rejectOrder(
        orderId: 'c3',
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['c3']!['status'], 'cancelled');
    });

    test('can cancel from ready', () async {
      store.orders['c4'] = _baseOrder(status: 'ready');

      await OrderStateMachine.rejectOrder(
        orderId: 'c4',
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['c4']!['status'], 'cancelled');
    });

    test('can cancel from readyForDriver', () async {
      store.orders['c5'] = _baseOrder(status: 'ready_for_driver');

      await OrderStateMachine.rejectOrder(
        orderId: 'c5',
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['c5']!['status'], 'cancelled');
    });

    test('can cancel from dispatched', () async {
      store.orders['c6'] = _baseOrder(status: 'dispatched');

      await OrderStateMachine.rejectOrder(
        orderId: 'c6',
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['c6']!['status'], 'cancelled');
    });

    test('can cancel from pickedUp', () async {
      store.orders['c7'] = _baseOrder(status: 'picked_up');

      await OrderStateMachine.rejectOrder(
        orderId: 'c7',
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['c7']!['status'], 'cancelled');
    });

    test('cannot cancel from delivered', () async {
      store.orders['c8'] = _baseOrder(status: 'delivered');

      expect(
        () => OrderStateMachine.rejectOrder(
          orderId: 'c8',
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Cannot reject'),
        )),
      );
    });

    test('cannot cancel already cancelled order', () async {
      store.orders['c9'] = _baseOrder(status: 'cancelled');

      expect(
        () => OrderStateMachine.rejectOrder(
          orderId: 'c9',
          actorId: 'rest-1',
          store: store,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Cannot reject'),
        )),
      );
    });
  });

  group('statusHistory is appended correctly', () {
    test('history grows with each transition', () async {
      store.orders['h1'] = _baseOrder();

      await OrderStateMachine.transition(
        orderId: 'h1',
        newStatus: OrderStatus.accepted,
        actorId: 'rest-1',
        store: store,
      );

      var history =
          store.orders['h1']!['statusHistory'] as List<Map<String, dynamic>>;
      expect(history, hasLength(1));
      expect(history[0]['from'], 'placed');
      expect(history[0]['to'], 'accepted');
      expect(history[0]['actorId'], 'rest-1');
      expect(history[0]['timestamp'], isNotNull);

      await OrderStateMachine.transition(
        orderId: 'h1',
        newStatus: OrderStatus.preparing,
        actorId: 'rest-1',
        store: store,
      );

      history =
          store.orders['h1']!['statusHistory'] as List<Map<String, dynamic>>;
      expect(history, hasLength(2));
      expect(history[1]['from'], 'accepted');
      expect(history[1]['to'], 'preparing');
    });

    test('rejection appends to history', () async {
      store.orders['h2'] = _baseOrder();

      await OrderStateMachine.rejectOrder(
        orderId: 'h2',
        actorId: 'cust-1',
        reason: 'Too expensive',
        store: store,
      );

      final history =
          store.orders['h2']!['statusHistory'] as List<Map<String, dynamic>>;
      expect(history, hasLength(1));
      expect(history[0]['from'], 'placed');
      expect(history[0]['to'], 'cancelled');
      expect(history[0]['note'], 'Too expensive');
      expect(history[0]['actorId'], 'cust-1');
    });

    test('latitude/longitude captured in history', () async {
      store.orders['h3'] = _baseOrder();

      await OrderStateMachine.transition(
        orderId: 'h3',
        newStatus: OrderStatus.accepted,
        actorId: 'rest-1',
        latitude: -6.2088,
        longitude: 106.8456,
        store: store,
      );

      final history =
          store.orders['h3']!['statusHistory'] as List<Map<String, dynamic>>;
      expect(history[0]['latitude'], -6.2088);
      expect(history[0]['longitude'], 106.8456);
    });

    test('note captured in history', () async {
      store.orders['h4'] = _baseOrder();

      await OrderStateMachine.transition(
        orderId: 'h4',
        newStatus: OrderStatus.accepted,
        actorId: 'rest-1',
        note: 'VIP customer',
        store: store,
      );

      final history =
          store.orders['h4']!['statusHistory'] as List<Map<String, dynamic>>;
      expect(history[0]['note'], 'VIP customer');
    });
  });

  group('timestamp fields are set correctly', () {
    test('acceptedAt is set when transitioning to accepted', () async {
      store.orders['t1'] = _baseOrder();
      final before = DateTime.now().toIso8601String();

      await OrderStateMachine.transition(
        orderId: 't1',
        newStatus: OrderStatus.accepted,
        actorId: 'rest-1',
        store: store,
      );

      expect(store.orders['t1']!['acceptedAt'], isNotNull);
      final acceptedAt = store.orders['t1']!['acceptedAt'] as String;
      expect(acceptedAt.compareTo(before), greaterThanOrEqualTo(-1));
    });

    test('readyAt is set when transitioning to ready', () async {
      store.orders['t2'] = _baseOrder(status: 'preparing');

      await OrderStateMachine.transition(
        orderId: 't2',
        newStatus: OrderStatus.ready,
        actorId: 'rest-1',
        store: store,
      );

      expect(store.orders['t2']!['readyAt'], isNotNull);
    });

    test('readyForDriverAt is set', () async {
      store.orders['t3'] = _baseOrder(status: 'ready');

      await OrderStateMachine.transition(
        orderId: 't3',
        newStatus: OrderStatus.readyForDriver,
        actorId: 'rest-1',
        store: store,
      );

      expect(store.orders['t3']!['readyForDriverAt'], isNotNull);
    });

    test('dispatchedAt is set', () async {
      store.orders['t4'] = _baseOrder(status: 'ready_for_driver');

      await OrderStateMachine.transition(
        orderId: 't4',
        newStatus: OrderStatus.dispatched,
        actorId: 'rest-1',
        store: store,
      );

      expect(store.orders['t4']!['dispatchedAt'], isNotNull);
    });

    test('pickedUpAt is set', () async {
      store.orders['t5'] = _baseOrder(status: 'dispatched');

      await OrderStateMachine.transition(
        orderId: 't5',
        newStatus: OrderStatus.pickedUp,
        actorId: 'driver-1',
        store: store,
      );

      expect(store.orders['t5']!['pickedUpAt'], isNotNull);
    });

    test('deliveredAt is set', () async {
      store.orders['t6'] = _baseOrder(status: 'picked_up');

      await OrderStateMachine.transition(
        orderId: 't6',
        newStatus: OrderStatus.delivered,
        actorId: 'driver-1',
        store: store,
      );

      expect(store.orders['t6']!['deliveredAt'], isNotNull);
    });

    test('updatedAt is set on every transition', () async {
      store.orders['t7'] = _baseOrder();

      await OrderStateMachine.transition(
        orderId: 't7',
        newStatus: OrderStatus.accepted,
        actorId: 'rest-1',
        store: store,
      );

      expect(store.orders['t7']!['updatedAt'], isNotNull);
    });
  });

  group('cancel via transition method', () {
    test('transition to cancelled works if valid', () async {
      store.orders['x1'] = _baseOrder();

      await OrderStateMachine.transition(
        orderId: 'x1',
        newStatus: OrderStatus.cancelled,
        actorId: 'cust-1',
        store: store,
      );
      expect(store.orders['x1']!['status'], 'cancelled');
    });

    test('cancel from preparing via transition works', () async {
      store.orders['x2'] = _baseOrder(status: 'preparing');

      await OrderStateMachine.transition(
        orderId: 'x2',
        newStatus: OrderStatus.cancelled,
        actorId: 'rest-1',
        store: store,
      );
      expect(store.orders['x2']!['status'], 'cancelled');
    });
  });
}
