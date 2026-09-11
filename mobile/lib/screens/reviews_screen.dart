import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';

class ReviewsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final reviews = context.read<ReviewProvider>();
    await reviews.fetchByUser(widget.userId, auth.token ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>();
    final avg = reviews.reviews.isEmpty
        ? null
        : reviews.reviews.fold<int>(0, (sum, r) => sum + r.rating) /
            reviews.reviews.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} · Ratings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: reviews.isLoading && reviews.reviews.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : reviews.reviews.isEmpty
                ? const Center(
                    child: Text(
                      'No reviews yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                size: 28, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              avg!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${reviews.reviews.length} '
                              '${reviews.reviews.length == 1 ? 'review' : 'reviews'})',
                              style:
                                  const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      ...reviews.reviews.map(_buildReviewCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    (review.reviewerName ?? '?').isNotEmpty
                        ? review.reviewerName![0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    review.reviewerName ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  '★★★★★',
                  style: TextStyle(fontSize: 10, color: Colors.amber),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.amber,
                );
              }),
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().format(review.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}