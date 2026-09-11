class Review {
  final String id;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;

  Review({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    return Review(
      id: json['id'],
      jobId: json['jobId'],
      reviewerId: json['reviewerId'],
      revieweeId: json['revieweeId'],
      rating: json['rating'] is int ? json['rating'] : (json['rating'] as num).toInt(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      reviewerName: reviewer?['name'],
    );
  }
}