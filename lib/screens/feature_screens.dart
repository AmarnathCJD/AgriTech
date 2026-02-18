import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Market Intelligence Screen ---
class MarketIntelligenceScreen extends StatelessWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Market Intelligence")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, "Live Mandi Prices"),
          _buildMarketCard(
              "Wheat (Sharbati)", "₹2,100/qt", "+2.5%", Colors.green),
          _buildMarketCard("Rice (Basmati)", "₹3,950/qt", "0%", Colors.grey),
          _buildMarketCard("Mustard", "₹4,800/qt", "-1.2%", Colors.red),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Price Trends (AI Prediction)"),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart_rounded,
                      size: 48, color: Colors.blueGrey),
                  const SizedBox(height: 8),
                  Text("Price Graph Placeholder",
                      style: GoogleFonts.dmSans(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ].animate(interval: 100.ms).fadeIn().slideX(),
      ),
    );
  }

  Widget _buildMarketCard(
      String crop, String price, String change, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.grass, color: color),
        ),
        title: Text(crop, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Mandi: Azadpur, Delhi"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(change, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- AI Crop Planning Screen ---
class CropPlanningScreen extends StatelessWidget {
  const CropPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Crop Planner")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.hub_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      "Analyzing Soil Data...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Based on N-P-K values and 15-day rain forecast",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text("Recommended Crops",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildRecommendationCard(
                      "Sugarcane", "98% Match", "High Profit", Colors.green),
                  _buildRecommendationCard(
                      "Cotton", "85% Match", "Medium Risk", Colors.orange),
                  _buildRecommendationCard(
                      "Maize", "70% Match", "Low Water Req", Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      String crop, String match, String tag, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.eco, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crop,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(match,
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(tag,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// --- Smart Harvest Timing Screen ---
class HarvestTimingScreen extends StatelessWidget {
  const HarvestTimingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Harvest Timing")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text("Optimal Harvest Window",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("Nov 15 - Nov 20",
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 16),
                  Expanded(
                      child: Text(
                          "Rain expected on Nov 22. Better to harvest early.")),
                ],
              ),
            ),
          ],
        ).animate().scale(),
      ),
    );
  }
}

// --- Risk Calculator Screen ---
class RiskCalculatorScreen extends StatelessWidget {
  const RiskCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Risk & Insurance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.redAccent.withOpacity(0.1),
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    const Text("Farm Risk Score",
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text("7.2 / 10",
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    const Text("High Risk (Flood Prone)",
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Recommended Insurance"),
            _buildInsuranceCard("PM Fasal Bima Yojana", "Premium: ₹1,200/acre",
                "Cover: ₹40,000"),
            _buildInsuranceCard("Private Agro Shield", "Premium: ₹1,500/acre",
                "Cover: ₹55,000"),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(String name, String premium, String cover) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.security, size: 32, color: Colors.blueGrey),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(premium),
            Text(cover, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
          ),
          child: const Text("Apply"),
        ),
      ),
    );
  }
}

// --- Equipment Sharing Screen ---
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Equipment Sharing")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Rent Out My Tractor"),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Search tractors, harvesters...",
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          _buildTractorCard("John Deere 5310", "3km away", "₹800/hr", 4.8),
          _buildTractorCard("Mahindra Yuvo", "1.5km away", "₹750/hr", 4.5),
          _buildTractorCard("Sonalika Tiger", "5km away", "₹900/hr", 4.9),
        ],
      ),
    );
  }

  Widget _buildTractorCard(
      String name, String dist, String price, double rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 120,
            color: Colors.grey[300],
            child: const Center(
                child: Icon(Icons.agriculture, size: 64, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(dist, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(rating.toString()),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}
