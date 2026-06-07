import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tayyebgo_admin/features/dashboard/views/business_type.dart';

class StoreFilter {
  final bool? isActive;
  final String? zone;
  final String? businessCategory;
  final String? businessStatus;
  final String? search;

  const StoreFilter({
    this.isActive,
    this.zone,
    this.businessCategory,
    this.businessStatus,
    this.search,
  });

  StoreFilter copyWith({
    bool? isActive,
    String? zone,
    String? businessCategory,
    String? businessStatus,
    String? search,
    bool clearSearch = false,
    bool clearZone = false,
  }) {
    return StoreFilter(
      isActive: isActive ?? this.isActive,
      zone: clearZone ? null : (zone ?? this.zone),
      businessCategory: businessCategory ?? this.businessCategory,
      businessStatus: businessStatus ?? this.businessStatus,
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

class OrderFilter {
  final String? status;
  final String? storeId;
  final DateTime? from;
  final DateTime? to;
  const OrderFilter({this.status, this.storeId, this.from, this.to});
}

class DriverFilter {
  final String? status;
  final String? storeId;
  final bool? isActive;
  const DriverFilter({this.status, this.storeId, this.isActive});
}

class PaginationParams {
  final int limit;
  final DocumentSnapshot? startAfter;
  const PaginationParams({this.limit = 20, this.startAfter});
}

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  const PaginatedResult({required this.items, required this.lastDoc, required this.hasMore});
}

class AdminFirestoreService {
  AdminFirestoreService._();
  static final AdminFirestoreService instance = AdminFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, Object> _localFlags = <String, Object>{};

  T getLocalFlag<T>(String key, {required T defaultValue}) {
    final v = _localFlags[key];
    if (v is T) return v;
    return defaultValue;
  }

  void setLocalFlag(String key, Object value) {
    _localFlags[key] = value;
  }

  CollectionReference get _stores => _db.collection('restaurants');
  CollectionReference get _orders => _db.collection('orders');
  CollectionReference get _drivers => _db.collection('drivers');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _contracts => _db.collection('contracts');
  CollectionReference get _zones => _db.collection('zones');
  CollectionReference get _approvals => _db.collection('approvals');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _marketing => _db.collection('marketing');
  CollectionReference get _settlements => _db.collection('settlements');
  CollectionReference get _support => _db.collection('support');
  CollectionReference get _config => _db.collection('config');
  CollectionReference get _activityLog => _db.collection('activity_log');

  Stream<Map<String, dynamic>?> watchStore(String id) {
    return _stores.doc(id).snapshots().map((s) {
      if (!s.exists) return null;
      return {...(s.data() as Map<String, dynamic>), 'id': s.id};
    });
  }

  Future<Map<String, dynamic>?> getStore(String id) async {
    final s = await _stores.doc(id).get();
    if (!s.exists) return null;
    return {...(s.data() as Map<String, dynamic>), 'id': s.id};
  }

  Future<DocumentSnapshot> updateStoreStatus(String id, BusinessStatus status) {
    return _stores.doc(id).update({'businessStatus': status.value}).then((_) {
      logAdminAction(action: 'store.status_changed', actorId: '', target: id, metadata: {'status': status.value});
      return _stores.doc(id).get();
    });
  }

  Future<void> updateStoreActive(String id, bool active) {
    return _stores.doc(id).update({
      'isActive': active,
      if (active) 'approvedAt': FieldValue.serverTimestamp() else 'suspendedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      logAdminAction(action: active ? 'store.activated' : 'store.suspended', actorId: '', target: id);
    });
  }

  Future<void> updateStore(String id, Map<String, dynamic> data) {
    return _stores.doc(id).update(data).then((_) {
      logAdminAction(action: 'store.updated', actorId: '', target: id, metadata: {'fields': data.keys.toList()});
    });
  }

  Future<DocumentReference> createStore(Map<String, dynamic> data) {
    return _stores.add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteStore(String id) => _stores.doc(id).delete();

  Stream<List<Map<String, dynamic>>> watchStoresRaw({StoreFilter? filter, int limit = 20}) {
    Query q = _stores.limit(limit);
    if (filter?.isActive != null) q = q.where('isActive', isEqualTo: filter!.isActive);
    if (filter?.zone != null) q = q.where('zone', isEqualTo: filter!.zone);
    if (filter?.businessCategory != null) q = q.where('businessCategory', isEqualTo: filter!.businessCategory);
    if (filter?.businessStatus != null) q = q.where('businessStatus', isEqualTo: filter!.businessStatus);
    return q.snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<PaginatedResult<Map<String, dynamic>>> fetchStoresPage({
    StoreFilter? filter,
    PaginationParams? params,
  }) async {
    final p = params ?? const PaginationParams(limit: 20);
    Query q = _stores.limit(p.limit);
    if (filter?.isActive != null) q = q.where('isActive', isEqualTo: filter!.isActive);
    if (filter?.zone != null) q = q.where('zone', isEqualTo: filter!.zone);
    if (filter?.businessCategory != null) q = q.where('businessCategory', isEqualTo: filter!.businessCategory);
    if (p.startAfter != null) q = q.startAfterDocument(p.startAfter!);
    final snap = await q.get();
    final items = snap.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList();
    return PaginatedResult(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == p.limit,
    );
  }

  Stream<int> watchStoreCount({bool? isActive}) {
    Query q = _stores;
    if (isActive != null) q = q.where('isActive', isEqualTo: isActive);
    return q.snapshots().map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> watchStoreProducts(String storeId, {int limit = 50}) {
    return _stores
        .doc(storeId)
        .collection('products')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchStoreCategories(String storeId, {int limit = 50}) {
    return _stores
        .doc(storeId)
        .collection('categories')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchOrdersRaw({OrderFilter? filter, int limit = 30}) {
    Query q = _orders.orderBy('createdAt', descending: true).limit(limit);
    if (filter?.status != null) q = q.where('status', isEqualTo: filter!.status);
    if (filter?.storeId != null) q = q.where('storeId', isEqualTo: filter!.storeId);
    return q.snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Stream<int> watchOrderCount({String? status, String? storeId}) {
    Query q = _orders;
    if (status != null) q = q.where('status', isEqualTo: status);
    if (storeId != null) q = q.where('storeId', isEqualTo: storeId);
    return q.snapshots().map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> watchDriversRaw({DriverFilter? filter, int limit = 50}) {
    Query q = _drivers.limit(limit);
    if (filter?.status != null) q = q.where('status', isEqualTo: filter!.status);
    if (filter?.isActive != null) q = q.where('isActive', isEqualTo: filter!.isActive);
    return q.snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Stream<int> watchDriverCount({String? status, bool? isActive}) {
    Query q = _drivers;
    if (status != null) q = q.where('status', isEqualTo: status);
    if (isActive != null) q = q.where('isActive', isEqualTo: isActive);
    return q.snapshots().map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> watchDriverAssignments(String storeId, {int limit = 20}) {
    return _db
        .collection('driverAssignments')
        .where('storeId', isEqualTo: storeId)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<int> watchUserCount() {
    return _users.snapshots().map((s) => s.docs.length);
  }

  Stream<double> watchTotalRevenue({String? storeId, int limit = 500}) {
    Query q = _orders.limit(limit);
    if (storeId != null) q = q.where('storeId', isEqualTo: storeId);
    return q.snapshots().map((s) {
      var sum = 0.0;
      for (final d in s.docs) {
        final data = d.data() as Map<String, dynamic>;
        if (data['status'] == 'cancelled' || data['status'] == 'refunded') continue;
        sum += (data['total'] as num?)?.toDouble() ?? 0;
      }
      return sum;
    });
  }

  Stream<List<Map<String, dynamic>>> watchContractsForStore(String storeName, {int limit = 10}) {
    return _contracts
        .where('storeName', isEqualTo: storeName)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchZonesRaw({int limit = 50}) {
    return _zones.limit(limit).snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<DocumentReference> createZone(Map<String, dynamic> data) =>
      _zones.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateZone(String id, Map<String, dynamic> data) => _zones.doc(id).update(data);
  Future<void> deleteZone(String id) => _zones.doc(id).delete();

  Stream<List<Map<String, dynamic>>> watchApprovalsRaw({String? type, String? status, int limit = 30}) {
    Query q = _approvals.orderBy('createdAt', descending: true).limit(limit);
    if (type != null) q = q.where('type', isEqualTo: type);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<void> approveRequest(String id, {String? note}) {
    return _approvals.doc(id).update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      if (note != null) 'reviewNote': note,
    });
  }

  Future<void> rejectRequest(String id, {String? reason}) {
    return _approvals.doc(id).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  Stream<List<Map<String, dynamic>>> watchNotificationsRaw({int limit = 50}) {
    return _notifications.orderBy('sentAt', descending: true).limit(limit).snapshots().map(
        (s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<DocumentReference> sendNotification(Map<String, dynamic> data) {
    return _notifications.add({
      ...data,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }

  Stream<List<Map<String, dynamic>>> watchMarketingRaw({int limit = 50}) {
    return _marketing.limit(limit).snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<DocumentReference> createCampaign(Map<String, dynamic> data) =>
      _marketing.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateCampaign(String id, Map<String, dynamic> data) => _marketing.doc(id).update(data);
  Future<void> deleteCampaign(String id) => _marketing.doc(id).delete();

  Stream<List<Map<String, dynamic>>> watchSettlementsRaw({String? status, int limit = 50}) {
    Query q = _settlements.limit(limit);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<void> settleDriver(String driverId, double amount) {
    return _settlements.add({
      'driverId': driverId,
      'amount': amount,
      'settledAt': FieldValue.serverTimestamp(),
      'status': 'settled',
    });
  }

  Stream<List<Map<String, dynamic>>> watchSupportTickets({String? status, int limit = 30}) {
    Query q = _support.orderBy('createdAt', descending: true).limit(limit);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Stream<Map<String, dynamic>?> watchFeatureFlags() {
    return _config.doc('feature_flags').snapshots().map((s) {
      if (!s.exists) return null;
      return s.data() as Map<String, dynamic>;
    });
  }

  Stream<List<Map<String, dynamic>>> watchActivityLog({int limit = 50}) {
    return _activityLog
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList());
  }

  Future<void> logAdminAction({
    required String action,
    required String actorId,
    String? actorName,
    String? target,
    Map<String, dynamic>? metadata,
  }) async {
    await _activityLog.add({
      'action': action,
      'actorId': actorId,
      'actorName': actorName,
      'target': target,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFeatureFlag(String key, bool value) {
    return _config.doc('feature_flags').set({key: value}, SetOptions(merge: true)).then((_) {
      logAdminAction(action: 'feature_flag.toggled', actorId: '', target: key, metadata: {'value': value});
    });
  }

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    final storesSnap = await _stores.limit(50).get();
    for (final d in storesSnap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      if (name.contains(lower)) {
        results.add({
          'type': 'store',
          'id': d.id,
          'title': data['name'] ?? '',
          'subtitle': data['cuisineType'] ?? data['businessType'] ?? '',
        });
      }
    }

    final driversSnap = await _drivers.limit(50).get();
    for (final d in driversSnap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      if (name.contains(lower)) {
        results.add({
          'type': 'driver',
          'id': d.id,
          'title': data['name'] ?? '',
          'subtitle': data['phone'] ?? '',
        });
      }
    }

    return results.take(20).toList();
  }
}

class StreamListener<T> {
  final T value;
  final Object? error;
  final bool isLoading;
  const StreamListener({this.isLoading = false, this.error, required this.value});
  bool get hasError => error != null;
  bool get isReady => !isLoading && error == null;
}

@immutable
class AsyncValue<T> {
  final T? data;
  final Object? error;
  final bool isLoading;
  const AsyncValue._({this.data, this.error, this.isLoading = false});
  const AsyncValue.loading() : this._(isLoading: true);
  const AsyncValue.data(T d) : this._(data: d);
  const AsyncValue.error(Object e) : this._(error: e);
  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isReady => !isLoading && error == null && data != null;
}
