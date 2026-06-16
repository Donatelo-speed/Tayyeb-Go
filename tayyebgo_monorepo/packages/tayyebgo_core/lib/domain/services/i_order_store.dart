/// Abstract interface for order state persistence.
/// OrderStateMachine uses this instead of Firestore directly.
abstract class IOrderStore {
  /// Read the current order data from storage
  Future<Map<String, dynamic>?> readOrder(String orderId);

  /// Update order fields
  Future<void> updateOrder(String orderId, Map<String, dynamic> updates);

  /// Run a batch of operations atomically
  Future<T> runTransaction<T>(Future<T> Function(IOrderStore txn) callback);
}
