class CropMaturityCalculator {
  // Crop duration in days
  static const Map<String, int> cropDurations = {
    'Wheat': 120,
    'Rice': 135,
    'Cotton': 160,
    'Maize': 110,
    'Sugarcane': 365,
    'Soybean': 90,
    'Mustard': 110,
    'Potato': 100,
    'Tomato': 110,
    'Onion': 120,
  };

  /// Returns the maturity percentage (0-100) and days since sowing.
  static Map<String, dynamic> calculateMaturity(
      String cropType, DateTime sowingDate) {
    // 1. Validate inputs
    if (!cropDurations.containsKey(cropType)) {
      // Default to a medium duration if unknown, or handle error.
      // For now, let's treat unknown as 120 days.
      // Ideally we should throw or return error, but UI will likely limit choices.
    }

    final int duration = cropDurations[cropType] ?? 120;
    final DateTime now = DateTime.now();

    // 2. Calculate days
    // Reset times to noon to avoid timezone/midnight edge cases affecting simple day count
    final date1 =
        DateTime.utc(sowingDate.year, sowingDate.month, sowingDate.day);
    final date2 = DateTime.utc(now.year, now.month, now.day);

    final int daysSinceSowing = date2.difference(date1).inDays;

    if (daysSinceSowing < 0) {
      return {
        'days_since_sowing': 0,
        'maturity_percent': 0.0,
        'error': 'Sowing date is in the future'
      };
    }

    // 3. Calculate percentage
    double percent = (daysSinceSowing / duration) * 100;
    if (percent > 100) percent = 100;
    if (percent < 0) percent = 0;

    return {
      'days_since_sowing': daysSinceSowing,
      'maturity_percent':
          double.parse(percent.toStringAsFixed(1)), // Keep 1 decimal
      'total_duration': duration
    };
  }
}
