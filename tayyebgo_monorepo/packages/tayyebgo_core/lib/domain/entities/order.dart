import '../enums/order_status.dart';
import '../enums/fulfillment_type.dart';
import '../value_objects/money.dart';
import '../value_objects/address.dart';
import '../value_objects/geo_location.dart';

class OrderItem {
  final String name;
  final Money price;
  final int quantity;
  final List<String> modifiers;

  const OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.modifiers = const [],
  });

  Money get total => price * quantity;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price.amountInCents,
        'quantity': quantity,
        'modifiers': modifiers,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        name: m['name'] as String? ?? '',
        price: Money((m['price'] as num?)?.toInt() ?? 0),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        modifiers: (m['modifiers'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class StatusTransition {
  final OrderStatus fromStatus;
  final OrderStatus toStatus;
  final DateTime timestamp;
  final String actorId;
  final GeoLocation? location;
  final String? note;

  const StatusTransition({
    required this.fromStatus,
    required this.toStatus,
    required this.timestamp,
    required this.actorId,
    this.location,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'from': fromStatus.value,
        'to': toStatus.value,
        'timestamp': timestamp.toIso8601String(),
        'actorId': actorId,
        if (location != null) ...location!.toMap(),
        if (note != null) 'note': note,
      };

  factory StatusTransition.fromMap(Map<String, dynamic> m) => StatusTransition(
        fromStatus: OrderStatus.fromValue(m['from'] as String? ?? ''),
        toStatus: OrderStatus.fromValue(m['to'] as String? ?? ''),
        timestamp: DateTime.parse(m['timestamp'] as String),
        actorId: m['actorId'] as String? ?? '',
        location: m['latitude'] != null
            ? GeoLocation.fromMap(m)
            : null,
        note: m['note'] as String?,
      );
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String restaurantId;
  final String restaurantName;
  final OrderStatus status;
  final List<OrderItem> items;
  final Money subtotal;
  final Money deliveryFee;
  final Money tax;
  final Money totalAmount;
  final FulfillmentType fulfillmentType;
  final Address? deliveryAddress;
  final GeoLocation? restaurantLocation;
  final String? driverId;
  final String? driverName;
  final List<StatusTransition> statusHistory;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String? rejectionReason;
  final String? promoCode;
  final Money? discount;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.customerEmail,
    required this.restaurantId,
    required this.restaurantName,
    this.status = OrderStatus.placed,
    this.items = const [],
    this.subtotal = const Money(0),
    this.deliveryFee = const Money(0),
    this.tax = const Money(0),
    this.totalAmount = const Money(0),
    this.fulfillmentType = FulfillmentType.delivery,
    this.deliveryAddress,
    this.restaurantLocation,
    this.driverId,
    this.driverName,
    this.statusHistory = const [],
    required this.createdAt,
    this.acceptedAt,
    this.readyAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.rejectionReason,
    this.promoCode,
    this.discount,
  });

  bool get isActive => status.isActive;
  bool get isDelivery => fulfillmentType == FulfillmentType.delivery;

  Order copyWith({OrderStatus? status, List<StatusTransition>? statusHistory}) =>
      Order(
        id: id,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        status: status ?? this.status,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        tax: tax,
        totalAmount: totalAmount,
        fulfillmentType: fulfillmentType,
        deliveryAddress: deliveryAddress,
        restaurantLocation: restaurantLocation,
        driverId: driverId,
        driverName: driverName,
        statusHistory: statusHistory ?? this.statusHistory,
        createdAt: createdAt,
        acceptedAt: acceptedAt,
        readyAt: readyAt,
        dispatchedAt: dispatchedAt,
        deliveredAt: deliveredAt,
        rejectionReason: rejectionReason,
        promoCode: promoCode,
        discount: discount,
      );

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'status': status.value,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal.amountInCents,
        'deliveryFee': deliveryFee.amountInCents,
        'tax': tax.amountInCents,
        'totalAmount': totalAmount.amountInCents,
        'fulfillmentType': fulfillmentType.value,
        if (deliveryAddress != null) ...deliveryAddress!.toMap(),
        if (restaurantLocation != null)
          'restaurantLocation': restaurantLocation!.toMap(),
        'driverId': driverId,
        'driverName': driverName,
        'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'dispatchedAt': dispatchedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
        'promoCode': promoCode,
        'discount': discount?.amountInCents,
      };

  factory Order.fromMap(Map<String, dynamic> m, String docId) => Order(
        id: docId,
        customerId: m['customerId'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        customerPhone: m['customerPhone'] as String? ?? '',
        customerEmail: m['customerEmail'] as String?,
        restaurantId: m['restaurantId'] as String? ?? '',
        restaurantName: m['restaurantName'] as String? ?? '',
        status: OrderStatus.fromValue(m['status'] as String? ?? ''),
        items: (m['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: Money((m['subtotal'] as num?)?.toInt() ?? 0),
        deliveryFee: Money((m['deliveryFee'] as num?)?.toInt() ?? 0),
        tax: Money((m['tax'] as num?)?.toInt() ?? 0),
        totalAmount: Money((m['totalAmount'] as num?)?.toInt() ?? 0),
        fulfillmentType:
            FulfillmentType.fromValue(m['fulfillmentType'] as String? ?? ''),
        deliveryAddress: m['street'] != null
            ? Address.fromMap(m)
            : null,
        restaurantLocation: m['restaurantLocation'] != null
            ? GeoLocation.fromMap(
                m['restaurantLocation'] as Map<String, dynamic>)
            : null,
        driverId: m['driverId'] as String?,
        driverName: m['driverName'] as String?,
        statusHistory: (m['statusHistory'] as List<dynamic>?)
                ?.map((e) =>
                    StatusTransition.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
        acceptedAt:
            DateTime.tryParse(m['acceptedAt'] as String? ?? ''),
        readyAt: DateTime.tryParse(m['readyAt'] as String? ?? ''),
        dispatchedAt:
            DateTime.tryParse(m['dispatchedAt'] as String? ?? ''),
        deliveredAt:
            DateTime.tryParse(m['deliveredAt'] as String? ?? ''),
        rejectionReason: m['rejectionReason'] as String?,
        promoCode: m['promoCode'] as String?,
        discount: m['discount'] != null
            ? Money((m['discount'] as num).toInt())
            : null,
      );
}
