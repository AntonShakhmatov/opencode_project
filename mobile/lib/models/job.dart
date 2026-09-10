class Job {
  final String id;
  final String clientId;
  final String? handymanId;
  final String serviceType;
  final String description;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final double? estimatedPrice;
  final double? finalPrice;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.clientId,
    this.handymanId,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.estimatedPrice,
    this.finalPrice,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? coords = json['location']?['coordinates'];
    return Job(
      id: json['id'],
      clientId: json['clientId'],
      handymanId: json['handymanId'],
      serviceType: json['serviceType'],
      description: json['description'],
      status: json['status'],
      latitude: coords != null ? (coords[1] as num).toDouble() : json['latitude']?.toDouble() ?? 0,
      longitude: coords != null ? (coords[0] as num).toDouble() : json['longitude']?.toDouble() ?? 0,
      address: json['address'],
      estimatedPrice: json['estimatedPrice']?.toDouble(),
      finalPrice: json['finalPrice']?.toDouble(),
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'handymanId': handymanId,
      'serviceType': serviceType,
      'description': description,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Handyman {
  final String userId;
  final String name;
  final String? avatar;
  final double? rating;
  final List<String>? skills;
  final double latitude;
  final double longitude;
  final double distanceInMeters;

  Handyman({
    required this.userId,
    required this.name,
    this.avatar,
    this.rating,
    this.skills,
    required this.latitude,
    required this.longitude,
    required this.distanceInMeters,
  });

  factory Handyman.fromJson(Map<String, dynamic> json) {
    return Handyman(
      userId: json['userId'],
      name: json['name'],
      avatar: json['avatar'],
      rating: json['rating']?.toDouble(),
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      latitude: json['latitude']?.toDouble() ?? json['location']?['coordinates']?[1]?.toDouble(),
      longitude: json['longitude']?.toDouble() ?? json['location']?['coordinates']?[0]?.toDouble(),
      distanceInMeters: json['distanceInMeters']?.toDouble(),
    );
  }
}
