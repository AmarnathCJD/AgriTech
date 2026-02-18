import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/government_scheme.dart';

class SchemeService {
  Future<List<GovernmentScheme>> getSchemes() async {
    try {
      final String response = await rootBundle
          .loadString('lib/assets/data/government_schemes.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => GovernmentScheme.fromJson(json)).toList();
    } catch (e) {
      // Return empty list or throw error depending on needs
      print("Error loading schemes: $e");
      return [];
    }
  }
}
