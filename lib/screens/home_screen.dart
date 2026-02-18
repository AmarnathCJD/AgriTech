import 'package:agri_tech_app/screens/market_intelligence_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'feature_screens.dart';
import 'additional_features_screen.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'crop_planning_screen.dart';
import '../services/location_service.dart';
import 'equipment/equipment_listing_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../providers/localization_provider.dart';
import 'live_crop_protection_screen.dart';
import 'community/community_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchUserLocation();
    });
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer<LocalizationProvider>(
        builder: (context, lang, child) => AlertDialog(
          title: Text(lang.t('select_location'),
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.t('search_city'),
                  style:
                      GoogleFonts.dmSans(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                Autocomplete<LocationSuggestion>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.length < 3) {
                      return const Iterable<LocationSuggestion>.empty();
                    }
                    return context
                        .read<LocationProvider>()
                        .searchLocations(textEditingValue.text);
                  },
                  displayStringForOption: (LocationSuggestion option) =>
                      option.displayName,
                  onSelected: (LocationSuggestion selection) {
                    context
                        .read<LocationProvider>()
                        .setLocationFromSuggestion(selection);
                    Navigator.pop(ctx);
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: lang.t('start_typing'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<LocationSuggestion> onSelected,
                      Iterable<LocationSuggestion> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: SizedBox(
                          height: 200.0,
                          width: 250, // Constrain width
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final LocationSuggestion option =
                                  options.elementAt(index);
                              return ListTile(
                                title: Text(option.displayName),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Professional Farmer-First Layout
    return Consumer<LocalizationProvider>(
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor:
              const Color(0xFFF8F5F2), // Very light warm grey/beige
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(
              lang.t('app_title'),
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
                tooltip: lang.t('alerts'),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Consumer<LocationProvider>(
                  builder: (context, provider, child) {
                    return Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showLocationDialog(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.isLoading
                                    ? lang.t('locating')
                                    : (provider.error != null
                                        ? lang.t('set_location')
                                        : provider.currentLocation),
                                style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white70, size: 20),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          provider.temperature,
                          style: GoogleFonts.dmSans(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.wb_sunny,
                            color: Colors.amber, size: 16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                _buildMarketTicker(context, lang),
                const SizedBox(height: 24),

                // Section 2: Core Services (Grid)
                Text(
                  "Smart Services",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildCreativeFeatureCard(
                      context,
                      title: "Market\nIntelligence",
                      subtitle: "Live Prices",
                      icon: Icons.analytics_outlined,
                      // Rich Emerald Green
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const MarketIntelligenceScreen())),
                    ),
                    _buildCreativeFeatureCard(
                      context,
                      title: "Crop\nPlanning",
                      subtitle: "AI Guide",
                      icon: Icons.grass_outlined,
                      // Deep Burnt Orange
                      gradient: const LinearGradient(
                          colors: [Color(0xFFBF360C), Color(0xFFE65100)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CropPlanningScreen())),
                    ),
                    _buildCreativeFeatureCard(
                      context,
                      title: "Harvest\nTiming",
                      subtitle: "Best Window",
                      icon: Icons.timer_outlined,
                      // Midnight Blue
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00363A), Color(0xFF006064)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HarvestTimingScreen())),
                    ),
                    _buildCreativeFeatureCard(
                      context,
                      title: "Live Crop\nProtection",
                      subtitle: "Weather Risks",
                      icon: Icons.shield_outlined,
                      // Dark Crimson
                      gradient: const LinearGradient(
                          colors: [Color(0xFF880E4F), Color(0xFFC2185B)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const LiveCropProtectionScreen())),
                    ),
                    _buildCreativeFeatureCard(
                      context,
                      title: "Equipment\nSharing",
                      subtitle: "Rentals",
                      icon: Icons.agriculture_outlined,
                      // Dark Espresso Brown
                      gradient: const LinearGradient(
                          colors: [Color(0xFF3E2723), Color(0xFF5D4037)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EquipmentListingScreen())),
                    ),
                    _buildCreativeFeatureCard(
                      context,
                      title: "Community\nForum",
                      subtitle: "Discuss",
                      icon: Icons.forum_outlined,
                      // Teal/Blue Gradient
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00695C), Color(0xFF00897B)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CommunityScreen())),
                    ),
                    _buildCreativeFeatureCard(
                      context,
                      title: "More\nServices",
                      subtitle: "Govt Schemes",
                      icon: Icons.grid_view,
                      // Deep Royal Purple
                      gradient: const LinearGradient(
                          colors: [Color(0xFF311B92), Color(0xFF4527A0)]),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AdditionalFeaturesScreen())),
                    ),
                  ],
                ).animate().slideY(begin: 0.1, end: 0).fadeIn(),

                const SizedBox(height: 24),

                // Section 3: Smart Advisory / Weather Insight
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E3C72),
                        Color(0xFF2A5298)
                      ], // Deep Blue Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3C72).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern (Decorative)
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.cloud,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: 20,
                        child: Icon(
                          Icons.water_drop,
                          size: 80,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: Colors.amberAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        lang.t('critical_alert'),
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "48 HRS",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang.t('heavy_rain'),
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lang.t('rain_warning'),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(
                                color: Colors.white.withOpacity(0.2),
                                height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  lang.t('tap_precautions'),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward,
                                    color: Colors.white, size: 18),
                              ],
                            ),
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
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MarketIntelligenceScreen()),
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              }
            },
            backgroundColor: Colors.white,
            elevation: 10,
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.home_filled), label: lang.t('home')),
              NavigationDestination(
                  icon: const Icon(Icons.trending_up), label: lang.t('market')),
              NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: lang.t('advisory')),
              NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  label: lang.t('profile')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketTicker(BuildContext context, LocalizationProvider lang) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // Allow shadows to show
        children: [
          _buildPriceCard(lang.t('wheat'), "₹2,100", "+2.5%", true),
          const SizedBox(width: 12),
          _buildPriceCard(lang.t('rice'), "₹1,950", "0%", false),
          const SizedBox(width: 12),
          _buildPriceCard(lang.t('mustard'), "₹4,800", "-1.2%", false,
              isDown: true),
          const SizedBox(width: 12),
          _buildPriceCard(lang.t('cotton'), "₹6,200", "+0.8%", true),
          const SizedBox(width: 12),
          _buildPriceCard(lang.t('soybean'), "₹3,400", "+1.5%", true),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String crop, String price, String change, bool isUp,
      {bool isDown = false}) {
    final color = isUp
        ? Colors.green[700]!
        : (isDown ? Colors.red[700]! : Colors.grey[700]!);
    final bgColor = isUp
        ? Colors.green[50]!
        : (isDown ? Colors.red[50]! : Colors.grey[100]!);
    final icon = isUp
        ? Icons.trending_up
        : (isDown ? Icons.trending_down : Icons.remove);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(crop,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 14)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          Text(price,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              change,
              style: GoogleFonts.dmSans(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Softer shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Stack(
            children: [
              // Decorative Background Icon (Faded)
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withOpacity(0.1), // Reduced opacity
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),

                    const Spacer(),

                    // Text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.white
                                .withOpacity(0.9), // Slightly clearer
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
