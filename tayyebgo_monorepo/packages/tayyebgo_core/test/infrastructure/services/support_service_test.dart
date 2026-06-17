import 'package:test/test.dart';
import 'package:tayyebgo_core/infrastructure/services/support_service.dart';

void main() {
  group('TicketStatus', () {
    test('fromValue returns correct status', () {
      expect(TicketStatus.fromValue('open'), TicketStatus.open);
      expect(TicketStatus.fromValue('assigned'), TicketStatus.assigned);
      expect(TicketStatus.fromValue('in_progress'), TicketStatus.inProgress);
      expect(TicketStatus.fromValue('resolved'), TicketStatus.resolved);
      expect(TicketStatus.fromValue('closed'), TicketStatus.closed);
      expect(TicketStatus.fromValue('unknown'), TicketStatus.open);
    });

    test('value returns correct string', () {
      expect(TicketStatus.open.value, 'open');
      expect(TicketStatus.assigned.value, 'assigned');
      expect(TicketStatus.inProgress.value, 'in_progress');
      expect(TicketStatus.resolved.value, 'resolved');
      expect(TicketStatus.closed.value, 'closed');
    });
  });

  group('TicketPriority', () {
    test('value returns name', () {
      expect(TicketPriority.low.value, 'low');
      expect(TicketPriority.medium.value, 'medium');
      expect(TicketPriority.high.value, 'high');
      expect(TicketPriority.urgent.value, 'urgent');
    });
  });

  group('SupportTicket', () {
    test('toMap and fromMap roundtrip', () {
      final ticket = SupportTicket(
        id: 'test-123',
        userId: 'user-1',
        userRole: 'customer',
        orderId: 'order-1',
        category: 'order_issue',
        description: 'Order was late',
        status: TicketStatus.open,
        priority: TicketPriority.medium,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final map = ticket.toMap();
      expect(map['userId'], 'user-1');
      expect(map['category'], 'order_issue');
      expect(map['status'], 'open');
      expect(map['priority'], 'medium');

      final restored = SupportTicket.fromMap(map, 'test-123');
      expect(restored.id, 'test-123');
      expect(restored.userId, 'user-1');
      expect(restored.status, TicketStatus.open);
      expect(restored.priority, TicketPriority.medium);
    });

    test('fromMap handles missing fields gracefully', () {
      final map = <String, dynamic>{};
      final ticket = SupportTicket.fromMap(map, 'id');
      expect(ticket.userId, '');
      expect(ticket.category, 'other');
      expect(ticket.status, TicketStatus.open);
      expect(ticket.priority, TicketPriority.medium);
    });
  });

  group('TicketMessage', () {
    test('toMap and fromMap roundtrip', () {
      final msg = TicketMessage(
        senderId: 'user-1',
        senderRole: 'customer',
        text: 'Hello',
        timestamp: DateTime(2025, 1, 1),
      );

      final map = msg.toMap();
      expect(map['senderId'], 'user-1');
      expect(map['text'], 'Hello');

      final restored = TicketMessage.fromMap(map);
      expect(restored.senderId, 'user-1');
      expect(restored.text, 'Hello');
    });
  });
}
