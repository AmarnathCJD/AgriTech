import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Helper to determine farm details based on location string
  Map<String, String> _getFarmDetails(String location) {
    final loc = location.toLowerCase();

    if (loc.contains("punjab") || loc.contains("haryana")) {
      return {
        "primary": "Wheat",
        "secondary": "Rice",
        "soil": "Alluvial Soil",
        "irrigation": "Tube Well"
      };
    } else if (loc.contains("maharashtra") || loc.contains("gujarat")) {
      return {
        "primary": "Cotton",
        "secondary": "Sugarcane",
        "soil": "Black Soil (Regur)",
        "irrigation": "Drip System"
      };
    } else if (loc.contains("kerala") || loc.contains("tamil nadu")) {
      return {
        "primary": "Paddy (Rice)",
        "secondary": "Coconut",
        "soil": "Red Laterite Soil",
        "irrigation": "Canal Irrigation"
      };
    } else if (loc.contains("andhra") ||
        loc.contains("telangana") ||
        loc.contains("guntur")) {
      return {
        "primary": "Guntur Chillies",
        "secondary": "Cotton",
        "soil": "Black Cotton Soil",
        "irrigation": "Drip System"
      };
    } else if (loc.contains("karnataka")) {
      return {
        "primary": "Ragi (Millet)",
        "secondary": "Sugarcane",
        "soil": "Red Soil",
        "irrigation": "Rainfed/Borewell"
      };
    } else {
      // Default / Fallback
      return {
        "primary": "Mixed Crops",
        "secondary": "Vegetables",
        "soil": "Loamy Soil",
        "irrigation": "Standard"
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch location provider for changes
    final locationProvider = context.watch<LocationProvider>();
    final currentLocation = locationProvider.currentLocation;

    // Get dynamic details
    final details = _getFarmDetails(currentLocation);

    // Determine verification status: Verified if location is set
    final isVerified =
        currentLocation != "Fetching..." && currentLocation != "Set Location";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text("My Profile",
            style: GoogleFonts.playfairDisplay(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 3),
                          image: const DecorationImage(
                            image: NetworkImage(
                                "https://ui-avatars.com/api/?name=Bava+Gireesh&background=2E7D32&color=fff&size=200"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified,
                                color: Colors.white, size: 20),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Bava Gireesh",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Agri-Entrepreneur & Farmer",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on,
                          size: 16,
                          color: isVerified ? Colors.green : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          currentLocation == "Fetching..." ||
                                  currentLocation == "Set Location"
                              ? "Location not set"
                              : currentLocation,
                          style: GoogleFonts.dmSans(color: Colors.grey[700])),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Farm Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatCard("Total Land", "5 Acres", Icons.landscape),
                  _buildStatCard("Experience", "10 Years", Icons.history_edu),
                  _buildStatCard("Member Since", "2021", Icons.star_outline),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed Info Section (DYNAMIC)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Farm Overview",
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Primary Crop", details["primary"]!,
                            Icons.local_fire_department, Colors.red),
                        const Divider(height: 24),
                        _buildDetailRow("Secondary Crop", details["secondary"]!,
                            Icons.grass, Colors.grey),
                        const Divider(height: 24),
                        _buildDetailRow("Soil Type", details["soil"]!,
                            Icons.terrain, Colors.brown),
                        const Divider(height: 24),
                        _buildDetailRow("Irrigation", details["irrigation"]!,
                            Icons.water_drop, Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Recent Activity",
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _buildActivityItem(
                    "Harvested 20 Quintals of ${details['secondary']}", // Dynamic crop name
                    "Nov 15, 2025",
                    Icons.inventory_2_outlined,
                  ),
                  _buildActivityItem(
                    "Soil Test Completed",
                    "Oct 20, 2025",
                    Icons.science_outlined,
                  ),
                  _buildActivityItem(
                    "Purchased 50kg Fertilizer",
                    "Oct 05, 2025",
                    Icons.shopping_bag_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.green[700], size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    GoogleFonts.dmSans(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(date,
                    style:
                        GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
