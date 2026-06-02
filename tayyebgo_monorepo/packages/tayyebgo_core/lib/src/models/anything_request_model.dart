import 'package:cloud_firestore/cloud_firestore.dart';

enum AnythingRequestStatus {
  pending,
  accepted,
  shopping,
  enRoute,
  delivered,
  cancelled;

  static AnythingRequestStatus fromString(String? v) => switch (v) {
        'pending' => AnythingRequestStatus.pending,
        'accepted' => AnythingRequestStatus.accepted,
        'shopping' => AnythingRequestStatus.shopping,
        'en_route' => AnythingRequestStatus.enRoute,
        'delivered' => AnythingRequestStatus.delivered,
        'cancelled' => AnythingRequestStatus.cancelled,
        _ => AnythingRequestStatus.pending,
      };

  String get firestoreValue => name;

  bool get isActive => this != delivered && this != cancelled;
  bool get isTerminal => this == delivered || this == cancelled;
}

class AnythingRequestItem {
  final String name;
  final int quantity;
  final String? note;

  const AnythingRequestItem({
    required this.name,
    this.quantity = 1,
    this.note,
  });

  factory AnythingRequestItem.fromMap(Map<String, dynamic> d) =>
      AnythingRequestItem(
        name: d['name'] as String? ?? '',
        quantity: (d['quantity'] as num?)?.toInt() ?? 1,
        note: d['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        if (note != null) 'note': note,
      };
}

class AnythingRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String storeName;
  final List<AnythingRequestItem> items;
  final double budget;
  final String? photoUrl;
  final String instructions;
  final AnythingRequestStatus status;
  final String? driverId;
  final String? driverName;
  final double? driverLatitude;
  final double? driverLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String dropoffAddress;
  final String? chatThreadId;
  final double deliveryFee;
  final double totalCost;
  final bool isPaid;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const AnythingRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.storeName,
    this.items = const [],
    this.budget = 0,
    this.photoUrl,
    this.instructions = '',
    this.status = AnythingRequestStatus.pending,
    this.driverId,
    this.driverName,
    this.driverLatitude,
    this.driverLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.dropoffAddress = '',
    this.chatThreadId,
    this.deliveryFee = 0,
    this.totalCost = 0,
    this.isPaid = false,
    this.paymentMethod = 'cash',
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.deliveredAt,
  });

  bool get hasDriver => driverId != null;
  bool get hasDriverLocation => driverLatitude != null && driverLongitude != null;
  bool get hasDropoffLocation => dropoffLatitude != null && dropoffLongitude != null;

  factory AnythingRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AnythingRequestModel(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerPhone: d['customerPhone'] as String?,
      storeName: d['storeName'] as String? ?? '',
      items: (d['items'] as List<dynamic>?)
              ?.map((i) => AnythingRequestItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      budget: (d['budget'] as num?)?.toDouble() ?? 0,
      photoUrl: d['photoUrl'] as String?,
      instructions: d['instructions'] as String? ?? '',
      status: AnythingRequestStatus.fromString(d['status'] as String?),
      driverId: d['driverId'] as String?,
      driverName: d['driverName'] as String?,
      driverLatitude: (d['driverLatitude'] as num?)?.toDouble(),
      driverLongitude: (d['driverLongitude'] as num?)?.toDouble(),
      dropoffLatitude: (d['dropoffLatitude'] as num?)?.toDouble(),
      dropoffLongitude: (d['dropoffLongitude'] as num?)?.toDouble(),
      dropoffAddress: d['dropoffAddress'] as String? ?? '',
      chatThreadId: d['chatThreadId'] as String?,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0,
      totalCost: (d['totalCost'] as num?)?.toDouble() ?? 0,
      isPaid: d['isPaid'] as bool? ?? false,
      paymentMethod: d['paymentMethod'] as String? ?? 'cash',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'customerId': customerId,
        'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        'storeName': storeName,
        'items': items.map((i) => i.toMap()).toList(),
        'budget': budget,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'instructions': instructions,
        'status': status.firestoreValue,
        if (driverId != null) 'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (driverLatitude != null) 'driverLatitude': driverLatitude,
        if (driverLongitude != null) 'driverLongitude': driverLongitude,
        if (dropoffLatitude != null) 'dropoffLatitude': dropoffLatitude,
        if (dropoffLongitude != null) 'dropoffLongitude': dropoffLongitude,
        'dropoffAddress': dropoffAddress,
        if (chatThreadId != null) 'chatThreadId': chatThreadId,
        'deliveryFee': deliveryFee,
        'totalCost': totalCost,
        'isPaid': isPaid,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  AnythingRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? storeName,
    List<AnythingRequestItem>? items,
    double? budget,
    String? photoUrl,
    String? instructions,
    AnythingRequestStatus? status,
    String? driverId,
    String? driverName,
    double? driverLatitude,
    double? driverLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    String? chatThreadId,
    double? deliveryFee,
    double? totalCost,
    bool? isPaid,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? deliveredAt,
  }) =>
      AnythingRequestModel(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        storeName: storeName ?? this.storeName,
        items: items ?? this.items,
        budget: budget ?? this.budget,
        photoUrl: photoUrl ?? this.photoUrl,
        instructions: instructions ?? this.instructions,
        status: status ?? this.status,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        driverLatitude: driverLatitude ?? this.driverLatitude,
        driverLongitude: driverLongitude ?? this.driverLongitude,
        dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
        dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
        dropoffAddress: dropoffAddress ?? this.dropoffAddress,
        chatThreadId: chatThreadId ?? this.chatThreadId,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        totalCost: totalCost ?? this.totalCost,
        isPaid: isPaid ?? this.isPaid,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );
}
