import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  // Fetch from .env
  String get baseUrl => dotenv.env['BACKEND_URL']!;

  Future<Map<String, dynamic>?> registerUser(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_number': mobileNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveUserPhone(mobileNumber);
        return data; // Returns the user object
      } else {
        print('Registration failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  Future<bool> updateProfile(
      String name, double acresLand, int yearsExperience) async {
    try {
      final phone = await _getSavedPhone();
      if (phone == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/updateprofile'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Phone': phone,
        },
        body: jsonEncode({
          'name': name,
          'acres_land': acresLand,
          'years_experience': yearsExperience,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> updateCrops(List<String> userCrops) async {
    try {
      final phone = await _getSavedPhone();
      if (phone == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/updatecrops'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Phone': phone,
        },
        body: jsonEncode({'crops_rotation': userCrops}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating crops: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final phone = await _getSavedPhone();
      if (phone == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'X-User-Phone': phone},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Backend says "User not registered" or unauthorized
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> _saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
  }

  Future<String?> _getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_phone');
  }
}
