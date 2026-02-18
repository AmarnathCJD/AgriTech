import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSuggestion {
  final String name;
  final String region;
  final String country;
  final double latitude;
  final double longitude;

  LocationSuggestion({
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  String get displayName {
    if (region.isNotEmpty) {
      return "$name, $region";
    }
    return "$name, $country";
  }

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      name: json['name'] ?? '',
      region: json['admin1'] ?? '', // Admin1 usually holds state/region
      country: json['country'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
    );
  }
}

class LocationService {
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Prioritize locality, then subAdministrativeArea
        String locality = place.locality?.isNotEmpty == true
            ? place.locality!
            : (place.subAdministrativeArea?.isNotEmpty == true
                ? place.subAdministrativeArea!
                : "Unknown");

        String adminArea = place.administrativeArea ?? "";

        if (adminArea.isNotEmpty) {
          return "$locality, $adminArea";
        }
        return locality;
      }
    } catch (e) {
      // debugPrint('Error getting address: $e');
    }
    return "Unknown Location";
  }

  Future<List<LocationSuggestion>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10&language=en&format=json');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('results')) {
          final List results = data['results'];
          return results.map((e) => LocationSuggestion.fromJson(e)).toList();
        }
      }
    } catch (e) {
      // debugPrint("Error searching places: $e");
    }
    return [];
  }
}
