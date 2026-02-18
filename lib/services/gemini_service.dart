import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/harvest_recommendation.dart';

class GeminiService {
  static const String _modelName = 'gemini-flash-latest';

  Future<HarvestRecommendation> getHarvestRecommendation({
    required String cropType,
    required int daysAfterSowing,
    required double maturityPercent,
    required String location,
    required String rainProb, // e.g. "45"
    required String windSpeed, // e.g. "12"
    required bool stormAlert,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) print("GEMINI_API_KEY is missing");
        return HarvestRecommendation.fallback(
            "Error: GEMINI_API_KEY is missing");
      }

      final model = GenerativeModel(model: _modelName, apiKey: apiKey);

      final prompt = '''
You are an agricultural advisory AI specialized in Indian farming conditions.

Analyze the farm data below and provide a harvest recommendation.

FARM DATA:
Crop Type: $cropType
Days Since Sowing: $daysAfterSowing
Maturity Percentage: $maturityPercent%
Location: $location
Rain Probability (Next 5 Days): $rainProb%
Wind Speed: $windSpeed km/h
Storm Alert: $stormAlert

Decision Rules:
1. If maturity < 70%, recommend WAIT.
2. If maturity between 70% and 85%, analyze weather and decide.
3. If maturity > 85% and rain_probability > 60%, recommend HARVEST NOW.
4. If storm alert is true and maturity > 80%, recommend HIGH RISK – HARVEST IMMEDIATELY.
5. Otherwise recommend WAIT.

Return STRICT JSON in this format:

{
  "maturity_status": "Brief status (e.g. Early Stage, Maturing, Ready)",
  "weather_risk_level": "LOW | MEDIUM | HIGH",
  "recommendation": "HARVEST NOW | WAIT | HIGH RISK – HARVEST IMMEDIATELY",
  "reasoning": "Short explanation",
  "farmer_advice": "Practical advice"
}
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) {
        return HarvestRecommendation.fallback("Error: Empty response from AI");
      }

      return HarvestRecommendation.fromRawJson(response.text!);
    } catch (e) {
      if (kDebugMode) {
        print("Gemini API Error: $e");
      }
      return HarvestRecommendation.fallback("Error: ${e.toString()}");
    }
  }

  // Restored method for CropPlanningProvider
  Future<Map<String, dynamic>?> checkCropFeasibility(
      Map<String, dynamic> userInputs,
      Map<String, dynamic> weatherSummary,
      Map<String, dynamic> marketSummary,
      List<dynamic> cropDataset) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      final model = GenerativeModel(model: _modelName, apiKey: apiKey);

      final prompt = '''
You are an expert agronomist. Analyze the following data to recommend the best crops.

User Inputs: $userInputs
Weather: $weatherSummary
Market: $marketSummary
Available Crops to consider: ${cropDataset.map((e) => e['crop_name']).join(', ')}

Provide a feasibility report in JSON format:
{
  "best_crop": "Name",
  "confidence": "High/Medium/Low",
  "reasoning": "...",
  "risks": "..."
}
''';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) return null;

      // Basic cleanup
      String clean =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return json.decode(clean);
    } catch (e) {
      if (kDebugMode) print("Gemini Planning Error: $e");
      return null;
    }
  }
}
