import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';

class JobProvider extends ChangeNotifier {
  List<Job> _jobs = [];
  List<Job> _availableJobs = [];
  List<Job> _activeJobs = [];
  List<Job> _completedJobs = [];
  List<Handyman> _nearbyHandymen = [];
  Job? _currentJob;
  bool _isLoading = false;
  String? _error;

  List<Job> get jobs => _jobs;
  List<Job> get availableJobs => _availableJobs;
  List<Job> get activeJobs => _activeJobs;
  List<Job> get completedJobs => _completedJobs;
  List<Handyman> get nearbyHandymen => _nearbyHandymen;
  Job? get currentJob => _currentJob;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _categorizeJobs() {
    _availableJobs = _jobs.where((j) => j.status == 'matched').toList();
    _activeJobs = _jobs.where((j) =>
        ['accepted', 'en_route', 'in_progress', 'searching'].contains(j.status)).toList();
    _completedJobs = _jobs.where((j) =>
        ['completed', 'cancelled'].contains(j.status)).toList();
  }

  Future<void> fetchClientJobs(String token, String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/jobs/client/$clientId', token: token);
      final data = response['data'] ?? response;
      if (data is List) {
        _jobs = data.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
        _categorizeJobs();
      } else {
        _error = 'Failed to fetch jobs';
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

  Future<void> fetchHandymanJobs(String token, String handymanId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/jobs/handyman/$handymanId', token: token);
      final data = response['data'] ?? response;
      if (data is List) {
        _jobs = data.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
        _categorizeJobs();
      } else {
        _error = 'Failed to fetch jobs';
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

  Future<void> fetchAllJobs(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/jobs', token: token);
      final data = response['data'] ?? response;
      if (data is List) {
        _jobs = data.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
        _categorizeJobs();
      } else {
        _error = 'Failed to fetch jobs';
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

  Future<void> createJob({
    required String serviceType,
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/jobs',
        {
          'serviceType': serviceType,
          'description': description,
          'location': {'latitude': latitude, 'longitude': longitude},
          'address': address,
        },
        token: token,
      );
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['id'] != null) {
        _currentJob = Job.fromJson(data);
        _jobs.insert(0, _currentJob!);
        _categorizeJobs();
      } else {
        _error = 'Failed to create job';
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

  Future<void> searchNearbyHandymen({
    required double latitude,
    required double longitude,
    required int radiusInMeters,
    String? serviceType,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radiusInMeters.toString(),
      };
      if (serviceType != null) {
        queryParams['serviceType'] = serviceType;
      }

      final response = await ApiService.get(
        '/location/nearby?${Uri(queryParameters: queryParams).query}',
        token: token,
      );
      final data = response['data'] ?? response;
      if (data is List) {
        _nearbyHandymen = data
            .map((h) => Handyman.fromJson(h as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Failed to search handymen';
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

  Future<void> acceptJob(String jobId, String? token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put('/jobs/$jobId/accept', {}, token: token);
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['id'] != null) {
        final updated = Job.fromJson(data);
        final index = _jobs.indexWhere((j) => j.id == jobId);
        if (index != -1) _jobs[index] = updated;
        _currentJob = updated;
        _categorizeJobs();
      } else {
        _error = 'Failed to accept job';
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

  Future<void> updateJobStatus(String jobId, String status, {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/jobs/$jobId',
        {'status': status},
        token: token,
      );
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['id'] != null) {
        final updated = Job.fromJson(data);
        final index = _jobs.indexWhere((j) => j.id == jobId);
        if (index != -1) _jobs[index] = updated;
        _currentJob = updated;
        _categorizeJobs();
      } else {
        _error = 'Failed to update job status';
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

  Future<Job?> fetchJobById(String jobId, String? token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/jobs/$jobId', token: token);
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['id'] != null) {
        final job = Job.fromJson(data);
        addJobFromSocket(job);
        return job;
      }
      _error = 'Failed to fetch job';
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addJobFromSocket(Job job) {
    final index = _jobs.indexWhere((j) => j.id == job.id);
    if (index == -1) {
      _jobs.insert(0, job);
    } else {
      _jobs[index] = job;
    }
    _categorizeJobs();
    notifyListeners();
  }

  void updateJobFromSocket(String jobId, Map<String, dynamic> changes) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final old = _jobs[index];
      _jobs[index] = Job(
        id: old.id,
        clientId: old.clientId,
        handymanId: changes['handymanId'] ?? old.handymanId,
        serviceType: old.serviceType,
        description: old.description,
        status: changes['status'] ?? old.status,
        latitude: old.latitude,
        longitude: old.longitude,
        address: old.address,
        handymanName: changes['handymanName'] ?? old.handymanName,
        estimatedPrice: old.estimatedPrice,
        finalPrice: old.finalPrice,
        scheduledAt: old.scheduledAt,
        startedAt: old.startedAt,
        completedAt: old.completedAt,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      _categorizeJobs();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
