class MarketService {
  // Simulates fetching market data from AGMARKNET
  // In a real app with access, this would be an HTTP call

  Future<Map<String, dynamic>> fetchMarketData(String district) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network

    // MOCK DATA
    return {
      "district": district,
      "updated_at": DateTime.now().toIso8601String(),
      "commodities": [
        {"name": "Rice", "price": 2500, "trend": "up", "percentile": 85},
        {"name": "Wheat", "price": 2100, "trend": "stable", "percentile": 70},
        {"name": "Cotton", "price": 6200, "trend": "up", "percentile": 90},
        {"name": "Maize", "price": 1800, "trend": "down", "percentile": 40},
        {
          "name": "Sugarcane",
          "price": 300,
          "trend": "stable",
          "percentile": 80
        },
      ]
    };
  }
}
