import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("GEMINI_API_KEY is missing in .env file");
    }
    _model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'));
  }

  Future<Map<String, dynamic>> checkCropFeasibility(
    Map<String, dynamic> userInputs,
    Map<String, dynamic> weatherSummary,
    Map<String, dynamic> districtMarketData,
    List<dynamic> cropDataset,
  ) async {
    try {
      final prompt = _buildPrompt(
          userInputs, weatherSummary, districtMarketData, cropDataset);

      print("--- GENERATED GEMINI PROMPT ---");
      _printLog(prompt);
      print("-------------------------------");

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception("Empty response from AI");
      }

      print("Gemini Response: ${response.text}"); // Debug log

      // Parse JSON response
      final jsonResponse = jsonDecode(response.text!);
      return jsonResponse;
    } catch (e) {
      print("Gemini Error: $e");
      // Fallback or rethrow
      throw Exception("Failed to generate crop plan: $e");
    }
  }

  void _printLog(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
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
