import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  AuthProvider() {
    loadSavedUserSession();
  }

  // Tự động khôi phục phiên đăng nhập khi mở app
  Future<void> loadSavedUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('saved_user_id');
    if (savedUserId != null) {
      _currentUser = await _authRepository.getUserById(savedUserId);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(username, password);
      if (user != null) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('saved_user_id', user.id!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String phone = '',
    String address = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = User(
        username: username,
        password: password,
        fullName: fullName,
        phone: phone,
        address: address,
        role: 'CUSTOMER',
      );
      final id = await _authRepository.register(newUser);
      _currentUser = newUser.copyWith(id: id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('saved_user_id', id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = _currentUser!.copyWith(
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );

      await _authRepository.updateUserProfile(updated);
      _currentUser = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    if (_currentUser!.password != currentPassword) {
      _errorMessage = 'Mật khẩu hiện tại không chính xác!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.changePassword(_currentUser!.id!, newPassword);
      _currentUser = _currentUser!.copyWith(password: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user_id');
    notifyListeners();
  }
}
