import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  bool _isAuthenticated = false;
  bool _isRestoring = true;
  String? _token;
  User? _user;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isRestoring => _isRestoring;
  String? get token => _token;
  User? get user => _user;
  String? get userId => _user?.id;
  String? get userName => _user?.name;
  String? get userEmail => _user?.email;
  String? get userRole => _user?.role;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token != null && userJson != null) {
      _token = token;
      _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _isAuthenticated = true;
    }

    _isRestoring = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['accessToken'] != null) {
        _applyAuth(data['accessToken'] as String, data['user']);
        return true;
      }
      _error = 'Login failed';
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

  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data['accessToken'] != null) {
        _applyAuth(data['accessToken'] as String, data['user']);
        return true;
      }
      _error = 'Registration failed';
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

  Future<bool> loadProfile() async {
    if (!_isAuthenticated || _token == null || _user == null) {
      return false;
    }
    try {
      final response = await ApiService.get(
        '/users/${_user!.id}',
        token: _token,
      );
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        _user = User.fromJson(data);
        await _persist();
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> changes) async {
    if (!_isAuthenticated || _token == null || _user == null) {
      return false;
    }
    try {
      final response = await ApiService.put(
        '/users/${_user!.id}',
        changes,
        token: _token,
      );
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        _user = User.fromJson(data);
        await _persist();
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _applyAuth(String token, dynamic userData) {
    _token = token;
    final userMap = userData is Map<String, dynamic> ? userData : <String, dynamic>{};
    _user = User.fromJson({...userMap, 'id': userMap['id'] ?? ''});
    _isAuthenticated = true;
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
    if (_user != null) {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    }
  }
}