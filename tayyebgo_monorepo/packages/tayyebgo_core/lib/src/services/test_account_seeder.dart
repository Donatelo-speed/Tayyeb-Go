import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAccountSeeder {
  TestAccountSeeder._();
  static final TestAccountSeeder instance = TestAccountSeeder._();

  static const _seededKey = 'test_accounts_seeded_v2';
  static const _roleMap = <String, String>{
    'admin@test.com': 'superAdmin',
    'owner@test.com': 'restaurantOwner',
    'cashier@test.com': 'cashier',
    'driver@test.com': 'driver',
    'customer@test.com': 'customer',
  };

  Future<void> seedIfNeeded() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    try {
      final db = FirebaseFirestore.instance;
      for (final entry in _roleMap.entries) {
        final email = entry.key;
        final correctRole = entry.value;
        final query = await db
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isEmpty) continue;
        final doc = query.docs.first;
        final currentRole = doc.data()['role'] as String?;
        if (currentRole != correctRole) {
          await doc.reference.update({'role': correctRole});
          debugPrint('[TestAccountSeeder] Fixed $email: $currentRole → $correctRole');
        }
      }
      await prefs.setBool(_seededKey, true);
      debugPrint('[TestAccountSeeder] All test accounts seeded.');
    } catch (e) {
      debugPrint('[TestAccountSeeder] Error: $e');
    }
  }
}
