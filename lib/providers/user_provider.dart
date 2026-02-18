import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  Future<bool> loginOrRegister(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userService.registerUser(phone);
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();
    final user = await _userService.getCurrentUser();
    if (user != null) {
      _user = user;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateUserProfile(
      String name, double acres, int experience) async {
    _isLoading = true;
    notifyListeners();
    final success = await _userService.updateProfile(name, acres, experience);
    if (success) {
      _user = await _userService.getCurrentUser(); // Refresh local data
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Auto-login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _userService.logout();
    _user = null;
    notifyListeners();
  }
}
