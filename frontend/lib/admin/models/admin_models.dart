import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStore {
  final String id;
  final String name;
  final String businessType;
  final String? cuisine;
  final String phone;
  final String address;
  final double? lat;
  final double? lng;
  final bool isOpen;
  final bool isSuspended;
  final double rating;
  final int totalOrders;
  final double revenue;
  final double commissionDebt;
  final double commissionCeiling;
  final double commissionRate;
  final String deliveryMode;
  final bool fallbackEnabled;
  final int fallbackDelayMinutes;
  final String? subscriptionId;
  final String? logoUrl;
  final String? bannerUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final int orderCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminStore({
    required this.id,
    required this.name,
    this.businessType = 'Restaurant',
    this.cuisine,
    this.phone = '',
    this.address = '',
    this.lat,
    this.lng,
    this.isOpen = true,
    this.isSuspended = false,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.revenue = 0,
    this.commissionDebt = 0,
    this.commissionCeiling = 50000,
    this.commissionRate = 15,
    this.deliveryMode = 'platform',
    this.fallbackEnabled = true,
    this.fallbackDelayMinutes = 10,
    this.subscriptionId,
    this.logoUrl,
    this.bannerUrl,
    this.primaryColor,
    this.secondaryColor,
    this.orderCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminStore.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AdminStore(
      id: doc.id,
      name: d['name'] ?? '',
      businessType: d['businessType'] ?? d['type'] ?? 'Restaurant',
      cuisine: d['cuisine'],
      phone: d['phone'] ?? '',
      address: d['address'] ?? '',
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      isOpen: d['isOpen'] ?? true,
      isSuspended: d['isSuspended'] ?? false,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: d['totalOrders'] ?? 0,
      revenue: (d['revenue'] as num?)?.toDouble() ?? 0,
      commissionDebt: (d['commissionDebt'] as num?)?.toDouble() ?? 0,
      commissionCeiling: (d['commissionCeiling'] as num?)?.toDouble() ?? 50000,
      commissionRate: (d['commissionRate'] as num?)?.toDouble() ?? 15,
      deliveryMode: d['deliveryMode'] ?? 'platform',
      fallbackEnabled: d['fallbackEnabled'] ?? true,
      fallbackDelayMinutes: d['fallbackDelayMinutes'] ?? 10,
      subscriptionId: d['subscriptionId'],
      logoUrl: d['logoUrl'],
      bannerUrl: d['bannerUrl'],
      primaryColor: d['primaryColor'],
      secondaryColor: d['secondaryColor'],
      orderCount: d['orderCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'businessType': businessType,
    'cuisine': cuisine,
    'phone': phone,
    'address': address,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    'isOpen': isOpen,
    'isSuspended': isSuspended,
    'rating': rating,
    'totalOrders': totalOrders,
    'revenue': revenue,
    'commissionDebt': commissionDebt,
    'commissionCeiling': commissionCeiling,
    'commissionRate': commissionRate,
    'deliveryMode': deliveryMode,
    'fallbackEnabled': fallbackEnabled,
    'fallbackDelayMinutes': fallbackDelayMinutes,
    if (subscriptionId != null) 'subscriptionId': subscriptionId,
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (bannerUrl != null) 'bannerUrl': bannerUrl,
    if (primaryColor != null) 'primaryColor': primaryColor,
    if (secondaryColor != null) 'secondaryColor': secondaryColor,
    'orderCount': orderCount,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

enum DriverStatus { online, offline, busy, suspended }

class AdminDriver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DriverStatus status;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? currentLat;
  final double? currentLng;
  final double? heading;
  final String driverType;
  final String? storeId;
  final String? storeName;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double rating;
  final double walletBalance;
  final double totalEarnings;
  final String? subscriptionId;
  final int subscriptionOrdersRemaining;
  final DateTime? subscriptionExpiresAt;
  final bool isVerified;
  final String? idDocumentUrl;
  final String? licenseDocumentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminDriver({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.status = DriverStatus.offline,
    this.vehicleType,
    this.vehiclePlate,
    this.currentLat,
    this.currentLng,
    this.heading,
    this.driverType = 'platform',
    this.storeId,
    this.storeName,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.rating = 0.0,
    this.walletBalance = 0,
    this.totalEarnings = 0,
    this.subscriptionId,
    this.subscriptionOrdersRemaining = 0,
    this.subscriptionExpiresAt,
    this.isVerified = false,
    this.idDocumentUrl,
    this.licenseDocumentUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminDriver.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    DriverStatus parseStatus(String? s) {
      switch (s) {
        case 'online': return DriverStatus.online;
        case 'offline': return DriverStatus.offline;
        case 'busy': return DriverStatus.busy;
        case 'suspended': return DriverStatus.suspended;
        default: return d['isOnline'] == true ? DriverStatus.online : DriverStatus.offline;
      }
    }
    return AdminDriver(
      id: doc.id,
      name: d['name'] ?? d['displayName'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      status: parseStatus(d['status'] as String?),
      vehicleType: d['vehicleType'],
      vehiclePlate: d['vehiclePlate'],
      currentLat: (d['currentLat'] as num?)?.toDouble() ?? (d['lat'] as num?)?.toDouble(),
      currentLng: (d['currentLng'] as num?)?.toDouble() ?? (d['lng'] as num?)?.toDouble(),
      heading: (d['heading'] as num?)?.toDouble(),
      driverType: d['driverType'] ?? 'platform',
      storeId: d['storeId'],
      storeName: d['storeName'],
      totalOrders: d['totalOrders'] ?? 0,
      completedOrders: d['completedOrders'] ?? 0,
      cancelledOrders: d['cancelledOrders'] ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (d['walletBalance'] as num?)?.toDouble() ?? 0,
      totalEarnings: (d['totalEarnings'] as num?)?.toDouble() ?? 0,
      subscriptionId: d['subscriptionId'],
      subscriptionOrdersRemaining: d['subscriptionOrdersRemaining'] ?? 0,
      subscriptionExpiresAt: (d['subscriptionExpiresAt'] as Timestamp?)?.toDate(),
      isVerified: d['isVerified'] ?? false,
      idDocumentUrl: d['idDocumentUrl'],
      licenseDocumentUrl: d['licenseDocumentUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'status': status.name,
    if (vehicleType != null) 'vehicleType': vehicleType,
    if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
    if (currentLat != null) 'currentLat': currentLat,
    if (currentLng != null) 'currentLng': currentLng,
    if (heading != null) 'heading': heading,
    'driverType': driverType,
    if (storeId != null) 'storeId': storeId,
    if (storeName != null) 'storeName': storeName,
    'totalOrders': totalOrders,
    'completedOrders': completedOrders,
    'cancelledOrders': cancelledOrders,
    'rating': rating,
    'walletBalance': walletBalance,
    'totalEarnings': totalEarnings,
    if (subscriptionId != null) 'subscriptionId': subscriptionId,
    'subscriptionOrdersRemaining': subscriptionOrdersRemaining,
    if (subscriptionExpiresAt != null) 'subscriptionExpiresAt': Timestamp.fromDate(subscriptionExpiresAt!),
    'isVerified': isVerified,
    if (idDocumentUrl != null) 'idDocumentUrl': idDocumentUrl,
    if (licenseDocumentUrl != null) 'licenseDocumentUrl': licenseDocumentUrl,
    'isOnline': status == DriverStatus.online,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class AdminCampaign {
  final String id;
  final String name;
  final String type;
  final double value;
  final String targetAudience;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? description;
  final DateTime? createdAt;

  const AdminCampaign({
    required this.id,
    required this.name,
    this.type = 'percentage',
    this.value = 0,
    this.targetAudience = 'all',
    this.isActive = false,
    this.startsAt,
    this.endsAt,
    this.description,
    this.createdAt,
  });

  factory AdminCampaign.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AdminCampaign(
      id: doc.id,
      name: d['name'] ?? '',
      type: d['type'] ?? 'percentage',
      value: (d['value'] as num?)?.toDouble() ?? 0,
      targetAudience: d['targetAudience'] ?? 'all',
      isActive: d['isActive'] ?? false,
      startsAt: (d['startsAt'] as Timestamp?)?.toDate(),
      endsAt: (d['endsAt'] as Timestamp?)?.toDate(),
      description: d['description'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'value': value,
    'targetAudience': targetAudience,
    'isActive': isActive,
    if (startsAt != null) 'startsAt': Timestamp.fromDate(startsAt!),
    if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
    if (description != null) 'description': description,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class AdminNotification {
  final String id;
  final String title;
  final String body;
  final String targetRole;
  final bool sent;
  final DateTime? sentAt;
  final DateTime? createdAt;

  const AdminNotification({
    required this.id,
    required this.title,
    this.body = '',
    this.targetRole = 'all',
    this.sent = false,
    this.sentAt,
    this.createdAt,
  });

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AdminNotification(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      targetRole: d['targetRole'] ?? 'all',
      sent: d['sent'] ?? false,
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final String type;
  final String status;
  final String priority;
  final String? userId;
  final String? userName;
  final String? assignedTo;
  final List<String> messages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    this.description = '',
    this.type = 'complaint',
    this.status = 'open',
    this.priority = 'medium',
    this.userId,
    this.userName,
    this.assignedTo,
    this.messages = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SupportTicket(
      id: doc.id,
      subject: d['subject'] ?? '',
      description: d['description'] ?? '',
      type: d['type'] ?? 'complaint',
      status: d['status'] ?? 'open',
      priority: d['priority'] ?? 'medium',
      userId: d['userId'],
      userName: d['userName'],
      assignedTo: d['assignedTo'],
      messages: List<String>.from(d['messages'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'subject': subject,
    'description': description,
    'type': type,
    'status': status,
    'priority': priority,
    if (userId != null) 'userId': userId,
    if (userName != null) 'userName': userName,
    if (assignedTo != null) 'assignedTo': assignedTo,
    'messages': messages,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class ActivityLogEntry {
  final String id;
  final String type;
  final String text;
  final String? actorId;
  final String? actorName;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.id,
    required this.type,
    required this.text,
    this.actorId,
    this.actorName,
    required this.timestamp,
  });

  factory ActivityLogEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLogEntry(
      id: doc.id,
      type: d['type'] ?? 'system',
      text: d['text'] ?? '',
      actorId: d['actorId'],
      actorName: d['actorName'],
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Future<void> log({
    required String type,
    required String text,
    String? actorId,
    String? actorName,
  }) async {
    await FirebaseFirestore.instance.collection('activity_log').add({
      'type': type,
      'text': text,
      'actorId': actorId,
      'actorName': actorName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class SubscriptionPackage {
  final String id;
  final String name;
  final int orderLimit;
  final double price;
  final int durationDays;
  final bool isActive;
  final bool isDriverPackage;

  const SubscriptionPackage({
    required this.id,
    required this.name,
    required this.orderLimit,
    this.price = 0,
    this.durationDays = 30,
    this.isActive = true,
    this.isDriverPackage = true,
  });

  factory SubscriptionPackage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SubscriptionPackage(
      id: doc.id,
      name: d['name'] ?? '',
      orderLimit: d['orderLimit'] ?? 0,
      price: (d['price'] as num?)?.toDouble() ?? 0,
      durationDays: d['durationDays'] ?? 30,
      isActive: d['isActive'] ?? true,
      isDriverPackage: d['isDriverPackage'] ?? true,
    );
  }
}

class PlatformSettings {
  final bool maintenanceMode;
  final bool registrationsOpen;
  final bool auditLoggingEnabled;
  final double defaultCommissionRate;
  final int maxDriversPerZone;
  final String defaultLanguage;
  final bool killSwitchEnabled;

  const PlatformSettings({
    this.maintenanceMode = false,
    this.registrationsOpen = true,
    this.auditLoggingEnabled = true,
    this.defaultCommissionRate = 15,
    this.maxDriversPerZone = 50,
    this.defaultLanguage = 'en',
    this.killSwitchEnabled = false,
  });

  factory PlatformSettings.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PlatformSettings(
      maintenanceMode: d['maintenanceMode'] ?? false,
      registrationsOpen: d['registrationsOpen'] ?? true,
      auditLoggingEnabled: d['auditLoggingEnabled'] ?? true,
      defaultCommissionRate: (d['defaultCommissionRate'] as num?)?.toDouble() ?? 15,
      maxDriversPerZone: d['maxDriversPerZone'] ?? 50,
      defaultLanguage: d['defaultLanguage'] ?? 'en',
      killSwitchEnabled: d['killSwitchEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'maintenanceMode': maintenanceMode,
    'registrationsOpen': registrationsOpen,
    'auditLoggingEnabled': auditLoggingEnabled,
    'defaultCommissionRate': defaultCommissionRate,
    'maxDriversPerZone': maxDriversPerZone,
    'defaultLanguage': defaultLanguage,
    'killSwitchEnabled': killSwitchEnabled,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class DashboardStats {
  final double revenueToday;
  final int ordersToday;
  final int activeOrders;
  final int onlineDrivers;
  final int activeStores;
  final int newCustomers;
  final int pendingRefunds;
  final int pendingTickets;
  final int pendingDriverApplications;
  final int pendingStoreRequests;
  final double platformHealth;

  const DashboardStats({
    this.revenueToday = 0,
    this.ordersToday = 0,
    this.activeOrders = 0,
    this.onlineDrivers = 0,
    this.activeStores = 0,
    this.newCustomers = 0,
    this.pendingRefunds = 0,
    this.pendingTickets = 0,
    this.pendingDriverApplications = 0,
    this.pendingStoreRequests = 0,
    this.platformHealth = 98,
  });
}