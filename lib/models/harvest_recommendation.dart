import 'dart:convert';

class HarvestRecommendation {
  final String maturityStatus;
  final String weatherRiskLevel;
  final String recommendation; // 'HARVEST NOW', 'WAIT', 'HIGH RISK...'
  final String reasoning;
  final String farmerAdvice;

  HarvestRecommendation({
    required this.maturityStatus,
    required this.weatherRiskLevel,
    required this.recommendation,
    required this.reasoning,
    required this.farmerAdvice,
  });

  factory HarvestRecommendation.fromJson(Map<String, dynamic> json) {
    return HarvestRecommendation(
      maturityStatus: json['maturity_status'] ?? 'Unknown',
      weatherRiskLevel: json['weather_risk_level'] ?? 'LOW',
      recommendation: json['recommendation'] ?? 'WAIT',
      reasoning: json['reasoning'] ?? '',
      farmerAdvice: json['farmer_advice'] ?? '',
    );
  }

  factory HarvestRecommendation.fallback([String? errorMessage]) {
    return HarvestRecommendation(
      maturityStatus: 'Analysis Failed',
      weatherRiskLevel: 'UNKNOWN',
      recommendation: 'Check Manually',
      reasoning: errorMessage ??
          'We could not analyze the data at this moment. Please check network connection.',
      farmerAdvice: 'Consult local agricultural officer if unsure.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maturity_status': maturityStatus,
      'weather_risk_level': weatherRiskLevel,
      'recommendation': recommendation,
      'reasoning': reasoning,
      'farmer_advice': farmerAdvice,
    };
  }

  // Safe helper to parse from raw string which might contain markdown ```json ... ```
  static HarvestRecommendation fromRawJson(String raw) {
    try {
      String clean = raw.trim();
      if (clean.startsWith('```json')) {
        clean = clean.replaceAll('```json', '').replaceAll('```', '');
      } else if (clean.startsWith('```')) {
        clean = clean.replaceAll('```', '');
      }
      return HarvestRecommendation.fromJson(jsonDecode(clean));
    } catch (e) {
      return HarvestRecommendation.fallback();
    }
  }
}
