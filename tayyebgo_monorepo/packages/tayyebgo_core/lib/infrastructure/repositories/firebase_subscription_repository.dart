import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_subscription.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/repositories/i_subscription_repository.dart';

class FirebaseSubscriptionRepository implements ISubscriptionRepository {
  static final FirebaseSubscriptionRepository instance =
      FirebaseSubscriptionRepository._();
  FirebaseSubscriptionRepository._();

  final _col = FirebaseFirestore.instance.collection('subscriptions');

  @override
  Stream<CustomerSubscription?> watchActiveSubscription(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final sub = CustomerSubscription.fromMap(doc.data(), doc.id);
      if (sub.isExpired) return null;
      return sub;
    });
  }

  @override
  Future<CustomerSubscription?> getActiveSubscription(String userId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final sub =
        CustomerSubscription.fromMap(snap.docs.first.data(), snap.docs.first.id);
    return sub.isExpired ? null : sub;
  }

  @override
  Future<List<CustomerSubscription>> getSubscriptionHistory(
      String userId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => CustomerSubscription.fromMap(d.data(), d.id))
        .toList();
  }

  @override
  Future<void> createSubscription(CustomerSubscription subscription) async {
    await _col.add(subscription.toMap()..remove('id'));
  }

  @override
  Future<void> updateSubscription(
      String id, Map<String, dynamic> updates) async {
    await _col.doc(id).update(updates);
  }

  @override
  Future<void> cancelSubscription(String id, String reason) async {
    await _col.doc(id).update({
      'status': SubscriptionStatus.cancelled.value,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancelReason': reason,
    });
  }

  @override
  Future<int> getSubscriberCount() async {
    final snap =
        await _col.where('status', isEqualTo: 'active').get();
    return snap.docs.length;
  }

  @override
  Future<double> getMonthlyRevenue() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final snap = await _col
        .where('createdAt',
            isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .get();
    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['pricePaid'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}
