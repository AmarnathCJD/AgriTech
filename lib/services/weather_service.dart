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
        print("Error fetching weatherr: $e");
      }
      return "--°C"; // Return placeholder on error
    }
  }

  Future<Map<String, dynamic>> fetchWeatherForecast(
      double lat, double lon) async {
    try {
      final url = Uri.parse(
          '$_baseUrl?latitude=$lat&longitude=$lon&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max&forecast_days=14&timezone=auto');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];

        List<double> maxTemps = List<double>.from(daily['temperature_2m_max']);
        List<double> minTemps = List<double>.from(daily['temperature_2m_min']);
        List<double> rainfall = List<double>.from(daily['precipitation_sum']);

        // New fields
        List<int?> rainProbs =
            List<int?>.from(daily['precipitation_probability_max']);
        List<double> windSpeeds =
            List<double>.from(daily['wind_speed_10m_max']);

        double avgTemp = (maxTemps.reduce((a, b) => a + b) +
                minTemps.reduce((a, b) => a + b)) /
            (maxTemps.length * 2);
        double totalRainfall = rainfall.reduce((a, b) => a + b);

        // Calculate max rain prob in next 5 days
        int maxRainProb5Days = 0;
        double maxWindSpeed5Days = 0.0;

        for (int i = 0; i < 5 && i < rainProbs.length; i++) {
          if (rainProbs[i] != null && rainProbs[i]! > maxRainProb5Days) {
            maxRainProb5Days = rainProbs[i]!;
          }
          if (windSpeeds[i] > maxWindSpeed5Days) {
            maxWindSpeed5Days = windSpeeds[i];
          }
        }

        return {
          "avg_temp": "${avgTemp.round()}°C",
          "total_rainfall_mm": totalRainfall.toStringAsFixed(1),
          "max_rain_prob_5days": maxRainProb5Days,
          "max_wind_speed_5days": maxWindSpeed5Days,
          "storm_alert":
              maxWindSpeed5Days > 50 || maxRainProb5Days > 80, // Basic rule
          "raw_rainfall": rainfall,
        };
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching forecast: $e");
      }
      return {
        "avg_temp": "25°C",
        "total_rainfall_mm": "0.0",
        "max_rain_prob_5days": 0,
        "max_wind_speed_5days": 0.0,
        "storm_alert": false,
        "raw_rainfall": [],
      };
    }
  }
}
