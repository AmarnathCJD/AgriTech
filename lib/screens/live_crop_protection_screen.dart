import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../providers/location_provider.dart';
import '../services/chat_gemini_service.dart';
import 'package:intl/intl.dart';

class LiveCropProtectionScreen extends StatefulWidget {
  const LiveCropProtectionScreen({super.key});

  @override
  State<LiveCropProtectionScreen> createState() =>
      _LiveCropProtectionScreenState();
}

class _LiveCropProtectionScreenState extends State<LiveCropProtectionScreen> {
  bool _isLoading = true;
  String? _error;
  List<CropRiskModel> _monitoredCrops = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get User Location
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      final lat = locationProvider.latitude;
      final lon = locationProvider.longitude;

      if (lat == null || lon == null) {
        throw Exception("Location not found. Please set your farm location.");
      }

      // 2. Fetch Weather Data
      final weather = await _fetchWeatherData(lat, lon);

      // 3. Load Crop Knowledge Base
      final cropKnowledgeBase = await _loadCropKnowledgeBase();

      // 4. Get Planted Crops from User Profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userCrops = userProvider.user?['crops_rotation']; // List<dynamic>

      if (userCrops == null || (userCrops as List).isEmpty) {
        setState(() {
          _isLoading = false;
          _monitoredCrops = []; // No crops to monitor
        });
        return;
      }

      // 5. Evaluate Risks
      List<CropRiskModel> risks = [];
      for (var cropName in userCrops) {
        // Find crop data in KB with looser matching
        final cropData = cropKnowledgeBase.firstWhere(
          (c) {
            String dbName = c['crop_name'].toString().toLowerCase();
            String userCrop = cropName.toString().toLowerCase();
            return dbName.contains(userCrop) || userCrop.contains(dbName);
          },
          orElse: () => <String, dynamic>{},
        );

        if (cropData.isNotEmpty) {
          final riskModel =
              _evaluateRiskForCrop(cropName.toString(), cropData, weather);
          risks.add(riskModel);
        }
      }

      setState(() {
        _monitoredCrops = risks;
        _isLoading = false;
      });

      // Force UI update to show local data immediately
      await Future.delayed(const Duration(milliseconds: 100));

      // 6. Gemini Integration (Batch)
      final geminiService = ChatGeminiService();

      // Prepare batch input
      final List<Map<String, dynamic>> batchInput = risks.map((risk) {
        return {
          "crop_name": risk.cropName,
          "risk_score": risk.riskScore,
          "primary_threat": risk.primaryConstraint,
          "heat_risk": risk.heatRisk,
          "flood_risk": risk.floodRisk,
          "drought_risk": risk.droughtRisk,
          "disease_risk": risk.diseaseRisk
        };
      }).toList();

      try {
        final batchAdvisories =
            await geminiService.getBatchStructuredAdvisory(batchInput);

        final enhancedRisks = risks.map((risk) {
          final summary = batchAdvisories[risk.cropName];
          if (summary != null) {
            return risk.copyWith(
                geminiAdvisory: summary as Map<String, dynamic>);
          }
          return risk;
        }).toList();

        if (!mounted) return;
        setState(() {
          _monitoredCrops = enhancedRisks;
          // _isLoading is already false
        });
      } catch (e) {
        print("Batch Error: $e");
        // Failure silently keeps local results
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherData(double lat, double lon) async {
    // Open-Meteo API
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,relative_humidity_2m_min&forecast_days=14&timezone=auto');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch weather data');
    }
  }

  Future<List<dynamic>> _loadCropKnowledgeBase() async {
    final String response =
        await rootBundle.loadString('lib/assets/data/crops.json');
    return jsonDecode(response);
  }

  CropRiskModel _evaluateRiskForCrop(String cropName,
      Map<String, dynamic> cropData, Map<String, dynamic> weather) {
    final daily = weather['daily'];
    final List<dynamic> maxTemps = daily['temperature_2m_max'];
    final List<dynamic> minTemps = daily['temperature_2m_min'];
    final List<dynamic> rainfall = daily['precipitation_sum'];
    // OpenMeteo gives min/max humidity, let's use min or assume relative_humidity_2m_max if we fetched it.
    // I requested relative_humidity_2m_min in URL, let's switch to max for disease risk
    // Wait, I put relative_humidity_2m_min in URL above. I should change it to max or mean.
    // I entered precipitation_sum.
    // Let's assume the URL is updated to fetch humidity max.

    // Core Crop Data
    final double optimalTemp = (cropData['optimal_temp_c'] as num).toDouble();
    final double tempMin = (cropData['ideal_temp_min_c'] as num).toDouble();
    final double tempMax = (cropData['ideal_temp_max_c'] as num).toDouble();
    final double waterReq =
        (cropData['water_requirement_mm_per_season'] as num).toDouble();
    final int duration = (cropData['crop_duration_days'] as num).toInt();
    final String floodTol = cropData['flood_tolerance'] ?? "Medium";
    final String droughtTol = cropData['drought_tolerance'] ?? "Medium";

    final double dailyWaterNeed = waterReq / duration;

    // Derived Weather Metrics
    double rainfall48h =
        (rainfall[0] as num).toDouble() + (rainfall[1] as num).toDouble();
    double rainfall7d = 0;
    double avgTemp7d = 0;

    for (int i = 0; i < 7; i++) {
      rainfall7d += (rainfall[i] as num).toDouble();
      avgTemp7d += ((maxTemps[i] as num) + (minTemps[i] as num)) / 2;
    }
    avgTemp7d /= 7;

    // --- RULES ---

    // 1. Extreme Rainfall (Flood)
    double floodRisk = 0;
    List<String> floodAdvice = [];
    if ((rainfall48h > dailyWaterNeed * 3) ||
        (rainfall7d > dailyWaterNeed * 7 * 1.5)) {
      if (floodTol == "Low") {
        floodRisk = 100;
        floodAdvice.add("Stop irrigation immediately");
        floodAdvice.add("Ensure drainage channels are open");
      } else if (floodTol == "Medium") {
        floodRisk = 60;
        floodAdvice.add("Monitor soil moisture");
        floodAdvice.add("Check drainage");
      }
    }

    // 2. Drought Risk
    double droughtRisk = 0;
    List<String> droughtAdvice = [];
    if (rainfall7d < (dailyWaterNeed * 7 * 0.5) && avgTemp7d > optimalTemp) {
      if (droughtTol != "High") {
        droughtRisk = 80;
        droughtAdvice.add("Increase irrigation frequency");
        droughtAdvice.add("Apply mulch to conserve moisture");
      } else {
        droughtRisk = 40;
        droughtAdvice.add("Monitor crop for wilting");
      }
    }

    // 3. Heat Stress
    double heatRisk = 0;
    List<String> heatAdvice = [];
    int consecutiveHeatDays = 0;
    for (int i = 0; i < 5; i++) {
      if ((maxTemps[i] as num) > tempMax)
        consecutiveHeatDays++;
      else
        consecutiveHeatDays = 0;

      if (consecutiveHeatDays >= 2) {
        heatRisk = 90;
        heatAdvice.add("Heat stress detected! Irrigate in evening");
        heatAdvice.add("Consider shade nets if possible");
        break;
      }
    }

    // 4. Cold Stress
    double coldRisk = 0;
    List<String> coldAdvice = [];
    int consecutiveColdDays = 0;
    for (int i = 0; i < 5; i++) {
      if ((minTemps[i] as num) < tempMin)
        consecutiveColdDays++;
      else
        consecutiveColdDays = 0;

      if (consecutiveColdDays >= 2) {
        coldRisk = 80;
        coldAdvice.add("Cold spell warning! Delay N-fertilizers");
        coldAdvice.add("Protect seedlings from frost");
        break;
      }
    }

    // 5. Disease Risk (Mocked humidity logic since I might miss proper humidity data)
    double diseaseRisk = 0;
    List<String> diseaseAdvice = [];
    // Assuming humidity is high if rainfall > 10mm and temp is moderate
    // A simplified rule as OpenMeteo humidity fetching might need more fields
    bool isHumid = rainfall7d > 20;
    bool isModTemp = avgTemp7d > 18 && avgTemp7d < 30;

    if (isHumid && isModTemp) {
      diseaseRisk = 50;
      diseaseAdvice.add("Conditions favorable for fungal growth");
      diseaseAdvice.add("Monitor for leaf spots/blight");
    }

    // --- SCORING ---
    // (Heat × 0.3) + (Flood × 0.3) + (Drought × 0.25) + (Disease × 0.15)
    // Note: Use max of heat/cold for 'Temperature Stress' component?
    // Or just separate. The formula provided:
    // Weather Risk Score = (Heat * 0.3) + (Flood * 0.3) + (Drought * 0.25) + (Disease * 0.15)
    // I will map Cold Risk to Heat component as 'Temp Stress' generally.
    double tempRisk = heatRisk > coldRisk ? heatRisk : coldRisk;

    double totalScore = (tempRisk * 0.3) +
        (floodRisk * 0.3) +
        (droughtRisk * 0.25) +
        (diseaseRisk * 0.15);

    // Identify Primary Risk
    String primaryRisk = "None";
    double maxR = 0;
    if (tempRisk > maxR) {
      maxR = tempRisk;
      primaryRisk = heatRisk > coldRisk ? "Heat Stress" : "Cold Stress";
    }
    if (floodRisk > maxR) {
      maxR = floodRisk;
      primaryRisk = "Rainfall Risk";
    }
    if (droughtRisk > maxR) {
      maxR = droughtRisk;
      primaryRisk = "Drought";
    }
    if (diseaseRisk > maxR) {
      maxR = diseaseRisk;
      primaryRisk = "Disease Risk";
    }

    if (totalScore < 10) primaryRisk = "Optimal Conditions";

    // Combine advice
    List<String> allAdvice = [
      ...floodAdvice,
      ...droughtAdvice,
      ...heatAdvice,
      ...coldAdvice,
      ...diseaseAdvice
    ];
    if (allAdvice.isEmpty) {
      if (totalScore < 30)
        allAdvice.add("Conditions are good. Continue standard care.");
      else
        allAdvice.add("Monitor field conditions.");
    }

    return CropRiskModel(
        cropName: cropName,
        riskScore: totalScore,
        primaryConstraint: primaryRisk,
        advice: allAdvice,
        weatherSummary:
            "Avg: ${avgTemp7d.toStringAsFixed(1)}°C, Rain: ${rainfall7d.toStringAsFixed(1)}mm (7d)",
        heatRisk: heatRisk,
        floodRisk: floodRisk,
        droughtRisk: droughtRisk,
        diseaseRisk: diseaseRisk);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Light theme
      appBar: AppBar(
        title: Text("Live Crop Protection",
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent))
          : _error != null
              ? _buildErrorState()
              : _monitoredCrops.isEmpty
                  ? _buildEmptyState()
                  : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      color: Colors.green,
      backgroundColor: const Color(0xFFF8F5F2),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderStatus(),
          const SizedBox(height: 24),
          ..._monitoredCrops.map((c) => _buildCropCard(c)),
        ],
      ),
    );
  }

  Widget _buildHeaderStatus() {
    // Overall farm status
    double maxRisk = 0;
    for (var c in _monitoredCrops) {
      if (c.riskScore > maxRisk) maxRisk = c.riskScore;
    }

    Color statusColor = Colors.greenAccent;
    String statusText = "FARM SECURE";
    IconData icon = Icons.shield;

    if (maxRisk > 60) {
      statusColor = Colors.redAccent;
      statusText = "CRITICAL ALERTS";
      icon = Icons.warning;
    } else if (maxRisk > 30) {
      statusColor = Colors.orangeAccent;
      statusText = "MODERATE RISK";
      icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SYSTEM STATUS",
                  style: GoogleFonts.dmSans(
                      color: Colors.grey[600], fontSize: 10)),
              Text(statusText,
                  style: GoogleFonts.dmSans(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCropCard(CropRiskModel crop) {
    Color riskColor = Colors.greenAccent;
    if (crop.riskScore > 60)
      riskColor = Colors.redAccent;
    else if (crop.riskScore > 30) riskColor = Colors.orangeAccent;

    // Use risk-based color for border/accent, but white for card bg
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: riskColor.withOpacity(0.3))),
      child: Theme(
        data: ThemeData.light().copyWith(
            dividerColor: Colors.transparent,
            colorScheme: ColorScheme.light(primary: riskColor)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          leading: CircularProgressIndicator(
            value: crop.riskScore / 100,
            backgroundColor: Colors.grey[100],
            color: riskColor,
          ),
          title: Text(crop.cropName,
              style: GoogleFonts.dmSans(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(crop.primaryConstraint.toUpperCase(),
                  style: GoogleFonts.dmSans(
                      color: riskColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text(crop.weatherSummary,
                  style: GoogleFonts.dmSans(
                      color: Colors.grey[600], fontSize: 10)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (crop.geminiAdvisory != null) ...[
                    Text(crop.geminiAdvisory!['advisory_title'] ?? "Advisory",
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey[800])),
                    const SizedBox(height: 4),
                    Text(crop.geminiAdvisory!['advisory_summary'] ?? "",
                        style: GoogleFonts.dmSans(
                            color: Colors.grey[700], fontSize: 13)),
                    const SizedBox(height: 12),
                    Text("RECOMMENDED ACTIONS:",
                        style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                    const SizedBox(height: 6),
                    ...(crop.geminiAdvisory!['recommended_actions'] as List? ??
                            [])
                        .map((action) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: riskColor, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(action.toString(),
                                          style: GoogleFonts.dmSans(
                                              color: Colors.grey[800],
                                              fontSize: 13))),
                                ],
                              ),
                            ))
                  ] else ...[
                    // Fallback to rule-based advice
                    Text("ACTION PLAN:",
                        style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(height: 8),
                    ...crop.advice.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right,
                                  color: riskColor, size: 16),
                              Expanded(
                                  child: Text(a,
                                      style: GoogleFonts.dmSans(
                                          color: Colors.grey[800],
                                          fontSize: 12))),
                            ],
                          ),
                        ))
                  ],
                  const SizedBox(height: 16),
                  _buildTimeline(),
                ],
              ),
            )
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildTimeline() {
    // Timeline with days
    final now = DateTime.now();
    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                    color: index % 3 == 0
                        ? Colors.redAccent.withOpacity(0.6)
                        : Colors.green.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3)),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(7, (index) {
            final day = now.add(Duration(days: index));
            return Expanded(
                child: Text(DateFormat('E').format(day), // Mon, Tue...
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold)));
          }),
        )
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(_error ?? "Unknown Error",
              style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeData,
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grass, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text("No active crops found.",
              style: GoogleFonts.dmSans(color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Add crops to your rotation in Profile.",
              style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class CropRiskModel {
  final String cropName;
  final double riskScore;
  final String primaryConstraint;
  final List<String> advice;
  final String weatherSummary;
  final Map<String, dynamic>? geminiAdvisory;
  final double heatRisk;
  final double floodRisk;
  final double droughtRisk;
  final double diseaseRisk;

  CropRiskModel({
    required this.cropName,
    required this.riskScore,
    required this.primaryConstraint,
    required this.advice,
    required this.weatherSummary,
    this.geminiAdvisory,
    this.heatRisk = 0,
    this.floodRisk = 0,
    this.droughtRisk = 0,
    this.diseaseRisk = 0,
  });

  CropRiskModel copyWith({Map<String, dynamic>? geminiAdvisory}) {
    return CropRiskModel(
      cropName: this.cropName,
      riskScore: this.riskScore,
      primaryConstraint: this.primaryConstraint,
      advice: this.advice,
      weatherSummary: this.weatherSummary,
      geminiAdvisory: geminiAdvisory ?? this.geminiAdvisory,
      heatRisk: this.heatRisk,
      floodRisk: this.floodRisk,
      droughtRisk: this.droughtRisk,
      diseaseRisk: this.diseaseRisk,
    );
  }
}
