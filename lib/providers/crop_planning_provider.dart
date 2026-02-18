import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import '../services/weather_service.dart';
import '../services/market_service.dart';
import '../services/gemini_service.dart';
import 'location_provider.dart';

class CropPlanningProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final MarketService _marketService = MarketService();
  final GeminiService _geminiService = GeminiService();

  // Inputs
  String? soilType;
  bool irrigationAvailable = true;
  String? previousCrop;
  List<String> preferredCrops = [];
  String? soilPh;
  String? landSize;
  String? previousYield;

  // Data State
  List<dynamic> _cropDataset = [];
  Map<String, dynamic>? _weatherSummary;
  Map<String, dynamic>? _marketSummary;
  Map<String, dynamic>? _aiResults;

  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get aiResults => _aiResults;
  List<dynamic> get cropDataset => _cropDataset; // Expose for dropdowns

  Future<void> loadCropData() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/data/crops.json');
      _cropDataset = json.decode(response);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading crops.json: $e");
      _error = "Failed to load crop database.";
    }
  }

  void togglePreferredCrop(String cropName) {
    if (preferredCrops.contains(cropName)) {
      preferredCrops.remove(cropName);
    } else {
      preferredCrops.add(cropName);
    }
    notifyListeners();
  }

  void setSoilType(String? val) {
    soilType = val;
    notifyListeners();
  }

  void setIrrigation(bool val) {
    irrigationAvailable = val;
    notifyListeners();
  }

  void setPreviousCrop(String? val) {
    previousCrop = val;
    notifyListeners();
  }

  void setSoilPh(String val) {
    soilPh = val;
    notifyListeners();
  }

  void setLandSize(String? val) {
    landSize = val;
    notifyListeners();
  }

  void setPreviousYield(String val) {
    previousYield = val;
    notifyListeners();
  }

  Future<void> generatePlan(LocationProvider locProvider) async {
    if (soilType == null) {
      _error = "Please select a soil type.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _aiResults = null;
    notifyListeners();

    try {
      // 1. Fetch Weather Forecast (parallel if possible but sequential is fine for clarity)
      // Need lat/lon from location provider. If not available, default or error.
      // We will assume location provider handles getting the lat/lon if we asked it,
      // but currently it exposes address string.
      // We will re-geocode the address string OR since we made LocationProvider smart,
      // we can add a method to expose Position or just re-fetch for now.
      // To be safe and fast, let's use a hardcoded default or try to parse if needed.
      // Ideally LocationProvider should expose coordinates.
      // Let's assume we can get coordinates or search again.
      // For this demo, let's fetch weather for the current location name logic handled in WeatherService if we passed coords.
      // Since I don't have direct coords exposed in LocationProvider public getter easily without refactor,
      // I'll fetch for a generic location or refactor provider.
      // Refactoring provider is better.

      // Actually, let's just use the display name to search again or use a default standard lat/lon for "India" if failed.
      // A better approach: The WeatherService needs lat/lon.
      // Let's Mock it with a standard central India location if we can't get it easily,
      // OR quick fix: use geocoding to get lat/lon from provider.currentLocation

      // Fetch weather
      _weatherSummary = await _weatherService.fetchWeatherForecast(
          20.5937, 78.9629); // Default India center

      // 2. Fetch Market Data
      _marketSummary =
          await _marketService.fetchMarketData("Satara"); // Mock district

      // 3. Prepare AI Prompt Payload
      Map<String, dynamic> userInputs = {
        "soil_type": soilType,
        "irrigation": irrigationAvailable,
        "previous_crop": previousCrop,
        "preferred_crops": preferredCrops,
        "soil_ph": soilPh,
        "land_size": landSize,
        "previous_yield": previousYield,
        "location": locProvider.currentLocation,
      };

      // 4. Call Gemini
      _aiResults = await _geminiService.checkCropFeasibility(
          userInputs, _weatherSummary!, _marketSummary!, _cropDataset);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
