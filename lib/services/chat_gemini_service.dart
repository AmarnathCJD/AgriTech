import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatGeminiService {
  late final GenerativeModel _model;

  static const _systemPrompt = '''
You are an intelligent agricultural assistant and mobile app controller for "Farmora".

Tasks:
1. Detect user language.
2. Translate to English for reasoning.
3. Identify intent (Market, Crop, Harvest, etc.).
4. Respond in user's original language.
5. Return STRICT JSON.

Mapping Rules:
- mandi/prices -> MARKET_INTELLIGENCE
- crop/planning -> CROP_PLANNING
- harvest -> HARVEST_TIMING
- insurance/risk -> INSURANCE
- equipment/tractor -> EQUIPMENT_RENTAL
- storage/warehouse -> STORAGE
- govt schemes/subsidy -> GOVT_SCHEMES
- profile/account -> PROFILE
- weather -> WEATHER
- unknown -> HELP

JSON Format:
{
  "detected_language": "string",
  "translated_query": "string",
  "intent": "string",
  "target_page": "string",
  "response_message": "string"
}
''';

  ChatGeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    _model = GenerativeModel(
      model: 'gemini-flash-latest', // Faster model
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.2, // Low temp for stability
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<Map<String, dynamic>> sendMessage(String userMessage,
      [List<Map<String, String>>? history]) async {
    // Construct chat history for the API
    final chatHistory = history?.map((m) {
          if (m['role'] == 'User') {
            return Content.text(m['text']!);
          } else {
            return Content.model([TextPart(m['text']!)]);
          }
        }).toList() ??
        [];

    // Add current message
    chatHistory.add(Content.text(userMessage));

    try {
      // Use generateContent for single turn or startChat for multi-turn.
      // Since we manage history manually for distinct sessions, we can just send the sequence.
      // But generateContent expects a list of contents which represents the history?
      // No, generateContent isn't chat aware in the same way startChat is.
      // However, passing the whole list to generateContent is effective for stateless.
      // Actually, standard usage is `_model.startChat(history: ...).sendMessage(...)`
      // But sticking to stateless `generateContent` with manual history context is fine for this robust controller logic.
      // The prompt structure in original code was just concatenating text.
      // Let's stick to the previous text-based concatenation if we want to be safe,
      // OR better, use the proper Content objects as I did above if the API supports it in a single call?
      // Actually, generateContent takes `Iterable<Content> prompt`.

      final response = await _model.generateContent(chatHistory);
      var responseText = response.text;

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      // Cleanups
      responseText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      return jsonDecode(responseText);
    } catch (e) {
      print('Gemini API Error: $e');
      return {
        "target_page": "HELP",
        "response_message": "Sorry, I encountered an error. Please try again."
      };
    }
  }
}
