import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    // TODO: Implement actual API call
    _isAuthenticated = true;
    _token = 'mock_token';
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    notifyListeners();
  }
}
