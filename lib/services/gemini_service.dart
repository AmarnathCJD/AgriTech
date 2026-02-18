class GeminiService {
  // Represents a mock or real Gemini integration
  // For this demo, we will simulate the Gemini response logic based on the prompt structure
  // In a real app, this would use google_generative_ai package

  Future<Map<String, dynamic>> checkCropFeasibility(
    Map<String, dynamic> userInputs,
    Map<String, dynamic> weatherSummary,
    Map<String, dynamic> districtMarketData,
    List<dynamic> cropDataset,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // MOCK LOGIC for demonstration purposes (since we don't have a live API key)
    // This replicates what the prompt asks Gemini to do

    List<Map<String, dynamic>> recommendations = [];
    String soilType = userInputs['soil_type'];
    double? ph = double.tryParse(userInputs['soil_ph'] ?? '');

    // Filter and score crops
    for (var crop in cropDataset) {
      // 1. Filter by Soil
      List<dynamic> suitableSoils = crop['suitable_soil_types'] ?? [];
      if (!suitableSoils.contains(soilType)) {
        continue; // Skip if soil doesn't match
      }

      // 2. Filter by pH (loose filter)
      if (ph != null) {
        double minPh = (crop['ideal_ph_min'] as num).toDouble();
        double maxPh = (crop['ideal_ph_max'] as num).toDouble();
        // Allow a small buffer of 0.5
        if (ph < minPh - 0.5 || ph > maxPh + 0.5) {
          continue;
        }
      }

      // 3. Compute Scores (Simulated)
      double idealTemp = (crop['optimal_temp_c'] as num).toDouble();
      double currentTemp = double.tryParse(
              weatherSummary['avg_temp']?.toString().replaceAll('°C', '') ??
                  '25') ??
          25;
      double diff = (idealTemp - currentTemp).abs();

      // Climate Score (closer temp is better)
      double climateScore = (100 - (diff * 5)).clamp(0, 100);

      // Market Momentum (Randomized for demo or based on static logic)
      // In real app, this comes from market data trend analysis
      double marketScore = 70 + (crop['crop_name'].toString().length % 30);

      // Risk (Inverse of water req for drought, simple logic)
      double riskScore = 80;
      int water = crop['water_requirement_mm_per_season'] as int;
      if (water > 800) riskScore -= 20; // High water risk

      // Final Weighted Score
      double finalScore =
          (climateScore * 0.4) + (marketScore * 0.4) + (riskScore * 0.2);

      recommendations.add({
        "crop_name": crop['crop_name'],
        "suitability_score_percent": finalScore.round(),
        "climate_compatibility_percent": climateScore.round(),
        "market_momentum_percent": marketScore.round(),
        "yield_potential_percent": 85, // Placeholder
        "risk_percent": (100 - riskScore).round(),
        "harvest_duration_days": crop['crop_duration_days'],
        "summary_reasoning":
            "Strong match for $soilType soil. Temperature is within optimal range (${crop['ideal_temp_min_c']}-${crop['ideal_temp_max_c']}°C). Market demand is stable.",
        "recommendation": finalScore > 85
            ? "Highly Recommended"
            : (finalScore > 70 ? "Recommended" : "Average")
      });
    }

    // Sort by score
    recommendations.sort((a, b) => b['suitability_score_percent']
        .compareTo(a['suitability_score_percent']));

    // Take top 3 or user filtered
    return {"recommendations": recommendations.take(3).toList()};
  }
}
