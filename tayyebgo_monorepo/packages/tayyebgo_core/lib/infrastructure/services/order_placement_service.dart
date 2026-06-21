import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fake_order_detector.dart';

class OrderPlacementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    double? tip,
  }) async {
    // Fraud detection before creating anything
    DetectionResult? fraudResult;
    try {
      fraudResult = await FakeOrderDetector.instance.analyzeOrder(
        customerId: customerId,
        restaurantId: restaurantId,
        totalAmount: totalAmountInCents / 100.0,
        paymentMethod: paymentMethodType,
        deliveryAddress: deliveryAddress ?? {},
      );
    } catch (e) {
      // Don't block orders on fraud check failure
    }

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
      if (tip != null && tip > 0) 'tip': tip,
      if (fraudResult != null) 'fraudCheck': fraudResult.toMap(),
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
    final isHighRisk = fraudResult != null && fraudResult.riskLevel == 'HIGH';

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
      if (isHighRisk) 'fraudRisk': true,
      if (fraudResult != null) 'riskLevel': fraudResult.riskLevel,
      if (fraudResult != null) 'riskFlags': fraudResult.flags,
    });

    return orderRef.id;
  }
}
