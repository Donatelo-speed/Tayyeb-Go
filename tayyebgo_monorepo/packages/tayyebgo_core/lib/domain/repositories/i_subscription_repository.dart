import '../entities/customer_subscription.dart';

abstract class ISubscriptionRepository {
  Stream<CustomerSubscription?> watchActiveSubscription(String userId);
  Future<CustomerSubscription?> getActiveSubscription(String userId);
  Future<List<CustomerSubscription>> getSubscriptionHistory(String userId);
  Future<void> createSubscription(CustomerSubscription subscription);
  Future<void> updateSubscription(String id, Map<String, dynamic> updates);
  Future<void> cancelSubscription(String id, String reason);
  Future<int> getSubscriberCount();
  Future<double> getMonthlyRevenue();
}
