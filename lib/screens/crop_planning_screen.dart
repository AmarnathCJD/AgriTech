import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/crop_planning_provider.dart';

class CropPlanningScreen extends StatefulWidget {
  const CropPlanningScreen({super.key});

  @override
  State<CropPlanningScreen> createState() => _CropPlanningScreenState();
}

class _CropPlanningScreenState extends State<CropPlanningScreen> {
  @override
  void initState() {
    super.initState();
    // Load crop data if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CropPlanningProvider>().loadCropData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<CropPlanningProvider>();
    final locator = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
          title: const Text("AI Crop Planner"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0),
      body: planner.aiResults != null
          ? _buildResultsView(context, planner)
          : _buildInputForm(context, planner, locator),
    );
  }

  Widget _buildInputForm(BuildContext context, CropPlanningProvider planner,
      LocationProvider locator) {
    if (planner.isLoading) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text("Analyzing Soil & Market Data...",
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Location & Weather Summary (Auto-fetched)
        _buildInfoCard(locator),
        const SizedBox(height: 16),

        Text("Farm Details",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Soil Type Dropdown
        DropdownButtonFormField<String>(
          value: planner.soilType,
          decoration: _inputDecoration("Soil Type"),
          items: ["Alluvial", "Clay", "Loamy", "Sandy", "Sandy Loam", "Black"]
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) => planner.setSoilType(val),
        ),
        const SizedBox(height: 16),

        // Irrigation Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Irrigation Available?",
                  style: GoogleFonts.dmSans(fontSize: 16)),
              Switch(
                value: planner.irrigationAvailable,
                onChanged: (val) => planner.setIrrigation(val),
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Previous Crop
        DropdownButtonFormField<String>(
          value: planner.previousCrop,
          decoration: _inputDecoration("Previous Crop"),
          items: planner.cropDataset
              .map((c) => c['crop_name'].toString())
              .toSet()
              .map((name) {
            return DropdownMenuItem(value: name, child: Text(name));
          }).toList(),
          onChanged: (val) => planner.setPreviousCrop(val),
        ),
        const SizedBox(height: 16),

        // Numeric Fields Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Soil pH (Optional)"),
                onChanged: (val) => planner.setSoilPh(val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Land Size (Acres)"),
                onChanged: (val) => planner.setLandSize(val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (planner.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Text(planner.error!, style: const TextStyle(color: Colors.red)),
          ),

        ElevatedButton(
          onPressed: () => planner.generatePlan(locator),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("GENERATE AI PLAN",
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ]),
    );
  }

  Widget _buildResultsView(BuildContext context, CropPlanningProvider planner) {
    final results = planner.aiResults!['recommendations'] as List;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Top AI Recommendations",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                  "Based on your soil, market trends & 14-day rainfall forecast.",
                  style: GoogleFonts.dmSans(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ...results.map((rec) => _buildDetailedCard(rec, context)),
              const SizedBox(height: 80), // Space for fab
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          left: 24,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<CropPlanningProvider>().resetPlan();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("START NEW PLAN"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDetailedCard(Map<String, dynamic> data, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.grass, color: Colors.green.shade700),
          ),
          title: Text(data['crop_name'],
              style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text(
              "Suitability Score: ${data['suitability_score_percent']}%",
              style: GoogleFonts.dmSans(
                  color: Colors.green.shade700, fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildStatRow(
                "Climate Match",
                "${data['climate_compatibility_percent']}%",
                Icons.wb_sunny_outlined,
                Colors.orange),
            _buildStatRow(
                "Market Momentum",
                "${data['market_momentum_percent']}%",
                Icons.trending_up,
                Colors.blue),
            _buildStatRow(
                "Yield Potential",
                "${data['yield_potential_percent']}%",
                Icons.spa_outlined,
                Colors.green),
            _buildStatRow("Risk Factor", "${data['risk_percent']}% Safe",
                Icons.shield_outlined, Colors.purple),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(data['summary_reasoning'],
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(LocationProvider loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Farm Location",
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 12)),
                Text(loc.currentLocation,
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Temp/Weather",
                  style:
                      GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
              Text(loc.temperature,
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
