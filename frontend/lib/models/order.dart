import 'dart:convert';
import 'user.dart';
import 'product.dart';

enum OrderStatus {
  pending,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  refundRequested,
  refunded,
}

enum PaymentMethod {
  cash,
  card,
  wallet,
  applePay,
  googlePay,
}

class Order {
  final String id;
  final String orderNumber;
  final User customer;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String currency;
  final double exchangeRate;
  OrderStatus status;
  final String? driverId;
  final Driver? assignedDriver;
  final String? adminNotes;
  final DeliveryAddress deliveryAddress;
  final DeliveryTimeSlot? timeSlot;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? proofOfDeliveryUrl;
  final String? customerSignature;
  final List<OrderStatusChange> statusHistory;
  final String? specialInstructions;
  final bool isHighPriority;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    this.currency = 'USD',
    this.exchangeRate = 1.0,
    required this.status,
    this.driverId,
    this.assignedDriver,
    this.adminNotes,
    required this.deliveryAddress,
    this.timeSlot,
    required this.paymentMethod,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.proofOfDeliveryUrl,
    this.customerSignature,
    this.statusHistory = const [],
    this.specialInstructions,
    this.isHighPriority = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      customer: json['customer'] is Map
          ? User.fromJson(json['customer'])
          : User(id: 0, name: 'Unknown', email: '', phone: ''),
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : [],
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'USD',
      exchangeRate: double.tryParse(json['exchange_rate']?.toString() ?? '1') ?? 1,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      driverId: json['driver_id'],
      assignedDriver: json['assigned_driver'] != null
          ? Driver.fromJson(json['assigned_driver'])
          : null,
      adminNotes: json['admin_notes'],
      deliveryAddress: json['delivery_address'] != null
          ? DeliveryAddress.fromJson(json['delivery_address'])
          : DeliveryAddress(
              id: '',
              label: 'Home',
              address: '',
              lat: 0,
              lng: 0,
            ),
      timeSlot: json['time_slot'] != null
          ? DeliveryTimeSlot.fromJson(json['time_slot'])
          : null,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      proofOfDeliveryUrl: json['proof_of_delivery_url'],
      customerSignature: json['customer_signature'],
      statusHistory: json['status_history'] != null
          ? (json['status_history'] as List)
              .map((e) => OrderStatusChange.fromJson(e))
              .toList()
          : [],
      specialInstructions: json['special_instructions'],
      isHighPriority: json['is_high_priority'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer': customer.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total': total,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'status': status.name,
      'driver_id': driverId,
      'assigned_driver': assignedDriver?.toJson(),
      'admin_notes': adminNotes,
      'delivery_address': deliveryAddress.toJson(),
      'time_slot': timeSlot?.toJson(),
      'payment_method': paymentMethod.name,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'proof_of_delivery_url': proofOfDeliveryUrl,
      'customer_signature': customerSignature,
      'status_history': statusHistory.map((e) => e.toJson()).toList(),
      'special_instructions': specialInstructions,
      'is_high_priority': isHighPriority,
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    User? customer,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? total,
    String? currency,
    double? exchangeRate,
    OrderStatus? status,
    String? driverId,
    Driver? assignedDriver,
    String? adminNotes,
    DeliveryAddress? deliveryAddress,
    DeliveryTimeSlot? timeSlot,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? proofOfDeliveryUrl,
    String? customerSignature,
    List<OrderStatusChange>? statusHistory,
    String? specialInstructions,
    bool? isHighPriority,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      adminNotes: adminNotes ?? this.adminNotes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      timeSlot: timeSlot ?? this.timeSlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      proofOfDeliveryUrl: proofOfDeliveryUrl ?? this.proofOfDeliveryUrl,
      customerSignature: customerSignature ?? this.customerSignature,
      statusHistory: statusHistory ?? this.statusHistory,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isHighPriority: isHighPriority ?? this.isHighPriority,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refundRequested:
        return 'Refund Requested';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  
  String get formattedTotalSYP => '${(total * exchangeRate).toStringAsFixed(0)} SYP';

  double get totalInSYP => total * exchangeRate;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      product: json['product'] is Map
          ? Product.fromJson(json['product'])
          : Product(
              id: json['product_id'] ?? 0,
              name: json['product_name'] ?? '',
              price: 0,
              stockQuantity: 0,
              category: '',
            ),
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
    };
  }
}

class DeliveryAddress {
  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  final String? instructions;
  final bool isDefault;

  DeliveryAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    this.instructions,
    this.isDefault = false,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Home',
      address: json['address'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      lng: double.tryParse(json['lng']?.toString() ?? '0') ?? 0,
      instructions: json['instructions'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'lat': lat,
      'lng': lng,
      'instructions': instructions,
      'is_default': isDefault,
    };
  }
}

class DeliveryTimeSlot {
  final String id;
  final String label;
  final DateTime startTime;
  final DateTime endTime;
  final double additionalFee;

  DeliveryTimeSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.additionalFee = 0,
  });

  factory DeliveryTimeSlot.fromJson(Map<String, dynamic> json) {
    return DeliveryTimeSlot(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      additionalFee:
          double.tryParse(json['additional_fee']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'additional_fee': additionalFee,
    };
  }

  String get timeRangeDisplay =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
}

class OrderStatusChange {
  final OrderStatus status;
  final String changedBy;
  final String? note;
  final DateTime timestamp;

  OrderStatusChange({
    required this.status,
    required this.changedBy,
    this.note,
    required this.timestamp,
  });

  factory OrderStatusChange.fromJson(Map<String, dynamic> json) {
    return OrderStatusChange(
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      changedBy: json['changed_by'] ?? 'system',
      note: json['note'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'changed_by': changedBy,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Driver {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final double lat;
  final double lng;
  final double rating;
  final int totalDeliveries;
  final bool isOnline;
  final String? currentOrderId;
  final String vehicleType;
  final String licenseNumber;
  final String? fcmToken;
  final DateTime? lastActiveAt;
  final DriverEarnings? earnings;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.lat,
    required this.lng,
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.isOnline = false,
    this.currentOrderId,
    this.vehicleType = 'motorcycle',
    this.licenseNumber = '',
    this.fcmToken,
    this.lastActiveAt,
    this.earnings,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photo_url'],
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      lng: double.tryParse(json['lng']?.toString() ?? '0') ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      totalDeliveries: json['total_deliveries'] ?? 0,
      isOnline: json['is_online'] ?? false,
      currentOrderId: json['current_order_id'],
      vehicleType: json['vehicle_type'] ?? 'motorcycle',
      licenseNumber: json['license_number'] ?? '',
      fcmToken: json['fcm_token'],
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : null,
      earnings: json['earnings'] != null
          ? DriverEarnings.fromJson(json['earnings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'is_online': isOnline,
      'current_order_id': currentOrderId,
      'vehicle_type': vehicleType,
      'license_number': licenseNumber,
      'fcm_token': fcmToken,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'earnings': earnings?.toJson(),
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    double? lat,
    double? lng,
    double? rating,
    int? totalDeliveries,
    bool? isOnline,
    String? currentOrderId,
    String? vehicleType,
    String? licenseNumber,
    String? fcmToken,
    DateTime? lastActiveAt,
    DriverEarnings? earnings,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isOnline: isOnline ?? this.isOnline,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      fcmToken: fcmToken ?? this.fcmToken,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      earnings: earnings ?? this.earnings,
    );
  }

  bool get isAvailable => isOnline && currentOrderId == null;

  double distanceTo(double destLat, double destLng) {
    const double earthRadius = 6371;
    final double dLat = _toRadians(destLat - lat);
    final double dLng = _toRadians(destLng - lng);
    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat)) *
            _cos(_toRadians(destLat)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorCos(x);
  double _sqrt(double x) => _babylonianSqrt(x);
  double _atan2(double y, double x) => _approximateAtan2(y, x);

  double _taylorSin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  double _taylorCos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  double _babylonianSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approximateAtan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5707963267948966 : -1.5707963267948966;
    double atan = _taylorAtan(y / x);
    if (x < 0) {
      return y >= 0 ? atan + 3.141592653589793 : atan - 3.141592653589793;
    }
    return atan;
  }

  double _taylorAtan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267948966 - _taylorAtan(1 / x);
    }
    double result = x;
    double term = x;
    for (int n = 1; n <= 20; n++) {
      term *= -x * x;
      result += term / (2 * n + 1);
    }
    return result;
  }
}

class DriverEarnings {
  final double today;
  final double week;
  final double month;
  final double total;
  final int pendingPayouts;
  final double pendingAmount;

  DriverEarnings({
    this.today = 0,
    this.week = 0,
    this.month = 0,
    this.total = 0,
    this.pendingPayouts = 0,
    this.pendingAmount = 0,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      today: double.tryParse(json['today']?.toString() ?? '0') ?? 0,
      week: double.tryParse(json['week']?.toString() ?? '0') ?? 0,
      month: double.tryParse(json['month']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      pendingPayouts: json['pending_payouts'] ?? 0,
      pendingAmount:
          double.tryParse(json['pending_amount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today': today,
      'week': week,
      'month': month,
      'total': total,
      'pending_payouts': pendingPayouts,
      'pending_amount': pendingAmount,
    };
  }
}