import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/equipment_model.dart';
import 'dart:developer';

class EquipmentService {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';

  Future<List<Equipment>> fetchNearbyEquipment({
    required double lat,
    required double long,
    double radiusKm = 50.0,
    String? equipmentType,
  }) async {
    String query =
        '$baseUrl/uber/equipment/nearby?lat=$lat&long=$long&radius_km=$radiusKm';
    if (equipmentType != null &&
        equipmentType.isNotEmpty &&
        equipmentType != 'All') {
      query += '&equipment_type=$equipmentType';
    }
    final url = Uri.parse(query);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Equipment.fromJson(e)).toList();
      } else {
        log('Failed to load equipment: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load equipment');
      }
    } catch (e) {
      log('Error fetching equipment: $e');
      return [];
    }
  }

  Future<bool> registerEquipmentByMobile(
      EquipmentCreateByMobile equipment) async {
    final url = Uri.parse('$baseUrl/uber/equipment/register-by-mobile');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(equipment.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        log('Failed to register equipment: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error registering equipment: $e');
      return false;
    }
  }

  Future<Equipment?> fetchEquipmentDetails(String id) async {
    final url = Uri.parse('$baseUrl/uber/equipment/$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return Equipment.fromJson(json.decode(response.body));
      }
    } catch (e) {
      log('Error fetching equipment details: $e');
    }
    return null;
  }

  Future<List<Equipment>> fetchMyEquipment(String mobileNumber) async {
    final url = Uri.parse(
        '$baseUrl/uber/equipment/my-listings?mobile_number=$mobileNumber');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Equipment.fromJson(e)).toList();
      } else {
        log('Failed to load my equipment: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error fetching my equipment: $e');
      return [];
    }
  }

  Future<bool> deleteEquipment(String id, String mobileNumber) async {
    final url =
        Uri.parse('$baseUrl/uber/equipment/$id?mobile_number=$mobileNumber');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      log('Error deleting equipment: $e');
      return false;
    }
  }
}
