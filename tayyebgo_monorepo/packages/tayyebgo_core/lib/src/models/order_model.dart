import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatusEx {
  pending,
  accepted,
  preparing,
  readyForDriver,
  pickedUp,
  delivered,
  cancelled;

  static OrderStatusEx fromString(String? value) => switch (value) {
        'pending' => OrderStatusEx.pending,
        'accepted' => OrderStatusEx.accepted,
        'preparing' => OrderStatusEx.preparing,
        'ready_for_driver' => OrderStatusEx.readyForDriver,
        'picked_up' => OrderStatusEx.pickedUp,
        'delivered' => OrderStatusEx.delivered,
        'cancelled' => OrderStatusEx.cancelled,
        _ => OrderStatusEx.pending,
      };

  String get firestoreValue => name;

  String get displayName => switch (this) {
        OrderStatusEx.pending => 'Pending',
        OrderStatusEx.accepted => 'Accepted',
        OrderStatusEx.preparing => 'Preparing',
        OrderStatusEx.readyForDriver => 'Ready',
        OrderStatusEx.pickedUp => 'Picked Up',
        OrderStatusEx.delivered => 'Delivered',
        OrderStatusEx.cancelled => 'Cancelled',
      };

  bool get isActive => !isTerminal;

  bool get isTerminal => switch (this) {
        OrderStatusEx.delivered || OrderStatusEx.cancelled => true,
        _ => false,
      };

  int get timelineStep => switch (this) {
        OrderStatusEx.pending => 0,
        OrderStatusEx.accepted || OrderStatusEx.preparing => 1,
        OrderStatusEx.readyForDriver => 2,
        OrderStatusEx.pickedUp => 3,
        OrderStatusEx.delivered => 4,
        OrderStatusEx.cancelled => -1,
      };
}

enum OrderPaymentMethodEx {
  cash,
  card,
  applePay,
  googlePay,
  wallet;

  static OrderPaymentMethodEx fromString(String? value) => switch (value) {
        'cash' => OrderPaymentMethodEx.cash,
        'card' => OrderPaymentMethodEx.card,
        'apple_pay' => OrderPaymentMethodEx.applePay,
        'google_pay' => OrderPaymentMethodEx.googlePay,
        'wallet' => OrderPaymentMethodEx.wallet,
        _ => OrderPaymentMethodEx.cash,
      };

  String get firestoreValue => name;

  String get displayName => switch (this) {
        OrderPaymentMethodEx.cash => 'Cash on Delivery',
        OrderPaymentMethodEx.card => 'Credit / Debit Card',
        OrderPaymentMethodEx.applePay => 'Apple Pay',
        OrderPaymentMethodEx.googlePay => 'Google Pay',
        OrderPaymentMethodEx.wallet => 'Wallet Balance',
      };
}

class SelectedModifierEx {
  final String optionId;
  final String name;
  final double priceAdjustment;

  const SelectedModifierEx({
    required this.optionId,
    required this.name,
    this.priceAdjustment = 0.0,
  });

  factory SelectedModifierEx.fromFirestore(Map<String, dynamic> d) =>
      SelectedModifierEx(
        optionId: d['optionId']?.toString() ?? '',
        name: d['name'] as String? ?? '',
        priceAdjustment: (d['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toFirestore() => {
        'optionId': optionId,
        'name': name,
        'priceAdjustment': priceAdjustment,
      };
}

class OrderItemEx {
  final String productId;
  final String name;
  final String? nameAr;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<SelectedModifierEx> modifiers;
  final String? note;

  const OrderItemEx({
    required this.productId,
    required this.name,
    this.nameAr,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.modifiers = const [],
    this.note,
  });

  factory OrderItemEx.fromFirestore(Map<String, dynamic> d) => OrderItemEx(
        productId: d['productId']?.toString() ?? '',
        name: d['name'] as String? ?? '',
        nameAr: d['nameAr'] as String?,
        quantity: (d['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (d['unitPrice'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0.0,
        modifiers: (d['modifiers'] as List<dynamic>?)
                ?.map((m) => SelectedModifierEx.fromFirestore(m as Map<String, dynamic>))
                .toList() ??
            [],
        note: d['note'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'productId': productId,
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'modifiers': modifiers.map((m) => m.toFirestore()).toList(),
        if (note != null) 'note': note,
      };
}

class DeliveryAddressEx {
  final String fullAddress;
  final String? city;
  final String? street;
  final String? building;
  final String? floor;
  final String? apartment;
  final double? latitude;
  final double? longitude;

  const DeliveryAddressEx({
    required this.fullAddress,
    this.city,
    this.street,
    this.building,
    this.floor,
    this.apartment,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory DeliveryAddressEx.fromFirestore(Map<String, dynamic> d) =>
      DeliveryAddressEx(
        fullAddress: d['fullAddress'] as String? ?? d['address'] as String? ?? '',
        city: d['city'] as String?,
        street: d['street'] as String?,
        building: d['building'] as String?,
        floor: d['floor'] as String?,
        apartment: d['apartment'] as String?,
        latitude: (d['latitude'] as num?)?.toDouble(),
        longitude: (d['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toFirestore() => {
        'fullAddress': fullAddress,
        if (city != null) 'city': city,
        if (street != null) 'street': street,
        if (building != null) 'building': building,
        if (floor != null) 'floor': floor,
        if (apartment != null) 'apartment': apartment,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}

class OrderStatusEventEx {
  final String status;
  final DateTime? timestamp;
  final String actorId;
  final String? note;

  const OrderStatusEventEx({
    required this.status,
    this.timestamp,
    this.actorId = '',
    this.note,
  });

  factory OrderStatusEventEx.fromFirestore(Map<String, dynamic> d) =>
      OrderStatusEventEx(
        status: d['status'] as String? ?? '',
        timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
        actorId: d['actorId'] as String? ?? '',
        note: d['note'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'actorId': actorId,
        if (note != null) 'note': note,
      };
}

class OrderModelEx {
  final String id;
  final String restaurantId;
  final String? restaurantName;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final List<OrderItemEx> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double totalAmount;
  final String? promoCode;
  final double promoDiscount;
  final int loyaltyCoinsUsed;
  final int loyaltyCoinsEarned;
  final OrderStatusEx status;
  final List<OrderStatusEventEx> statusHistory;
  final Map<String, DateTime> statusMetrics;
  final OrderPaymentMethodEx paymentMethod;
  final bool isPaid;
  final String fulfillmentType;
  final DeliveryAddressEx deliveryAddress;
  final String? driverId;
  final String? driverName;
  final double? driverLatitude;
  final double? driverLongitude;
  final int? etaMinutes;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const OrderModelEx({
    required this.id,
    required this.restaurantId,
    this.restaurantName,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.items = const [],
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.totalAmount = 0.0,
    this.promoCode,
    this.promoDiscount = 0.0,
    this.loyaltyCoinsUsed = 0,
    this.loyaltyCoinsEarned = 0,
    this.status = OrderStatusEx.pending,
    this.statusHistory = const [],
    this.statusMetrics = const {},
    this.paymentMethod = OrderPaymentMethodEx.cash,
    this.isPaid = false,
    this.fulfillmentType = 'delivery',
    DeliveryAddressEx? deliveryAddress,
    this.driverId,
    this.driverName,
    this.driverLatitude,
    this.driverLongitude,
    this.etaMinutes,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.deliveredAt,
  }) : deliveryAddress = deliveryAddress ?? const DeliveryAddressEx(fullAddress: '');

  bool get isDelivery => fulfillmentType == 'delivery';
  bool get isPickup => fulfillmentType == 'pickup';
  bool get hasDriver => driverId != null;
  bool get hasDriverLocation => driverLatitude != null && driverLongitude != null;

  String get etaDisplay {
    if (etaMinutes == null) return '—';
    if (etaMinutes! < 1) return 'Arriving now';
    return '~$etaMinutes min';
  }

  Duration? get timeToAccept {
    final accepted = statusMetrics['accepted'];
    if (createdAt == null || accepted == null) return null;
    return accepted.difference(createdAt!);
  }

  Duration? get prepTime {
    final accepted = statusMetrics['accepted'];
    final ready = statusMetrics['ready_for_driver'];
    if (accepted == null || ready == null) return null;
    return ready.difference(accepted);
  }

  Duration? get totalDeliveryTime {
    if (createdAt == null || deliveredAt == null) return null;
    return deliveredAt!.difference(createdAt!);
  }

  factory OrderModelEx.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    final rawMetrics = d['statusMetrics'] as Map<String, dynamic>?;
    final Map<String, DateTime> metrics = {};
    if (rawMetrics != null) {
      for (final entry in rawMetrics.entries) {
        final ts = entry.value;
        if (ts is Timestamp) metrics[entry.key] = ts.toDate();
      }
    }

    return OrderModelEx(
      id: doc.id,
      restaurantId: d['restaurantId'] as String? ?? '',
      restaurantName: d['restaurantName'] as String?,
      customerId: d['customerId'] as String?,
      customerName: d['customerName'] as String? ?? 'Guest',
      customerPhone: d['customerPhone'] as String?,
      items: (d['items'] as List<dynamic>?)
              ?.map((i) => OrderItemEx.fromFirestore(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (d['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (d['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
      promoCode: d['promoCode'] as String?,
      promoDiscount: (d['promoDiscount'] as num?)?.toDouble() ?? 0.0,
      loyaltyCoinsUsed: (d['loyaltyCoinsUsed'] as num?)?.toInt() ?? 0,
      loyaltyCoinsEarned: (d['loyaltyCoinsEarned'] as num?)?.toInt() ?? 0,
      status: OrderStatusEx.fromString(d['status'] as String?),
      statusHistory: (d['statusHistory'] as List<dynamic>?)
              ?.map((e) => OrderStatusEventEx.fromFirestore(e as Map<String, dynamic>))
              .toList() ??
          [],
      statusMetrics: metrics,
      paymentMethod: OrderPaymentMethodEx.fromString(d['paymentMethod'] as String?),
      isPaid: d['isPaid'] as bool? ?? false,
      fulfillmentType: d['fulfillmentType'] as String? ?? 'delivery',
      deliveryAddress: DeliveryAddressEx.fromFirestore(
          (d['deliveryAddress'] as Map<String, dynamic>?) ?? {}),
      driverId: d['driverId'] as String?,
      driverName: d['driverName'] as String?,
      driverLatitude: (d['driverLatitude'] as num?)?.toDouble(),
      driverLongitude: (d['driverLongitude'] as num?)?.toDouble(),
      etaMinutes: (d['etaMinutes'] as num?)?.toInt(),
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'restaurantId': restaurantId,
        if (restaurantName != null) 'restaurantName': restaurantName,
        if (customerId != null) 'customerId': customerId,
        'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        'items': items.map((i) => i.toFirestore()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'tax': tax,
        'discount': discount,
        'totalAmount': totalAmount,
        if (promoCode != null) 'promoCode': promoCode,
        'promoDiscount': promoDiscount,
        'loyaltyCoinsUsed': loyaltyCoinsUsed,
        'loyaltyCoinsEarned': loyaltyCoinsEarned,
        'status': status.firestoreValue,
        'paymentMethod': paymentMethod.firestoreValue,
        'isPaid': isPaid,
        'fulfillmentType': fulfillmentType,
        'deliveryAddress': deliveryAddress.toFirestore(),
        if (driverId != null) 'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (driverLatitude != null) 'driverLatitude': driverLatitude,
        if (driverLongitude != null) 'driverLongitude': driverLongitude,
        if (etaMinutes != null) 'etaMinutes': etaMinutes,
        if (note != null) 'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  OrderModelEx copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<OrderItemEx>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? discount,
    double? totalAmount,
    String? promoCode,
    double? promoDiscount,
    int? loyaltyCoinsUsed,
    int? loyaltyCoinsEarned,
    OrderStatusEx? status,
    List<OrderStatusEventEx>? statusHistory,
    Map<String, DateTime>? statusMetrics,
    OrderPaymentMethodEx? paymentMethod,
    bool? isPaid,
    String? fulfillmentType,
    DeliveryAddressEx? deliveryAddress,
    String? driverId,
    String? driverName,
    double? driverLatitude,
    double? driverLongitude,
    int? etaMinutes,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? deliveredAt,
  }) =>
      OrderModelEx(
        id: id ?? this.id,
        restaurantId: restaurantId ?? this.restaurantId,
        restaurantName: restaurantName ?? this.restaurantName,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        tax: tax ?? this.tax,
        discount: discount ?? this.discount,
        totalAmount: totalAmount ?? this.totalAmount,
        promoCode: promoCode ?? this.promoCode,
        promoDiscount: promoDiscount ?? this.promoDiscount,
        loyaltyCoinsUsed: loyaltyCoinsUsed ?? this.loyaltyCoinsUsed,
        loyaltyCoinsEarned: loyaltyCoinsEarned ?? this.loyaltyCoinsEarned,
        status: status ?? this.status,
        statusHistory: statusHistory ?? this.statusHistory,
        statusMetrics: statusMetrics ?? this.statusMetrics,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        isPaid: isPaid ?? this.isPaid,
        fulfillmentType: fulfillmentType ?? this.fulfillmentType,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        driverLatitude: driverLatitude ?? this.driverLatitude,
        driverLongitude: driverLongitude ?? this.driverLongitude,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );
}
