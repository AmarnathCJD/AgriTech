import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'widgets/chat_floating_button.dart';

// Market Intelligence Screen moved to lib/screens/market_intelligence_screen.dart

export 'harvest/harvest_timing_screen.dart';

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
