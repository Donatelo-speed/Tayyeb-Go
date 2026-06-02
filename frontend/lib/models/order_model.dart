// =====================================================
// TAYYEB-GO — lib/models/order_model.dart
//
// Typed Dart model for the /orders/{orderId} Firestore collection.
//
// Covers the complete order lifecycle:
//   pending → accepted → preparing → ready_for_driver
//           → picked_up → delivered | cancelled
//
// Sub-models:
//   • OrderItem          — one line in the order (product + qty + modifiers)
//   • SelectedModifier   — a single modifier option chosen by the customer
//   • DeliveryAddress    — snapshot of the delivery address at order time
//   • OrderStatusEvent   — immutable log entry in the status_history array
// =====================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// OrderStatus — canonical lifecycle values
// =============================================================================

/// String constants for the `status` field.  Mirrors the constants already
/// defined in [OrderStatus] inside database_service.dart; this typed version
/// adds helpers used by the model layer.
enum OrderStatus {
  pending,
  accepted,
  preparing,
  readyForDriver,
  pickedUp,
  delivered,
  cancelled;

  // ── String ↔ enum ──────────────────────────────────────────────────────────

  static OrderStatus fromString(String? value) {
    return switch (value) {
      'pending'           => OrderStatus.pending,
      'accepted'          => OrderStatus.accepted,
      'preparing'         => OrderStatus.preparing,
      'ready_for_driver'  => OrderStatus.readyForDriver,
      'picked_up'         => OrderStatus.pickedUp,
      'delivered'         => OrderStatus.delivered,
      'cancelled'         => OrderStatus.cancelled,
      _                   => OrderStatus.pending,
    };
  }

  /// The snake_case string stored in Firestore.
  String get firestoreValue => switch (this) {
    OrderStatus.pending        => 'pending',
    OrderStatus.accepted       => 'accepted',
    OrderStatus.preparing      => 'preparing',
    OrderStatus.readyForDriver => 'ready_for_driver',
    OrderStatus.pickedUp       => 'picked_up',
    OrderStatus.delivered      => 'delivered',
    OrderStatus.cancelled      => 'cancelled',
  };

  /// English display label.
  String get displayName => switch (this) {
    OrderStatus.pending        => 'Pending',
    OrderStatus.accepted       => 'Accepted',
    OrderStatus.preparing      => 'Preparing',
    OrderStatus.readyForDriver => 'Ready for Driver',
    OrderStatus.pickedUp       => 'Picked Up',
    OrderStatus.delivered      => 'Delivered',
    OrderStatus.cancelled      => 'Cancelled',
  };

  /// Arabic display label.
  String get displayNameAr => switch (this) {
    OrderStatus.pending        => 'قيد الانتظار',
    OrderStatus.accepted       => 'مقبول',
    OrderStatus.preparing      => 'يُحضَّر',
    OrderStatus.readyForDriver => 'جاهز للتسليم',
    OrderStatus.pickedUp       => 'تم الاستلام',
    OrderStatus.delivered      => 'تم التوصيل',
    OrderStatus.cancelled      => 'ملغي',
  };

  /// Whether this status means the order is still in an active state.
  bool get isActive =>
      this == pending ||
      this == accepted ||
      this == preparing ||
      this == readyForDriver ||
      this == pickedUp;

  bool get isTerminal => this == delivered || this == cancelled;
}

// =============================================================================
// OrderPaymentMethod
// =============================================================================

enum OrderPaymentMethod {
  cash,
  card,
  applePay,
  googlePay,
  wallet;

  static OrderPaymentMethod fromString(String? value) {
    return switch (value) {
      'cash'       => OrderPaymentMethod.cash,
      'card'       => OrderPaymentMethod.card,
      'apple_pay'  => OrderPaymentMethod.applePay,
      'google_pay' => OrderPaymentMethod.googlePay,
      'wallet'     => OrderPaymentMethod.wallet,
      _            => OrderPaymentMethod.cash,
    };
  }

  String get firestoreValue => switch (this) {
    OrderPaymentMethod.cash      => 'cash',
    OrderPaymentMethod.card      => 'card',
    OrderPaymentMethod.applePay  => 'apple_pay',
    OrderPaymentMethod.googlePay => 'google_pay',
    OrderPaymentMethod.wallet    => 'wallet',
  };
}

// =============================================================================
// SelectedModifier — one modifier option on a line item
// =============================================================================

/// Represents a single modifier option chosen by the customer.
///
/// Firestore shape (inside an OrderItem's `selectedModifiers` array):
/// ```json
/// {
///   "groupName": "Protein",
///   "optionName": "Extra Cheese",
///   "priceDelta": 2.50
/// }
/// ```
class SelectedModifier {
  final String groupName;
  final String optionName;
  final double priceDelta;

  const SelectedModifier({
    required this.groupName,
    required this.optionName,
    this.priceDelta = 0.0,
  });

  factory SelectedModifier.fromMap(Map<String, dynamic> map) {
    return SelectedModifier(
      groupName:  (map['groupName']  as String?) ?? '',
      optionName: (map['optionName'] as String?) ?? '',
      priceDelta: _toDouble(map['priceDelta']),
    );
  }

  Map<String, dynamic> toMap() => {
    'groupName':  groupName,
    'optionName': optionName,
    'priceDelta': priceDelta,
  };
}

// =============================================================================
// OrderItem — one line in the order
// =============================================================================

/// Firestore shape (inside the `items` array on an order document):
/// ```json
/// {
///   "productId":   "menu-item-doc-id",
///   "name":        "Mandi Rice – Large",
///   "nameAr":      "مندي أرز – كبير",
///   "imageUrl":    "https://...",
///   "basePrice":   45.00,
///   "quantity":    2,
///   "customerNote": "No onions please",
///   "selectedModifiers": [ ... ]
/// }
/// ```
class OrderItem {
  final String   productId;
  final String   name;
  final String?  nameAr;
  final String?  imageUrl;
  final double   basePrice;
  final int      quantity;
  final String?  customerNote;
  final List<SelectedModifier> selectedModifiers;

  const OrderItem({
    required this.productId,
    required this.name,
    this.nameAr,
    this.imageUrl,
    required this.basePrice,
    this.quantity = 1,
    this.customerNote,
    this.selectedModifiers = const [],
  });

  // ── Computed helpers ───────────────────────────────────────────────────────

  double get modifierDelta =>
      selectedModifiers.fold(0.0, (sum, m) => sum + m.priceDelta);

  double get unitPrice  => basePrice + modifierDelta;
  double get lineTotal  => unitPrice * quantity;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final rawModifiers = map['selectedModifiers'];
    final modifiers = rawModifiers is List
        ? rawModifiers
            .whereType<Map<String, dynamic>>()
            .map(SelectedModifier.fromMap)
            .toList()
        : <SelectedModifier>[];

    return OrderItem(
      productId:         (map['productId']    as String?) ?? '',
      name:              (map['name']         as String?) ?? '',
      nameAr:             map['nameAr']       as String?,
      imageUrl:           map['imageUrl']     as String?,
      basePrice:         _toDouble(map['basePrice']),
      quantity:          (map['quantity']     as int?)    ?? 1,
      customerNote:       map['customerNote'] as String?,
      selectedModifiers: modifiers,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId':         productId,
    'name':              name,
    if (nameAr       != null) 'nameAr':       nameAr,
    if (imageUrl     != null) 'imageUrl':      imageUrl,
    'basePrice':         basePrice,
    'quantity':          quantity,
    if (customerNote != null) 'customerNote':  customerNote,
    'selectedModifiers': selectedModifiers.map((m) => m.toMap()).toList(),
  };
}

// =============================================================================
// DeliveryAddress — snapshot of the address at order-placement time
// =============================================================================

/// Firestore shape (the `deliveryAddress` map on an order document):
/// ```json
/// {
///   "street":    "King Fahad Road",
///   "district":  "Al Malqa",
///   "city":      "Riyadh",
///   "country":   "Saudi Arabia",
///   "notes":     "Blue gate on the left",
///   "latitude":  24.7136,
///   "longitude": 46.6753
/// }
/// ```
class DeliveryAddress {
  final String  street;
  final String? district;
  final String  city;
  final String  country;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const DeliveryAddress({
    required this.street,
    this.district,
    required this.city,
    this.country = 'Saudi Arabia',
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      street:    (map['street']   as String?) ?? '',
      district:   map['district'] as String?,
      city:      (map['city']     as String?) ?? '',
      country:   (map['country']  as String?) ?? 'Saudi Arabia',
      notes:      map['notes']    as String?,
      latitude:  _toDouble(map['latitude'],  nullable: true),
      longitude: _toDouble(map['longitude'], nullable: true),
    );
  }

  Map<String, dynamic> toMap() => {
    'street':   street,
    if (district  != null) 'district':  district,
    'city':     city,
    'country':  country,
    if (notes     != null) 'notes':     notes,
    if (latitude  != null) 'latitude':  latitude,
    if (longitude != null) 'longitude': longitude,
  };

  String get singleLine =>
      [street, district, city].where((s) => s != null && s!.isNotEmpty).join(', ');
}

// =============================================================================
// OrderStatusEvent — one entry in the immutable status_history array
// =============================================================================

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime    timestamp;
  final String?     actorId;   // uid of whoever triggered the change
  final String?     note;

  const OrderStatusEvent({
    required this.status,
    required this.timestamp,
    this.actorId,
    this.note,
  });

  factory OrderStatusEvent.fromMap(Map<String, dynamic> map) {
    DateTime ts = DateTime.now();
    final raw = map['timestamp'];
    if (raw is Timestamp)  ts = raw.toDate();
    if (raw is String)     ts = DateTime.tryParse(raw) ?? ts;

    return OrderStatusEvent(
      status:    OrderStatus.fromString(map['status'] as String?),
      timestamp: ts,
      actorId:    map['actorId'] as String?,
      note:       map['note']    as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'status':    status.firestoreValue,
    'timestamp': Timestamp.fromDate(timestamp),
    if (actorId != null) 'actorId': actorId,
    if (note    != null) 'note':    note,
  };
}

// =============================================================================
// OrderModel — the main document
// =============================================================================

/// Immutable representation of a Tayyeb-Go order stored in Firestore.
///
/// Firestore schema  (/orders/{orderId}):
/// ```
/// {
///   "customerId":      "user-uid",
///   "customerName":    "John Customer",
///   "customerPhone":   "+966...",           // nullable
///   "vendorId":        "vendor-doc-id",
///   "vendorName":      "Al Mandi",
///   "vendorPhone":     "+966...",           // nullable
///   "driverId":        "driver-uid",        // nullable until assigned
///   "driverName":      "Khaled Driver",     // nullable
///   "status":          "pending",
///   "paymentMethod":   "cash",
///   "items":           [ ... OrderItem maps ],
///   "deliveryAddress": { ... DeliveryAddress map },
///   "subtotal":        90.00,
///   "deliveryFee":     10.00,
///   "discount":        5.00,
///   "taxAmount":       0.00,
///   "totalAmount":     95.00,
///   "loyaltyPointsUsed":   0,
///   "loyaltyPointsEarned": 9,
///   "estimatedDeliveryMinutes": 30,    // nullable
///   "customerNote":    "Ring the bell", // nullable
///   "statusHistory":   [ ... OrderStatusEvent maps ],
///   "isPaid":          false,
///   "isRated":         false,
///   "rating":          null,            // nullable int 1-5
///   "createdAt":       Timestamp,
///   "updatedAt":       Timestamp,
///   "acceptedAt":      Timestamp,       // nullable
///   "deliveredAt":     Timestamp        // nullable
/// }
/// ```
class OrderModel {
  final String  id;

  // ── Participants ───────────────────────────────────────────────────────────
  final String  customerId;
  final String  customerName;
  final String? customerPhone;

  final String  vendorId;
  final String  vendorName;
  final String? vendorPhone;

  final String? driverId;
  final String? driverName;

  // ── Status ─────────────────────────────────────────────────────────────────
  final OrderStatus status;
  final List<OrderStatusEvent> statusHistory;

  // ── Payment ────────────────────────────────────────────────────────────────
  final OrderPaymentMethod paymentMethod;
  final bool               isPaid;

  // ── Items ──────────────────────────────────────────────────────────────────
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;

  // ── Pricing ────────────────────────────────────────────────────────────────
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double taxAmount;
  final double totalAmount;

  // ── Loyalty ────────────────────────────────────────────────────────────────
  final int loyaltyPointsUsed;
  final int loyaltyPointsEarned;

  // ── Misc ───────────────────────────────────────────────────────────────────
  final int?    estimatedDeliveryMinutes;
  final String? customerNote;
  final bool    isRated;
  final int?    rating;             // 1–5

  // ── Timestamps ─────────────────────────────────────────────────────────────
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.vendorId,
    required this.vendorName,
    this.vendorPhone,
    this.driverId,
    this.driverName,
    required this.status,
    this.statusHistory = const [],
    required this.paymentMethod,
    this.isPaid = false,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    this.deliveryFee  = 0.0,
    this.discount     = 0.0,
    this.taxAmount    = 0.0,
    required this.totalAmount,
    this.loyaltyPointsUsed   = 0,
    this.loyaltyPointsEarned = 0,
    this.estimatedDeliveryMinutes,
    this.customerNote,
    this.isRated    = false,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.deliveredAt,
  });

  // ── Convenience ────────────────────────────────────────────────────────────

  bool get isActive   => status.isActive;
  bool get isTerminal => status.isTerminal;
  int  get itemCount  => items.fold(0, (sum, i) => sum + i.quantity);

  // ── Firestore deserialization ─────────────────────────────────────────────

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? _ts(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String)    return DateTime.tryParse(value);
      return null;
    }

    // items array
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromMap)
            .toList()
        : <OrderItem>[];

    // statusHistory array
    final rawHistory = data['statusHistory'];
    final statusHistory = rawHistory is List
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(OrderStatusEvent.fromMap)
            .toList()
        : <OrderStatusEvent>[];

    // deliveryAddress map
    final rawAddress = data['deliveryAddress'];
    final deliveryAddress = rawAddress is Map<String, dynamic>
        ? DeliveryAddress.fromMap(rawAddress)
        : const DeliveryAddress(street: '', city: '');

    return OrderModel(
      id:               doc.id,
      customerId:      (data['customerId']    as String?) ?? '',
      customerName:    (data['customerName']  as String?) ?? '',
      customerPhone:    data['customerPhone'] as String?,
      vendorId:        (data['vendorId']      as String?) ?? '',
      vendorName:      (data['vendorName']    as String?) ?? '',
      vendorPhone:      data['vendorPhone']   as String?,
      driverId:         data['driverId']      as String?,
      driverName:       data['driverName']    as String?,
      status:          OrderStatus.fromString(data['status'] as String?),
      statusHistory:   statusHistory,
      paymentMethod:   OrderPaymentMethod.fromString(data['paymentMethod'] as String?),
      isPaid:          (data['isPaid']        as bool?) ?? false,
      items:           items,
      deliveryAddress: deliveryAddress,
      subtotal:        _toDouble(data['subtotal']),
      deliveryFee:     _toDouble(data['deliveryFee']),
      discount:        _toDouble(data['discount']),
      taxAmount:       _toDouble(data['taxAmount']),
      totalAmount:     _toDouble(data['totalAmount']),
      loyaltyPointsUsed:   (data['loyaltyPointsUsed']   as int?) ?? 0,
      loyaltyPointsEarned: (data['loyaltyPointsEarned'] as int?) ?? 0,
      estimatedDeliveryMinutes: data['estimatedDeliveryMinutes'] as int?,
      customerNote:     data['customerNote']  as String?,
      isRated:         (data['isRated']       as bool?)   ?? false,
      rating:           data['rating']        as int?,
      createdAt:       _ts(data['createdAt']),
      updatedAt:       _ts(data['updatedAt']),
      acceptedAt:      _ts(data['acceptedAt']),
      deliveredAt:     _ts(data['deliveredAt']),
    );
  }

  // ── JSON deserialization (from API) ───────────────────────────────────────

  factory OrderModel.fromJson(Map<String, dynamic> data) {
    DateTime? _ts(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromMap)
            .toList()
        : <OrderItem>[];

    final rawHistory = data['statusHistory'];
    final statusHistory = rawHistory is List
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(OrderStatusEvent.fromMap)
            .toList()
        : <OrderStatusEvent>[];

    final rawAddress = data['deliveryAddress'];
    final deliveryAddress = rawAddress is Map<String, dynamic>
        ? DeliveryAddress.fromMap(rawAddress)
        : const DeliveryAddress(street: '', city: '');

    return OrderModel(
      id: (data['id'] as String?) ?? '',
      customerId: (data['customerId'] as String?) ?? '',
      customerName: (data['customerName'] as String?) ?? '',
      customerPhone: data['customerPhone'] as String?,
      vendorId: (data['vendorId'] as String?) ?? '',
      vendorName: (data['vendorName'] as String?) ?? '',
      vendorPhone: data['vendorPhone'] as String?,
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
      status: OrderStatus.fromString(data['status'] as String?),
      statusHistory: statusHistory,
      paymentMethod: OrderPaymentMethod.fromString(data['paymentMethod'] as String?),
      isPaid: (data['isPaid'] as bool?) ?? false,
      items: items,
      deliveryAddress: deliveryAddress,
      subtotal: _toDouble(data['subtotal']),
      deliveryFee: _toDouble(data['deliveryFee']),
      discount: _toDouble(data['discount']),
      taxAmount: _toDouble(data['taxAmount']),
      totalAmount: _toDouble(data['totalAmount']),
      loyaltyPointsUsed: (data['loyaltyPointsUsed'] as int?) ?? 0,
      loyaltyPointsEarned: (data['loyaltyPointsEarned'] as int?) ?? 0,
      estimatedDeliveryMinutes: data['estimatedDeliveryMinutes'] as int?,
      customerNote: data['customerNote'] as String?,
      isRated: (data['isRated'] as bool?) ?? false,
      rating: data['rating'] as int?,
      createdAt: _ts(data['createdAt']),
      updatedAt: _ts(data['updatedAt']),
      acceptedAt: _ts(data['acceptedAt']),
      deliveredAt: _ts(data['deliveredAt']),
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'customerId':    customerId,
      'customerName':  customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'vendorId':      vendorId,
      'vendorName':    vendorName,
      if (vendorPhone != null)   'vendorPhone':   vendorPhone,
      if (driverId    != null)   'driverId':      driverId,
      if (driverName  != null)   'driverName':    driverName,
      'status':        status.firestoreValue,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'paymentMethod': paymentMethod.firestoreValue,
      'isPaid':        isPaid,
      'items':         items.map((i) => i.toMap()).toList(),
      'deliveryAddress': deliveryAddress.toMap(),
      'subtotal':      subtotal,
      'deliveryFee':   deliveryFee,
      'discount':      discount,
      'taxAmount':     taxAmount,
      'totalAmount':   totalAmount,
      'loyaltyPointsUsed':   loyaltyPointsUsed,
      'loyaltyPointsEarned': loyaltyPointsEarned,
      if (estimatedDeliveryMinutes != null)
        'estimatedDeliveryMinutes': estimatedDeliveryMinutes,
      if (customerNote != null) 'customerNote': customerNote,
      'isRated': isRated,
      if (rating != null) 'rating': rating,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (acceptedAt  != null) 'acceptedAt':  Timestamp.fromDate(acceptedAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  OrderModel copyWith({
    String?              id,
    String?              customerId,
    String?              customerName,
    String?              customerPhone,
    String?              vendorId,
    String?              vendorName,
    String?              vendorPhone,
    String?              driverId,
    String?              driverName,
    OrderStatus?         status,
    List<OrderStatusEvent>? statusHistory,
    OrderPaymentMethod?  paymentMethod,
    bool?                isPaid,
    List<OrderItem>?     items,
    DeliveryAddress?     deliveryAddress,
    double?              subtotal,
    double?              deliveryFee,
    double?              discount,
    double?              taxAmount,
    double?              totalAmount,
    int?                 loyaltyPointsUsed,
    int?                 loyaltyPointsEarned,
    int?                 estimatedDeliveryMinutes,
    String?              customerNote,
    bool?                isRated,
    int?                 rating,
    DateTime?            createdAt,
    DateTime?            updatedAt,
    DateTime?            acceptedAt,
    DateTime?            deliveredAt,
  }) {
    return OrderModel(
      id:              id              ?? this.id,
      customerId:      customerId      ?? this.customerId,
      customerName:    customerName    ?? this.customerName,
      customerPhone:   customerPhone   ?? this.customerPhone,
      vendorId:        vendorId        ?? this.vendorId,
      vendorName:      vendorName      ?? this.vendorName,
      vendorPhone:     vendorPhone     ?? this.vendorPhone,
      driverId:        driverId        ?? this.driverId,
      driverName:      driverName      ?? this.driverName,
      status:          status          ?? this.status,
      statusHistory:   statusHistory   ?? this.statusHistory,
      paymentMethod:   paymentMethod   ?? this.paymentMethod,
      isPaid:          isPaid          ?? this.isPaid,
      items:           items           ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      subtotal:        subtotal        ?? this.subtotal,
      deliveryFee:     deliveryFee     ?? this.deliveryFee,
      discount:        discount        ?? this.discount,
      taxAmount:       taxAmount       ?? this.taxAmount,
      totalAmount:     totalAmount     ?? this.totalAmount,
      loyaltyPointsUsed:   loyaltyPointsUsed   ?? this.loyaltyPointsUsed,
      loyaltyPointsEarned: loyaltyPointsEarned ?? this.loyaltyPointsEarned,
      estimatedDeliveryMinutes:
          estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      customerNote:  customerNote  ?? this.customerNote,
      isRated:       isRated       ?? this.isRated,
      rating:        rating        ?? this.rating,
      createdAt:     createdAt     ?? this.createdAt,
      updatedAt:     updatedAt     ?? this.updatedAt,
      acceptedAt:    acceptedAt    ?? this.acceptedAt,
      deliveredAt:   deliveredAt   ?? this.deliveredAt,
    );
  }

  @override
  String toString() =>
      'OrderModel(id: $id, status: ${status.firestoreValue}, total: $totalAmount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// Private helpers
// =============================================================================

/// Safely coerces a Firestore numeric value to [double].
/// Handles int, double, and String representations.
double _toDouble(dynamic value, {bool nullable = false}) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int)    return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
