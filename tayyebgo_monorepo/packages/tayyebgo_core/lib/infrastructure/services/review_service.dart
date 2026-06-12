import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// A store/restaurant review with star rating, text, and optional photos.
class StoreReview {
  final String id;
  final String userId;
  final String userName;
  final String restaurantId;
  final double rating;
  final String text;
  final List<String> photoUrls;
  final DateTime createdAt;
  final String? orderType; // 'food', 'grocery', 'pharmacy', etc.

  StoreReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.rating,
    required this.text,
    this.photoUrls = const [],
    required this.createdAt,
    this.orderType,
  });

  factory StoreReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreReview(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      text: data['text'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderType: data['orderType'],
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'restaurantId': restaurantId,
    'rating': rating,
    'text': text,
    'photoUrls': photoUrls,
    'createdAt': FieldValue.serverTimestamp(),
    'orderType': orderType,
  };
}

class ReviewService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Gets reviews for a restaurant, ordered by most recent.
  Stream<QuerySnapshot> getReviews(String restaurantId) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Gets the average rating for a restaurant.
  Stream<double> getAverageRating(String restaurantId) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['rating'] as num?)?.toDouble() ?? 0;
      }
      return total / snapshot.docs.length;
    });
  }

  /// Gets the rating distribution (1-5 stars) for a restaurant.
  Stream<Map<int, int>> getRatingDistribution(String restaurantId) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rating = ((data['rating'] as num?)?.toDouble() ?? 0).round();
        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }
      return distribution;
    });
  }

  /// Submits a review with optional photos.
  Future<void> submitReview({
    required String userId,
    required String userName,
    required String restaurantId,
    required double rating,
    required String text,
    List<String>? photoUrls,
    String? orderType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('reviews').add(StoreReview(
        id: '',
        userId: userId,
        userName: userName,
        restaurantId: restaurantId,
        rating: rating,
        text: text,
        photoUrls: photoUrls ?? [],
        createdAt: DateTime.now(),
        orderType: orderType,
      ).toMap());

      // Update restaurant's average rating
      await _updateRestaurantRating(restaurantId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uploads a review photo to Firebase Storage.
  Future<String?> uploadPhoto(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('reviews/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[REVIEW] Error uploading photo: $e');
      return null;
    }
  }

  /// Updates the restaurant's average rating in the restaurants collection.
  Future<void> _updateRestaurantRating(String restaurantId) async {
    final reviews = await _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    if (reviews.docs.isEmpty) return;

    double total = 0;
    for (final doc in reviews.docs) {
      final data = doc.data();
      total += (data['rating'] as num?)?.toDouble() ?? 0;
    }

    await _firestore.collection('restaurants').doc(restaurantId).update({
      'averageRating': total / reviews.docs.length,
      'reviewCount': reviews.docs.length,
    });
  }

  /// Checks if a user has already reviewed a restaurant.
  Future<bool> hasUserReviewed(String userId, String restaurantId) async {
    final reviews = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(1)
        .get();

    return reviews.docs.isNotEmpty;
  }
}
