import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPlacementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> placeOrder({
    required String customerId,
    required String restaurantId,
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required int totalAmountInCents,
    required String paymentMethodType,
    required double commissionPercent,
    required String fulfillmentType,
    Map<String, dynamic>? deliveryAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
  }) async {
    final orderRef = _firestore.collection('Orders').doc();

    final now = FieldValue.serverTimestamp();
    final statusHistory = [
      {
        'from': '',
        'to': 'placed',
        'timestamp': now,
        'actorId': customerId,
        'note': 'Order placed',
      },
    ];

    final orderData = {
      'status': 'placed',
      'customerId': customerId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items,
      'totalAmount': totalAmountInCents,
      'paymentMethodType': paymentMethodType,
      'commissionPercent': commissionPercent,
      'fulfillmentType': fulfillmentType,
      'deliveryAddress': deliveryAddress,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'statusHistory': statusHistory,
      'createdAt': now,
      'updatedAt': now,
    };

    await orderRef.set(orderData);

    final dispatchRef = _firestore.collection('dispatch_requests').doc();
    await dispatchRef.set({
      'orderId': orderRef.id,
      'restaurantId': restaurantId,
      'status': 'pending',
      'pickupLat': null,
      'pickupLon': null,
      'dropoffLat': dropoffLatitude,
      'dropoffLon': dropoffLongitude,
      'customerId': customerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }
}
