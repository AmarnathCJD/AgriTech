import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/harvest_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/crop_maturity_calculator.dart';
import 'harvest_result_screen.dart';

class HarvestTimingScreen extends StatefulWidget {
  const HarvestTimingScreen({super.key});

  @override
  State<HarvestTimingScreen> createState() => _HarvestTimingScreenState();
}

class _HarvestTimingScreenState extends State<HarvestTimingScreen> {
  final _locationController =
      TextEditingController(); // For manual input display

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locProvider = context.read<LocationProvider>();
      final harvestProvider = context.read<HarvestProvider>();

      harvestProvider.reset();

      if (locProvider.currentLocation != "Fetching..." &&
          locProvider.currentLocation != "Set Location") {
        _locationController.text = locProvider.currentLocation;

        // Auto-set location in provider if we have coordinates
        if (locProvider.latitude != null && locProvider.longitude != null) {
          harvestProvider.setLocation(locProvider.currentLocation,
              locProvider.latitude!, locProvider.longitude!);
        }
      }
    });
  }

  Future<void> _submit() async {
    final provider = context.read<HarvestProvider>();
    final locProvider = context.read<LocationProvider>();

    // 1. Ensure provider has location if input field is filled
    if (provider.locationName.isEmpty && _locationController.text.isNotEmpty) {
      // If the text matches LocationProvider, rely on it
      if (_locationController.text == locProvider.currentLocation &&
          locProvider.latitude != null) {
        provider.setLocation(locProvider.currentLocation, locProvider.latitude!,
            locProvider.longitude!);
      } else {
        // Manual entry without geocoding support in this screen yet.
        // Improvement: Add Geocoding here or show error.
        // For now, if no coordinates, we can't proceed.
        if (provider.locationName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Please verify location using the icon"),
                backgroundColor: Colors.orange),
          );
          return;
        }
      }
    }

    // 2. Default fallback to current user location if everything empty
    if (provider.locationName.isEmpty) {
      if (locProvider.latitude != null) {
        provider.setLocation(locProvider.currentLocation, locProvider.latitude!,
            locProvider.longitude!);
        _locationController.text = locProvider.currentLocation;
      } else {
        // Try fetch
        await locProvider.fetchUserLocation();
        if (locProvider.latitude != null) {
          provider.setLocation(locProvider.currentLocation,
              locProvider.latitude!, locProvider.longitude!);
          _locationController.text = locProvider.currentLocation;
        }
      }
    }

    await provider.checkHarvestStatus();

    if (mounted && provider.result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HarvestResultScreen()),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HarvestProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Harvest Check",
            style: GoogleFonts.playfairDisplay(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Get AI-powered harvest advice based on crop maturity and weather.",
              style: GoogleFonts.dmSans(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),

            // 1. SELECT CROP
            Text("Select Crop",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.selectedCrop,
                  hint: const Text("Choose Crop"),
                  isExpanded: true,
                  icon: const Icon(Icons.agriculture),
                  items: CropMaturityCalculator.cropDurations.keys.map((crop) {
                    return DropdownMenuItem(value: crop, child: Text(crop));
                  }).toList(),
                  onChanged: (val) => provider.setCrop(val),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. SOWING DATE
            Text("Sowing Date",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: provider.sowingDate ??
                      DateTime.now().subtract(const Duration(days: 60)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  provider.setSowingDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      provider.sowingDate == null
                          ? "Select Date"
                          : DateFormat('dd MMM yyyy')
                              .format(provider.sowingDate!),
                      style: GoogleFonts.dmSans(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. LOCATION
            Text("Farm Location",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: "Enter location",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (val) {
                      // Note: Logic to update provider location pending geocoding
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    // Quick logic to get location and set it in provider
                    final locProvider = context.read<LocationProvider>();
                    await locProvider.fetchUserLocation();

                    if (locProvider.latitude != null &&
                        locProvider.longitude != null) {
                      _locationController.text = locProvider.currentLocation;
                      provider.setLocation(locProvider.currentLocation,
                          locProvider.latitude!, locProvider.longitude!);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.my_location,
                        color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("CHECK HARVEST STATUS",
                        style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
