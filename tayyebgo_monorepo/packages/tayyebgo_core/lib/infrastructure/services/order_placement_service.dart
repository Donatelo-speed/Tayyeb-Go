import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPlacementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a 4-digit delivery PIN for order verification.
  String _generateDeliveryPin() {
    final rng = Random.secure();
    return (1000 + rng.nextInt(9000)).toString();
  }

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
    String? promoCode,
    double? promoDiscount,
    int? subtotalCents,
    int? deliveryFeeCents,
    int? taxCents,
  }) async {
    final orderRef = _firestore.collection('orders').doc();
    final deliveryPin = _generateDeliveryPin();

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
      'deliveryPin': deliveryPin,
      'deliveryPinVerified': false,
      'statusHistory': statusHistory,
      'createdAt': now,
      'updatedAt': now,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      if (promoDiscount != null && promoDiscount > 0) 'promoDiscount': promoDiscount,
      if (subtotalCents != null) 'subtotalAmount': subtotalCents,
      if (deliveryFeeCents != null) 'deliveryFee': deliveryFeeCents,
      if (taxCents != null) 'taxAmount': taxCents,
    };

    await orderRef.set(orderData);

    double? pickupLat;
    double? pickupLon;
    try {
      final restaurantDoc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      if (restaurantDoc.exists) {
        final rData = restaurantDoc.data()!;
        pickupLat = (rData['latitude'] as num?)?.toDouble();
        pickupLon = (rData['longitude'] as num?)?.toDouble();
      }
    } catch (_) {}

    final dispatchRef = _firestore.collection('dispatch_requests').doc();
    await dispatchRef.set({
      'orderId': orderRef.id,
      'restaurantId': restaurantId,
      'status': 'pending',
      'pickupLat': pickupLat,
      'pickupLon': pickupLon,
      'dropoffLat': dropoffLatitude,
      'dropoffLon': dropoffLongitude,
      'customerId': customerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }
}
