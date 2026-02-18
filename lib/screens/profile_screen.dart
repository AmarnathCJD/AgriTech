import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch location provider for changes
    final locationProvider = context.watch<LocationProvider>();
    final currentLocation = locationProvider.currentLocation;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final name = user?['name'] ?? "Guest Farmer";
        final acres = user?['acres_land']?.toString() ?? "--";
        final experience = user?['years_experience']?.toString() ?? "--";
        final phone = user?['mobile_number'] ?? "";

        // Dynamic crops from user profile if available, else fallback
        final crops = user?['crops_rotation'] != null
            ? List<String>.from(user!['crops_rotation'])
            : ["Wheat", "Rice"];

        // Determine verification status: Verified if location is set
        final isVerified = currentLocation != "Fetching..." &&
            currentLocation != "Set Location";

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
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () => _showEditProfileDialog(context, userProvider),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () {
                  userProvider.logout();
                  // Navigate to LoginScreen, clearing stack
                  // We need to import LoginScreen but we can use Named routes or just push unique
                  // Since circular dependency might be an issue if not careful, we'll pop to root
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (ctx) => const LoginScreen()));
                },
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
                                    "https://ui-avatars.com/api/?name=User&background=2E7D32&color=fff&size=200"),
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
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone.isNotEmpty ? "+91 $phone" : "Agri-Entrepreneur",
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ... (Location Row) ...
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
                              style:
                                  GoogleFonts.dmSans(color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Language Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<LocalizationProvider>(
                    builder: (context, provider, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.t('language'),
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: provider.currentLocale.languageCode,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: provider.languages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang['code'],
                                  child: Text(
                                    lang['name']!,
                                    style: GoogleFonts.dmSans(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  provider.setLocale(Locale(newValue));
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
                      _buildStatCard(
                          "Total Land", "$acres Acres", Icons.landscape),
                      _buildStatCard(
                          "Experience", "$experience Years", Icons.history_edu),
                      _buildStatCard(
                          "Member", "Since 2026", Icons.star_outline),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Detailed Info Section
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
                            // Crops Section Header
                            InkWell(
                              onTap: () =>
                                  _showEditCropsDialog(context, userProvider),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.grass,
                                          color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Crops in Rotation",
                                          style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                    ],
                                  ),
                                  const Icon(Icons.edit,
                                      size: 18, color: Colors.grey),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                children: crops
                                    .map((c) => Chip(
                                          label: Text(c,
                                              style: GoogleFonts.dmSans(
                                                  fontSize: 12)),
                                          backgroundColor: Colors.green[50],
                                        ))
                                    .toList(),
                              ),
                            ),
                            const Divider(height: 24),
                            // Keeping soil/irrigation hardcoded or dependent on location for now as API doesn't return them yet
                            _buildDetailRow("Soil Type", "Loamy/Black",
                                Icons.terrain, Colors.brown),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final user = userProvider.user;
    final nameCtrl = TextEditingController(text: user?['name'] ?? "");
    final acresCtrl =
        TextEditingController(text: user?['acres_land']?.toString() ?? "");
    final expCtrl = TextEditingController(
        text: user?['years_experience']?.toString() ?? "");

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (ctx) => Consumer<UserProvider>(
        builder: (context, provider, child) {
          return AlertDialog(
            title: const Text("Update Profile"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: "Full Name")),
                  const SizedBox(height: 16),
                  TextField(
                      controller: acresCtrl,
                      decoration:
                          const InputDecoration(labelText: "Land Size (Acres)"),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(
                      controller: expCtrl,
                      decoration: const InputDecoration(
                          labelText: "Experience (Years)"),
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed:
                      provider.isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final acres = double.tryParse(acresCtrl.text) ?? 0.0;
                          final exp = int.tryParse(expCtrl.text) ?? 0;
                          final success = await provider.updateUserProfile(
                              nameCtrl.text, acres, exp);
                          if (success && ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Save"))
            ],
          );
        },
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

  void _showEditCropsDialog(BuildContext context, UserProvider provider) {
    final user = provider.user;
    List<String> currentCrops = user?['crops_rotation'] != null
        ? List<String>.from(user!['crops_rotation'])
        : [];

    final List<String> availableCrops = [
      "Wheat",
      "Rice",
      "Maize",
      "Cotton",
      "Sugarcane",
      "Soybean",
      "Vegetables",
      "Pulses",
      "Tomato",
      "Potato",
      "Onion"
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer<UserProvider>(
        builder: (context, provider, child) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Crops Rotation"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: availableCrops.map((crop) {
                        final isSelected = currentCrops.contains(crop);
                        return FilterChip(
                          label: Text(crop),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                currentCrops.add(crop);
                              } else {
                                currentCrops.remove(crop);
                              }
                            });
                          },
                          selectedColor: Colors.green[100],
                          checkmarkColor: Colors.green[800],
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.green[900]
                                  : Colors.black),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed:
                        provider.isLoading ? null : () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            final success =
                                await provider.updateUserCrops(currentCrops);
                            if (success && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text("Save"))
              ],
            );
          });
        },
      ),
    );
  }
}
