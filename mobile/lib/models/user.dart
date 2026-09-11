class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? avatar;
  final double? rating;
  final int? reviewCount;
  final List<String>? skills;
  final bool? isAvailable;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.avatar,
    this.rating,
    this.reviewCount,
    this.skills,
    this.isAvailable,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final rawReviewCount = json['reviewCount'];
    final rawSkills = json['skills'];

    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      avatar: json['avatar'],
      rating: rawRating != null && rawRating.toString().trim().isNotEmpty
          ? double.tryParse(rawRating.toString())
          : null,
      reviewCount: rawReviewCount != null
          ? int.tryParse(rawReviewCount.toString()) ??
              (rawReviewCount is num ? rawReviewCount.toInt() : null)
          : null,
      skills: _parseSkills(rawSkills),
      isAvailable: json['isAvailable'],
    );
  }

  static List<String>? _parseSkills(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return <String>[];
      return trimmed
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is List) {
      return raw.map((s) => s.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'rating': rating,
      'reviewCount': reviewCount,
      'skills': skills,
      'isAvailable': isAvailable,
    };
  }
}
