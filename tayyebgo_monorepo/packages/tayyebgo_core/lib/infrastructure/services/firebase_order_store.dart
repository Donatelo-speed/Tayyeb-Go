import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/services/i_order_store.dart';

class FirebaseOrderStore implements IOrderStore {
  static final FirebaseOrderStore instance = FirebaseOrderStore._();
  FirebaseOrderStore._();

  @override
  Future<Map<String, dynamic>?> readOrder(String orderId) async {
    final snap =
        await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    return snap.exists ? snap.data() : null;
  }

  @override
  Future<void> updateOrder(
      String orderId, Map<String, dynamic> updates) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update(updates);
  }

  @override
  Future<T> runTransaction<T>(
      Future<T> Function(IOrderStore txn) callback) async {
    return await FirebaseFirestore.instance.runTransaction((txn) async {
      final store = _TransactionOrderStore(txn);
      return await callback(store);
    });
  }
}

class _TransactionOrderStore implements IOrderStore {
  final Transaction _txn;
  _TransactionOrderStore(this._txn);

  @override
  Future<Map<String, dynamic>?> readOrder(String orderId) async {
    final snap = await _txn
        .get(FirebaseFirestore.instance.collection('orders').doc(orderId));
    return snap.exists ? snap.data() : null;
  }

  @override
  Future<void> updateOrder(
      String orderId, Map<String, dynamic> updates) async {
    _txn.update(
        FirebaseFirestore.instance.collection('orders').doc(orderId), updates);
  }

  @override
  Future<T> runTransaction<T>(
      Future<T> Function(IOrderStore txn) callback) async {
    throw UnsupportedError('Nested transactions not supported');
  }
}
