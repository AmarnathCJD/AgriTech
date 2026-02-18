import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Keep this if used, otherwise remove
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'feature_screens.dart';
import 'additional_features_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmora Dashboard"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: "Alerts",
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Market Snapshot (Horizontal Scroll)
            _buildMarketTicker(context),
            const SizedBox(height: 24),

            // Main Features Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildFeatureCard(
                  context,
                  title: "Market Intelligence",
                  icon: Icons.analytics_rounded,
                  color: Colors.blueGrey,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MarketIntelligenceScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Crop Planning",
                  icon: Icons.grass_rounded,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CropPlanningScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Harvest Timing",
                  icon: Icons.timer_rounded,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HarvestTimingScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Risk Calculator",
                  icon: Icons.shield_rounded,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RiskCalculatorScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "Equipment Sharing",
                  icon: Icons.agriculture_rounded,
                  color: Colors.brown,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EquipmentScreen())),
                ),
                _buildFeatureCard(
                  context,
                  title: "More Features",
                  icon: Icons.grid_view_rounded,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdditionalFeaturesScreen())),
                ),
              ],
            ).animate().slideY(begin: 0.1, end: 0).fadeIn(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: "Home"),
          NavigationDestination(icon: Icon(Icons.trending_up), label: "Market"),
          NavigationDestination(icon: Icon(Icons.people), label: "Community"),
        ],
      ),
    );
  }

  Widget _buildMarketTicker(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildTickerItem("Wheat", "₹2,100", "+2.5%", true),
          const SizedBox(width: 24),
          _buildTickerItem("Rice", "₹1,950", "0%", false),
          const SizedBox(width: 24),
          _buildTickerItem("Mustard", "₹4,800", "-1.2%", false, isDown: true),
          const SizedBox(width: 24),
          _buildTickerItem("Cotton", "₹6,200", "+0.8%", true),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTickerItem(String crop, String price, String change, bool isUp,
      {bool isDown = false}) {
    // Using Theme colors instead of neon accents
    final upColor = Colors.green[400];
    final downColor = Colors.red[400];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(crop, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Row(
          children: [
            Text(price,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(
              isUp
                  ? Icons.arrow_upward
                  : (isDown ? Icons.arrow_downward : Icons.remove),
              color: isUp ? upColor : (isDown ? downColor : Colors.grey),
              size: 16,
            ),
            Text(
              change,
              style: TextStyle(
                color: isUp ? upColor : (isDown ? downColor : Colors.grey),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
