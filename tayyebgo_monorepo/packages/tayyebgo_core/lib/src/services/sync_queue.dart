import 'dart:convert';

enum SyncActionType {
  placeOrder,
  updateProfile,
  updateCart,
  cancelOrder,
  rateOrder,
}

class SyncAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  SyncAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory SyncAction.fromMap(Map<String, dynamic> map) {
    return SyncAction(
      id: map['id'] as String,
      type: SyncActionType.values[map['type'] as int],
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  SyncAction copyWith({int? retryCount}) {
    return SyncAction(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class SyncQueue {
  final List<SyncAction> _queue = [];

  List<SyncAction> get pendingActions => List.unmodifiable(_queue);

  int get length => _queue.length;

  bool get isEmpty => _queue.isEmpty;

  bool get isNotEmpty => _queue.isNotEmpty;

  void enqueue(SyncAction action) {
    _queue.add(action);
  }

  SyncAction? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  void remove(String actionId) {
    _queue.removeWhere((action) => action.id == actionId);
  }

  void clear() {
    _queue.clear();
  }

  void loadFromMaps(List<Map<String, dynamic>> maps) {
    _queue.clear();
    _queue.addAll(maps.map((map) => SyncAction.fromMap(map)));
  }

  List<Map<String, dynamic>> toMaps() {
    return _queue.map((action) => action.toMap()).toList();
  }

  List<SyncAction> getActionsByType(SyncActionType type) {
    return _queue.where((action) => action.type == type).toList();
  }

  bool hasPendingAction(String actionId) {
    return _queue.any((action) => action.id == actionId);
  }
}
