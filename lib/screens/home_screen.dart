import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'feature_screens.dart';
import 'additional_features_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Professional Farmer-First Layout
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Very light warm grey/beige
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Farmora",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_active_outlined,
                color: Colors.white),
            tooltip: "Alerts",
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Satara, Maharashtra",
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  "28°C",
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.wb_sunny, color: Colors.amber, size: 16),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Market Ticker (Vital Info)
            Text(
              "Mandi Prices (Live)",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
            ),
            const SizedBox(height: 12),
            _buildMarketTicker(context),
            const SizedBox(height: 24),

            // Section 2: Core Services (Grid)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Smart Services",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
                TextButton(onPressed: () {}, child: const Text("View All")),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1, // Slightly wider for better text fit
              children: [
                _buildFeatureCard(
                  context,
                  title: "Market\nIntelligence",
                  subtitle: "Prices & Trends",
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF2E7D32), // Green
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MarketIntelligenceScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Crop\nPlanning",
                  subtitle: "AI Recommendations",
                  icon: Icons.grass_outlined,
                  color: const Color(0xFFF57F17), // Amber/Orange
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CropPlanningScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Harvest\nTiming",
                  subtitle: "Best time to cut",
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF00838F), // Cyan
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HarvestTimingScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Risk\nCalculator",
                  subtitle: "Insurance & Safety",
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFC62828), // Red
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RiskCalculatorScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Equipment\nSharing",
                  subtitle: "Rent Tractors",
                  icon: Icons.agriculture_outlined,
                  color: const Color(0xFF5D4037), // Brown
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EquipmentScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "More\nServices",
                  subtitle: "Govt Schemes & More",
                  icon: Icons.grid_view,
                  color: const Color(0xFF4527A0), // Purple
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdditionalFeaturesScreen())),
                ),
              ],
            ).animate().slideY(begin: 0.1, end: 0).fadeIn(),

            const SizedBox(height: 24),

            // Section 3: Daily Insight / Advisory
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_cloudy_outlined,
                      size: 32, color: Colors.blueAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monsoon Alert",
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                            "Heavy rains expected in 48hrs. Secure your harvest.",
                            style: GoogleFonts.dmSans(
                                color: Colors.grey[700], fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        elevation: 10,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: "Home"),
          NavigationDestination(icon: Icon(Icons.trending_up), label: "Mandi"),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: "Advisory"),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildMarketTicker(BuildContext context) {
    return Container(
      height: 90,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildTickerItem("Wheat", "₹2,100", "+2.5%", true),
          const VerticalDivider(indent: 10, endIndent: 10),
          _buildTickerItem("Rice", "₹1,950", "0%", false),
          const VerticalDivider(indent: 10, endIndent: 10),
          _buildTickerItem("Mustard", "₹4,800", "-1.2%", false, isDown: true),
          const VerticalDivider(indent: 10, endIndent: 10),
          _buildTickerItem("Cotton", "₹6,200", "+0.8%", true),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTickerItem(String crop, String price, String change, bool isUp,
      {bool isDown = false}) {
    final color = isUp
        ? Colors.green[700]
        : (isDown ? Colors.red[700] : Colors.grey[700]);
    final icon = isUp
        ? Icons.arrow_drop_up
        : (isDown ? Icons.arrow_drop_down : Icons.remove);

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(crop,
              style: GoogleFonts.dmSans(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(price,
              style: GoogleFonts.dmSans(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              Text(change,
                  style: GoogleFonts.dmSans(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
