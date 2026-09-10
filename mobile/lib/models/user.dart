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
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      avatar: json['avatar'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      isAvailable: json['isAvailable'],
    );
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
