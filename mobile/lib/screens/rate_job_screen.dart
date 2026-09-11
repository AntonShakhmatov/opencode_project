import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';

class RateJobScreen extends StatefulWidget {
  final String jobId;
  final String revieweeId;
  final String revieweeName;

  const RateJobScreen({
    super.key,
    required this.jobId,
    required this.revieweeId,
    required this.revieweeName,
  });

  @override
  State<RateJobScreen> createState() => _RateJobScreenState();
}

class _RateJobScreenState extends State<RateJobScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final reviews = context.read<ReviewProvider>();

    final success = await reviews.createReview(
      jobId: widget.jobId,
      revieweeId: widget.revieweeId,
      rating: _rating,
      comment: _commentController.text.trim(),
      token: auth.token,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your review!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reviews.error ?? 'Failed to submit review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Job'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Icon(
              Icons.star_half,
              size: 64,
              color: AppColors.warn,
            ),
            const SizedBox(height: 16),
            const Text(
              'How was your experience?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate ${widget.revieweeName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: AppColors.warn,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share details about your experience (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: reviews.isLoading ? null : _submit,
              icon: reviews.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                reviews.isLoading ? 'Submitting...' : 'Submit Review',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}