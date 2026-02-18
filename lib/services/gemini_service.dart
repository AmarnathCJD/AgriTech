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

      print("--- GENERATED GEMINI PROMPT ---");
      _printLog(prompt);
      print("-------------------------------");

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

  void _printLog(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  void _printLog(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
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
  String _buildPrompt(
    Map<String, dynamic> inputs,
    Map<String, dynamic> weather,
    Map<String, dynamic> market,
    List<dynamic> crops,
  ) {
    return """
    You are an expert agronomist advisor for Indian farmers. 
    Analyze the following data and recommend the top 3 most suitable crops.

    # FARM DATA:
    - Location: ${inputs['location'] ?? 'Unknown'}
    - Soil Type: ${inputs['soil_type']}
    - Soil pH: ${inputs['soil_ph'] ?? 'N/A'}
    - Land Size: ${inputs['land_size']} acres
    - Irrigation Available: ${inputs['irrigation']}
    - Previous Crop: ${inputs['previous_crop']}

    # WEATHER FORECAST (Next 14 Days):
    - Avg Temp: ${weather['avg_temp']}
    - Total Rainfall: ${weather['total_rainfall_mm']}mm

    # MARKET TRENDS (Current District Prices):
    ${jsonEncode(market['commodities'])}

    # AVAILABLE CROP DATASET (JSON):
    ${jsonEncode(crops.take(15).toList())} 
    (Note: This is a subset of local crops. You may recommend others if highly suitable but prioritize these if they fit.)

    # TASK:
    1. The user's previous crop was "${inputs['target_crop'] ?? 'None'}". Evaluate if it is suitable to plant AGAIN in the upcoming season. Include it in the list with a recommendation.
    2. Recommend 2-3 other most suitable crops based on soil, season, and market trends.
    3. Generate a 'suitability_score_percent' (0-100) for each.
    4. Provide specific risk warnings if risk > 30%.

    # OUTPUT FORMAT (Strict JSON):
    {
      "recommendations": [
        {
          "crop_name": "Name",
          "suitability_score_percent": 90,
          "climate_compatibility_percent": 85,
          "market_momentum_percent": 80,
          "yield_potential_percent": 95,
          "risk_percent": 10,
          "risk_reason": "High humidity may cause fungal issues.",
          "harvest_duration_days": 120,
          "summary_reasoning": "Detailed explanation...",
          "recommendation": "Highly Recommended"
        }
      ]
    }
    """;
  }
}
