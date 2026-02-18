import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'widgets/chat_floating_button.dart';

// Market Intelligence Screen moved to lib/screens/market_intelligence_screen.dart

export 'harvest/harvest_timing_screen.dart';

// --- Risk Calculator Screen ---
class RiskCalculatorScreen extends StatelessWidget {
  const RiskCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
          title: const Text("Risk & Insurance"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.2))),
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    Text("Farm Risk Score",
                        style: GoogleFonts.dmSans(
                            fontSize: 16, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Text("7.2 / 10",
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Text("High Risk (Flood Prone)",
                        style: GoogleFonts.dmSans(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
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
      floatingActionButton: const ChatFloatingButton(),
    );
  }

  Widget _buildInsuranceCard(String name, String premium, String cover) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.security, size: 28, color: Colors.blueGrey),
        ),
        title:
            Text(name, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(premium, style: GoogleFonts.dmSans(fontSize: 13)),
            Text(cover,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            backgroundColor: Colors.blueGrey,
            elevation: 0,
          ),
          child: const Text("Apply", style: TextStyle(fontSize: 12)),
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
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
          title: const Text("Equipment Sharing"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "equipment_fab",
            onPressed: () {},
            label: const Text("Rent Out My Tractor"),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.brown,
          ),
          const SizedBox(height: 16),
          const ChatFloatingButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Search tractors, harvesters...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 140,
            color: Colors.grey[200],
            child: const Center(
                child: Icon(Icons.agriculture, size: 64, color: Colors.grey)),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.dmSans(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(dist, style: GoogleFonts.dmSans(color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price,
                        style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700])),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(rating.toString(),
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold)),
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
      style: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    ),
  );
}
