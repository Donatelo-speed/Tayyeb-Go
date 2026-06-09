import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_loyalty_repository.dart';

class FirebaseLoyaltyRepository implements ILoyaltyRepository {
  static final FirebaseLoyaltyRepository instance = FirebaseLoyaltyRepository._();
  FirebaseLoyaltyRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    final snap = await _firestore
        .collection('loyalty_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  @override
  Future<int> getCurrentPoints(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<bool> awardPoints({
    required String userId,
    required int points,
    required String type,
    required String description,
    String? orderId,
  }) async {
    try {
      await _firestore.collection('loyalty_transactions').add({
        'userId': userId,
        'points': points,
        'type': type,
        'description': description,
        if (orderId != null) 'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(points),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> redeemPoints({
    required String userId,
    required int points,
    required String description,
  }) async {
    try {
      final currentPoints = await getCurrentPoints(userId);
      if (currentPoints < points) return false;

      await _firestore.collection('loyalty_transactions').add({
        'userId': userId,
        'points': -points,
        'type': 'redeemed',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(-points),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStreakData(String userId) async {
    try {
      final snap = await _firestore
          .collection('loyalty_transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'streak')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        return {
          'currentStreak': (d['streakDay'] as num?)?.toInt() ?? 0,
          'bestStreak': (d['bestStreak'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'currentStreak': 0, 'bestStreak': 0};
  }
}
