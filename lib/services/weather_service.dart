import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<String> fetchTemperature(double lat, double lon) async {
    try {
      final url = Uri.parse(
          '$_baseUrl?latitude=$lat&longitude=$lon&current=temperature_2m');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final temp = current['temperature_2m'];
        // Round to integer for cleaner display
        return "${temp.round()}°C";
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching weather: $e");
      }
      return "--°C"; // Return placeholder on error
    }
  }
}
