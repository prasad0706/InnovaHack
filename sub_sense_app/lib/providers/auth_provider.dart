import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/safe_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _token;
  String _userEmail = '';
  String _userName = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get token => _token;
  String get userEmail => _userEmail;
  String get userName => _userName;

  String get userInitial => userName.isNotEmpty
      ? userName[0].toUpperCase()
      : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U');

  String get userDisplayName => userName.isNotEmpty
      ? userName
      : (userEmail.isNotEmpty ? userEmail.split('@')[0] : 'User');

  AuthProvider() {
    _loadAuthSession();
  }

  Future<void> _loadAuthSession() async {
    try {
      final savedToken = await SafeStorage.getString('auth_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        final userData = await ApiService.getCurrentUser(savedToken);
        _userEmail = userData['email'] ?? '';
        _userName = userData['name'] ?? '';
        _isLoggedIn = true;
      }
    } catch (e) {
      _token = null;
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userData = await ApiService.login(email: email, password: password);
      _token = userData['token'] as String?;
      _userEmail = userData['email'] as String? ?? email;
      _userName = userData['name'] as String? ?? email.split('@')[0];
      _isLoggedIn = true;

      if (_token != null) {
        await SafeStorage.setString('auth_token', _token!);
        await SafeStorage.setString('user_name', _userName);
        await SafeStorage.setString('user_email', _userEmail);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userData = await ApiService.register(
        email: email,
        password: password,
        name: name,
      );
      _token = userData['token'] as String?;
      _userEmail = userData['email'] as String? ?? email;
      _userName = userData['name'] as String? ?? name;
      _isLoggedIn = true;

      if (_token != null) {
        await SafeStorage.setString('auth_token', _token!);
        await SafeStorage.setString('user_name', _userName);
        await SafeStorage.setString('user_email', _userEmail);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _userEmail = '';
    _userName = '';
    _errorMessage = null;

    await SafeStorage.remove('auth_token');
    await SafeStorage.remove('user_email');

    notifyListeners();
  }
}
