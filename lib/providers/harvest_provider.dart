import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/gemini_service.dart';
import '../services/gemini_service.dart';
import '../utils/crop_maturity_calculator.dart';
import '../models/harvest_recommendation.dart';

class HarvestProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final GeminiService _geminiService = GeminiService();

  // Inputs
  String? _selectedCrop;
  DateTime? _sowingDate;
  String _locationName = "";
  double? _lat;
  double? _lon;

  // State
  bool _isLoading = false;
  String? _error;
  HarvestRecommendation? _result;
  Map<String, dynamic>? _maturityData;
  Map<String, dynamic>? _weatherData;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  HarvestRecommendation? get result => _result;
  Map<String, dynamic>? get maturityData => _maturityData;
  Map<String, dynamic>? get weatherData => _weatherData;

  String? get selectedCrop => _selectedCrop;
  DateTime? get sowingDate => _sowingDate;
  String get locationName => _locationName;

  void setCrop(String? crop) {
    _selectedCrop = crop;
    notifyListeners();
  }

  void setSowingDate(DateTime? date) {
    _sowingDate = date;
    notifyListeners();
  }

  void setLocation(String name, double lat, double lon) {
    _locationName = name;
    _lat = lat;
    _lon = lon;
    notifyListeners();
  }

  Future<void> checkHarvestStatus() async {
    if (_selectedCrop == null ||
        _sowingDate == null ||
        _lat == null ||
        _lon == null) {
      _error = "Please fill all fields";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      // 1. Calculate Maturity
      _maturityData = CropMaturityCalculator.calculateMaturity(
          _selectedCrop!, _sowingDate!);

      if (_maturityData!['error'] != null) {
        throw Exception(_maturityData!['error']);
      }

      // 2. Fetch Weather
      _weatherData = await _weatherService.fetchWeatherForecast(_lat!, _lon!);

      // 3. Get Gemini Recommendation
      _result = await _geminiService.getHarvestRecommendation(
        cropType: _selectedCrop!,
        daysAfterSowing: _maturityData!['days_since_sowing'],
        maturityPercent: _maturityData!['maturity_percent'],
        location: _locationName,
        rainProb: _weatherData!['max_rain_prob_5days'].toString(),
        windSpeed: _weatherData!['max_wind_speed_5days'].toString(),
        stormAlert: _weatherData!['storm_alert'] ?? false,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _error = null;
    _weatherData = null;
    _maturityData = null;
    notifyListeners();
  }
}
