import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/harvest_provider.dart';

class HarvestResultScreen extends StatelessWidget {
  const HarvestResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HarvestProvider>();
    final result = provider.result;
    final maturity = provider.maturityData;
    final weather = provider.weatherData;

    if (result == null || maturity == null || weather == null) {
      return const Scaffold(
        body: Center(child: Text("No result data")),
      );
    }

    final double maturityPercent = maturity['maturity_percent'];
    final String recommendation = result.recommendation.toUpperCase();

    // Determine Color Scheme based on recommendation
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (recommendation.contains("WAIT")) {
      statusColor = Colors.green;
      statusIcon = Icons.hourglass_bottom_rounded;
    } else if (recommendation.contains("HIGH RISK")) {
      statusColor = Colors.red[900]!;
      statusIcon = Icons.warning_rounded;
    } else if (recommendation.contains("HARVEST NOW")) {
      statusColor = Colors.red;
      statusIcon = Icons.agriculture_rounded; // Or sickle icon if available
    } else {
      // Medium risk or unknown
      statusColor = Colors.amber[800]!;
      statusIcon = Icons.info_outline;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text("Harvest Analysis",
            style: GoogleFonts.playfairDisplay(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Crop & Maturity Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Crop",
                                style: GoogleFonts.dmSans(color: Colors.grey)),
                            Text(provider.selectedCrop ?? "Crop",
                                style: GoogleFonts.dmSans(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Days Since Sowing",
                                style: GoogleFonts.dmSans(color: Colors.grey)),
                            Text("${maturity['days_since_sowing']} Days",
                                style: GoogleFonts.dmSans(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Maturity",
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold)),
                            Text("$maturityPercent%",
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: maturityPercent / 100,
                          backgroundColor: Colors.grey[200],
                          color: maturityPercent > 85
                              ? Colors.green
                              : Colors.orange,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // 2. Weather Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_queue, size: 32, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Weather Outlook (5 Days)",
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900])),
                          const SizedBox(height: 4),
                          Text(
                            "Rain Prob: ${weather['max_rain_prob_5days']}% | Wind: ${weather['max_wind_speed_5days']} km/h",
                            style: GoogleFonts.dmSans(color: Colors.blue[800]),
                          ),
                          if (weather['storm_alert'] == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text("STORM ALERT ACTIVE",
                                  style: GoogleFonts.dmSans(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // 3. Recommendation Box (Big & Bold)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Icon(statusIcon, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.result!
                        .recommendation, // Should limit length or handle wrap
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.result!.maturityStatus,
                    style: GoogleFonts.dmSans(
                        color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ).animate().scale(delay: 200.ms),

            const SizedBox(height: 24),

            // 4. Reasoning & Advice
            Text("Analysis & Advice",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reasoning",
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(result.reasoning,
                      style: GoogleFonts.dmSans(height: 1.5)),
                  const Divider(height: 24),
                  Text("Farmer Advice",
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(result.farmerAdvice,
                      style: GoogleFonts.dmSans(height: 1.5)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.refresh),
                label: const Text("Check Another Crop"),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
