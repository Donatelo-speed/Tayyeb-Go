import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus {
  open,
  assigned,
  inProgress,
  resolved,
  closed;

  String get value => switch (this) {
        open => 'open',
        assigned => 'assigned',
        inProgress => 'in_progress',
        resolved => 'resolved',
        closed => 'closed',
      };

  static TicketStatus fromValue(String v) => switch (v) {
        'open' => open,
        'assigned' => assigned,
        'in_progress' => inProgress,
        'resolved' => resolved,
        'closed' => closed,
        _ => open,
      };
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent;

  String get value => name;
}

class SupportTicket {
  final String id;
  final String userId;
  final String userRole;
  final String orderId;
  final String category;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String? assignedTo;
  final String? resolution;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userRole,
    this.orderId = '',
    required this.category,
    required this.description,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.medium,
    this.assignedTo,
    this.resolution,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userRole': userRole,
        'orderId': orderId,
        'category': category,
        'description': description,
        'status': status.value,
        'priority': priority.value,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (resolution != null) 'resolution': resolution,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SupportTicket.fromMap(Map<String, dynamic> m, String docId) =>
      SupportTicket(
        id: docId,
        userId: m['userId'] as String? ?? '',
        userRole: m['userRole'] as String? ?? 'customer',
        orderId: m['orderId'] as String? ?? '',
        category: m['category'] as String? ?? 'other',
        description: m['description'] as String? ?? '',
        status: TicketStatus.fromValue(m['status'] as String? ?? 'open'),
        priority: TicketPriority.values.firstWhere(
          (e) => e.value == (m['priority'] as String? ?? 'medium'),
          orElse: () => TicketPriority.medium,
        ),
        assignedTo: m['assignedTo'] as String?,
        resolution: m['resolution'] as String?,
        messages: (m['messages'] as List<dynamic>?)
                ?.map((e) => TicketMessage.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class TicketMessage {
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime timestamp;

  const TicketMessage({
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TicketMessage.fromMap(Map<String, dynamic> m) => TicketMessage(
        senderId: m['senderId'] as String? ?? '',
        senderRole: m['senderRole'] as String? ?? '',
        text: m['text'] as String? ?? '',
        timestamp:
            DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class SupportService {
  static final SupportService instance = SupportService._();
  SupportService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _validTransitions = {
    TicketStatus.open: [TicketStatus.assigned, TicketStatus.closed],
    TicketStatus.assigned: [TicketStatus.inProgress, TicketStatus.closed],
    TicketStatus.inProgress: [TicketStatus.resolved, TicketStatus.closed],
    TicketStatus.resolved: [TicketStatus.closed, TicketStatus.open],
    TicketStatus.closed: [],
  };

  Future<String> createTicket({
    required String userId,
    required String userRole,
    required String category,
    required String description,
    String orderId = '',
    TicketPriority priority = TicketPriority.medium,
  }) async {
    final now = DateTime.now();
    final doc = await _db.collection('support_tickets').add({
      'userId': userId,
      'userRole': userRole,
      'orderId': orderId,
      'category': category,
      'description': description,
      'status': TicketStatus.open.value,
      'priority': priority.value,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    await _trackEvent('ticket_created', {
      'ticketId': doc.id,
      'userId': userId,
      'category': category,
    });

    return doc.id;
  }

  Future<void> transitionTicket({
    required String ticketId,
    required TicketStatus newStatus,
    required String actorId,
    String? resolution,
  }) async {
    final doc = await _db.collection('support_tickets').doc(ticketId).get();
    if (!doc.exists) throw Exception('Ticket not found');

    final current =
        TicketStatus.fromValue(doc.data()?['status'] as String? ?? 'open');

    final allowed = _validTransitions[current];
    if (allowed == null || !allowed.contains(newStatus)) {
      throw Exception(
          'Invalid transition: ${current.value} → ${newStatus.value}');
    }

    final updates = <String, dynamic>{
      'status': newStatus.value,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (newStatus == TicketStatus.assigned) {
      updates['assignedTo'] = actorId;
    }
    if (newStatus == TicketStatus.resolved && resolution != null) {
      updates['resolution'] = resolution;
    }

    await _db.collection('support_tickets').doc(ticketId).update(updates);

    await _trackEvent('ticket_transitioned', {
      'ticketId': ticketId,
      'from': current.value,
      'to': newStatus.value,
      'actorId': actorId,
    });
  }

  Future<void> addMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final msg = TicketMessage(
      senderId: senderId,
      senderRole: senderRole,
      text: text,
      timestamp: DateTime.now(),
    );

    await _db.collection('support_tickets').doc(ticketId).update({
      'messages': FieldValue.arrayUnion([msg.toMap()]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<SupportTicket>> watchUserTickets(String userId) {
    return _db
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<SupportTicket>> watchOpenTickets() {
    return _db
        .collection('support_tickets')
        .where('status', whereIn: ['open', 'assigned', 'in_progress'])
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> _trackEvent(String event, Map<String, dynamic> data) async {
    try {
      await _db.collection('activity_log').add({
        'event': event,
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
