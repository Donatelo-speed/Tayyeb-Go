import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/tayyebgo_theme.dart';

class OrderRating extends StatefulWidget {
  final String orderId;
  final String restaurantId;

  const OrderRating({super.key, required this.orderId, required this.restaurantId});

  @override
  State<OrderRating> createState() => _OrderRatingState();
}

class _OrderRatingState extends State<OrderRating> {
  int _rating = 0;
  bool _submitted = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: TayyebGoTheme.cardDecoration,
        child: Row(children: [
          Icon(Icons.check_circle, color: TayyebGoTheme.successColor, size: 20),
          const SizedBox(width: 12),
          Text('Thank you for your review!', style: TextStyle(color: TayyebGoTheme.successColor, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate your experience', style: TayyebGoTheme.heading3),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(star <= _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                onPressed: () => setState(() => _rating = star),
              );
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating > 0 && !_saving ? _submitRating : null,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Rating'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('Orders').doc(widget.orderId).update({
        'customerRating': _rating,
        'ratedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('Restaurants').doc(widget.restaurantId).update({
        'totalRatings': FieldValue.increment(1),
        'sumRatings': FieldValue.increment(_rating),
      });
      if (mounted) setState(() { _submitted = true; _saving = false; });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }
}
