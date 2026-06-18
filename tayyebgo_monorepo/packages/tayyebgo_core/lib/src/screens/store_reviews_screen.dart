import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// Displays store reviews with rating distribution, individual reviews,
/// and a button to write a new review.
class StoreReviewsScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String? currentUserId;
  final String? currentUserName;

  const StoreReviewsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  final ReviewService _reviewService = ReviewService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews — ${widget.restaurantName}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rating summary
          _RatingSummary(restaurantId: widget.restaurantId),
          const SizedBox(height: 24),

          // Write review button
          if (widget.currentUserId != null)
            OutlinedButton.icon(
              onPressed: () => _showWriteReviewDialog(context),
              icon: const Icon(Icons.edit, size: 18),
              label: Text('Write a Review', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
            ),
          const SizedBox(height: 24),

          // Reviews list
          StreamBuilder<QuerySnapshot>(
            stream: _reviewService.getReviews(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined, size: 48, color: context.textMutedColor),
                        const SizedBox(height: 12),
                        Text('No reviews yet', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Be the first to review this store', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final review = StoreReview.fromFirestore(doc);
                  return _ReviewCard(review: review);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WriteReviewSheet(
        restaurantId: widget.restaurantId,
        userId: widget.currentUserId!,
        userName: widget.currentUserName ?? 'Anonymous',
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final String restaurantId;
  const _RatingSummary({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: ReviewService().getAverageRating(restaurantId),
      builder: (context, ratingSnap) {
        return StreamBuilder<Map<int, int>>(
          stream: ReviewService().getRatingDistribution(restaurantId),
          builder: (context, distSnap) {
            final avg = ratingSnap.data ?? 0;
            final dist = distSnap.data ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
            final total = dist.values.fold<int>(0, (a, b) => a + b);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.brCard,
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  // Average rating
                  Column(
                    children: [
                      Text(avg.toStringAsFixed(1),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 36, color: context.textPrimaryColor)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) => Icon(
                          i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 20,
                        )),
                      ),
                      Text('$total reviews', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Distribution bars
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((stars) {
                        final count = dist[stars] ?? 0;
                        final pct = total > 0 ? count / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$stars', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                              const SizedBox(width: 4),
                              Icon(Icons.star_rounded, color: const Color(0xFFFBBF24), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: AppRadius.brSm,
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: context.borderColor,
                                    color: const Color(0xFFFBBF24),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$count', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final StoreReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(_formatDate(review.createdAt), style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) => Icon(
              i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFFBBF24),
              size: 18,
            )),
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.text, style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor)),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: AppRadius.brMd,
                  child: CachedImage(
                    url: review.photoUrls[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final String restaurantId;
  final String userId;
  final String userName;

  const _WriteReviewSheet({
    required this.restaurantId,
    required this.userId,
    required this.userName,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 5;
  final _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await ReviewService().submitReview(
        userId: widget.userId,
        userName: widget.userName,
        restaurantId: widget.restaurantId,
        rating: _rating,
        text: _textController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.borderColor, borderRadius: AppRadius.brSm),
            ),
          ),
          const SizedBox(height: 16),
          Text('Write a Review', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFBBF24),
                    size: 36,
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us about your experience...',
              hintStyle: GoogleFonts.inter(color: context.textMutedColor),
              border: OutlineInputBorder(borderRadius: AppRadius.brMd),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit Review', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
