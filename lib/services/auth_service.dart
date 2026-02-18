import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentMobileNumber;

  String? get currentMobileNumber => _currentMobileNumber;
  bool get isLoggedIn => _currentMobileNumber != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentMobileNumber = prefs.getString('owner_mobile_number');
  }

  Future<void> login(String mobileNumber) async {
    _currentMobileNumber = mobileNumber;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owner_mobile_number', mobileNumber);
  }

  Future<void> logout() async {
    _currentMobileNumber = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('owner_mobile_number');
  }
}
