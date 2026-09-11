import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';
import '../services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  static const _ratedKey = 'reviewed_job_ids';

  List<Review> _reviews = [];
  final Set<String> _ratedJobIds = {};
  bool _isLoading = false;
  String? _error;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get ratedJobIds => _ratedJobIds;

  Future<void> restoreRatedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ratedKey);
    if (raw != null) {
      _ratedJobIds
        ..clear()
        ..addAll(List<String>.from(jsonDecode(raw) as List));
    }
    notifyListeners();
  }

  bool isRated(String jobId) => _ratedJobIds.contains(jobId);

  Future<bool> createReview({
    required String jobId,
    required String revieweeId,
    required int rating,
    String? comment,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/reviews',
        {
          'jobId': jobId,
          'revieweeId': revieweeId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
        token: token,
      );
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['id'] != null) {
        _ratedJobIds.add(jobId);
        _persist(_ratedJobIds);
        _reviews.insert(0, Review.fromJson(data));
        notifyListeners();
        return true;
      }
      _error = 'Failed to submit review';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchByUser(String userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/reviews/user/$userId',
        token: token,
      );
      final data = response['data'] ?? response;
      if (data is List) {
        _reviews = data
            .map((r) => Review.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Failed to load reviews';
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _persist(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ratedKey, jsonEncode(ids.toList()));
  }
}