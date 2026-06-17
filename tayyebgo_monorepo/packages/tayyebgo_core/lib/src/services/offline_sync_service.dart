import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'sync_queue.dart';

class OfflineSyncService {
  static Database? _database;
  final SyncQueue _syncQueue = SyncQueue();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  Stream<bool> get connectivityStream => _connectivityController.stream;
  int get pendingActionsCount => _syncQueue.length;

  static const String _dbName = 'tayyebgo_offline.db';
  static const int _dbVersion = 1;

  static const String _menuTable = 'cached_menus';
  static const String _cartTable = 'cached_cart';
  static const String _ordersTable = 'cached_orders';
  static const String _syncQueueTable = 'sync_queue';

  Future<void> initialize() async {
    await _initDatabase();
    await _loadSyncQueue();
    await _initConnectivity();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      _dbName,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_menuTable (
        restaurant_id TEXT PRIMARY KEY,
        menu_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_cartTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        items_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_ordersTable (
        id TEXT PRIMARY KEY,
        order_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_syncQueueTable (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _loadSyncQueue() async {
    final db = _database;
    if (db == null) return;

    final maps = await db.query(_syncQueueTable);
    _syncQueue.loadFromMaps(maps);
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();

    final result = await connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    _connectivityController.add(_isOnline);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      _connectivityController.add(_isOnline);

      if (!wasOnline && _isOnline) {
        _onConnectivityRestored();
      }
    });
  }

  Future<void> _onConnectivityRestored() async {
    if (_syncQueue.isNotEmpty) {
      await processSyncQueue();
    }
  }

  Future<void> processSyncQueue() async {
    if (_isSyncing || _syncQueue.isEmpty) return;

    _isSyncing = true;

    try {
      while (_syncQueue.isNotEmpty) {
        final action = _syncQueue.dequeue();
        if (action == null) break;

        try {
          await _processAction(action);
          await _removeFromDatabase(action.id);
        } catch (e) {
          action.retryCount++;
          if (action.retryCount < 3) {
            _syncQueue.enqueue(action);
            await _updateInDatabase(action);
          } else {
            await _removeFromDatabase(action.id);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processAction(SyncAction action) async {
    switch (action.type) {
      case SyncActionType.placeOrder:
        await _processPlaceOrder(action.data);
        break;
      case SyncActionType.updateProfile:
        await _processUpdateProfile(action.data);
        break;
      case SyncActionType.updateCart:
        await _processUpdateCart(action.data);
        break;
      case SyncActionType.cancelOrder:
        await _processCancelOrder(action.data);
        break;
      case SyncActionType.rateOrder:
        await _processRateOrder(action.data);
        break;
    }
  }

  Future<void> _processPlaceOrder(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _processUpdateProfile(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _processUpdateCart(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _processCancelOrder(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _processRateOrder(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _removeFromDatabase(String actionId) async {
    final db = _database;
    if (db == null) return;

    await db.delete(
      _syncQueueTable,
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  Future<void> _updateInDatabase(SyncAction action) async {
    final db = _database;
    if (db == null) return;

    await db.update(
      _syncQueueTable,
      action.toMap(),
      where: 'id = ?',
      whereArgs: [action.id],
    );
  }

  Future<void> enqueueAction(SyncActionType type, Map<String, dynamic> data) async {
    final action = SyncAction(
      id: _generateId(),
      type: type,
      data: data,
    );

    _syncQueue.enqueue(action);
    await _saveToDatabase(action);
  }

  String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<void> _saveToDatabase(SyncAction action) async {
    final db = _database;
    if (db == null) return;

    await db.insert(
      _syncQueueTable,
      action.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheMenu(String restaurantId, Map<String, dynamic> menu) async {
    final db = _database;
    if (db == null) return;

    await db.insert(
      _menuTable,
      {
        'restaurant_id': restaurantId,
        'menu_data': jsonEncode(menu),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedMenu(String restaurantId) async {
    final db = _database;
    if (db == null) return null;

    final results = await db.query(
      _menuTable,
      where: 'restaurant_id = ?',
      whereArgs: [restaurantId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final menuData = results.first['menu_data'] as String;
    return jsonDecode(menuData) as Map<String, dynamic>;
  }

  Future<void> cacheCart(List<Map<String, dynamic>> items) async {
    final db = _database;
    if (db == null) return;

    await db.delete(_cartTable);

    await db.insert(
      _cartTable,
      {
        'items_data': jsonEncode(items),
        'cached_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>?> getCachedCart() async {
    final db = _database;
    if (db == null) return null;

    final results = await db.query(
      _cartTable,
      limit: 1,
    );

    if (results.isEmpty) return null;

    final itemsData = results.first['items_data'] as String;
    final decoded = jsonDecode(itemsData) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    final db = _database;
    if (db == null) return;

    for (final order in orders) {
      final orderId = order['id'] as String? ?? _generateId();
      await db.insert(
        _ordersTable,
        {
          'id': orderId,
          'order_data': jsonEncode(order),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedOrders() async {
    final db = _database;
    if (db == null) return null;

    final results = await db.query(
      _ordersTable,
      orderBy: 'cached_at DESC',
    );

    if (results.isEmpty) return null;

    return results.map((row) {
      final orderData = row['order_data'] as String;
      return jsonDecode(orderData) as Map<String, dynamic>;
    }).toList();
  }

  Future<void> clearCache() async {
    final db = _database;
    if (db == null) return;

    await db.delete(_menuTable);
    await db.delete(_cartTable);
    await db.delete(_ordersTable);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectivityController.close();
    await _database?.close();
    _database = null;
  }
}
