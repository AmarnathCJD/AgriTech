import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  static const String _prefsKeyLocation = 'user_location';
  static const String _prefsKeyTemp = 'user_temperature';
  static const String _prefsKeyLat = 'user_lat';
  static const String _prefsKeyLon = 'user_lon';

  LocationProvider() {
    _loadSavedData();
  }

  String _currentLocation = "Fetching...";
  String _temperature = "--°C";
  bool _isLoading = false;
  String? _error;
  double? _latitude;
  double? _longitude;

  String get currentLocation => _currentLocation;
  String get temperature => _temperature;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString(_prefsKeyLocation);
      final savedTemp = prefs.getString(_prefsKeyTemp);
      final savedLat = prefs.getDouble(_prefsKeyLat);
      final savedLon = prefs.getDouble(_prefsKeyLon);

      if (savedLocation != null && savedLocation.isNotEmpty) {
        _currentLocation = savedLocation;
      }
      if (savedTemp != null && savedTemp.isNotEmpty) {
        _temperature = savedTemp;
      }
      if (savedLat != null) _latitude = savedLat;
      if (savedLon != null) _longitude = savedLon;

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading saved data: $e");
    }
  }

  Future<void> _saveData(String location, String temperature,
      [double? lat, double? lon]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyLocation, location);
      await prefs.setString(_prefsKeyTemp, temperature);
      if (lat != null) await prefs.setDouble(_prefsKeyLat, lat);
      if (lon != null) await prefs.setDouble(_prefsKeyLon, lon);
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  Future<void> fetchUserLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Position position = await _locationService.determinePosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      String address = await _locationService.getAddressFromPosition(position);

      _currentLocation = address;
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Fetch weather using coordinates
      try {
        String temp = await _weatherService.fetchTemperature(
            position.latitude, position.longitude);
        _temperature = temp;
      } catch (weatherError) {
        debugPrint("Weather fetch error: $weatherError");
      }

      _saveData(_currentLocation, _temperature, _latitude, _longitude);
    } catch (e) {
      _error = e.toString();
      // If we have a saved location, keep it. Only set "Set Location" if we are still at default.
      if (_currentLocation == "Fetching...") {
        _currentLocation = "Set Location";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setManualLocation(String location) async {
    _isLoading = true;
    notifyListeners();

    _currentLocation = location;

    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        _latitude = locations[0].latitude;
        _longitude = locations[0].longitude;

        String temp =
            await _weatherService.fetchTemperature(_latitude!, _longitude!);
        _temperature = temp;
      }
    } catch (e) {
      debugPrint("Error fetching weather for manual location: $e");
      _temperature = "--°C";
    }

    _saveData(_currentLocation, _temperature, _latitude, _longitude);
    _isLoading = false;
    notifyListeners();
  }

  Future<List<LocationSuggestion>> searchLocations(String query) async {
    return _locationService.searchPlaces(query);
  }

  Future<void> setLocationFromSuggestion(LocationSuggestion suggestion) async {
    _isLoading = true;
    notifyListeners();

    _currentLocation = suggestion.displayName;
    _latitude = suggestion.latitude;
    _longitude = suggestion.longitude;

    try {
      String temp = await _weatherService.fetchTemperature(
          suggestion.latitude, suggestion.longitude);
      _temperature = temp;
    } catch (e) {
      debugPrint("Error fetching weather for suggestion: $e");
      _temperature = "--°C";
    }

    _saveData(_currentLocation, _temperature, _latitude, _longitude);
    _isLoading = false;
    notifyListeners();
  }
}
