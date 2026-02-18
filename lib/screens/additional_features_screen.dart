import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalFeaturesScreen extends StatelessWidget {
  const AdditionalFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text("More Services"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureTile(
            context,
            "Storage & Warehouses",
            "Find nearby cold storage and godowns",
            Icons.warehouse_rounded,
            Colors.brown,
          ),
          _buildFeatureTile(
            context,
            "Government Schemes",
            "Subsidy alerts & application support",
            Icons.account_balance_rounded,
            Colors.blueGrey,
          ),
          _buildFeatureTile(
            context,
            "Agri-Expert Chatbot",
            "24/7 AI advisory for crop diseases",
            Icons.chat_bubble_rounded,
            Colors.green,
          ),
          _buildFeatureTile(
            context,
            "Soil Health Card",
            "Digital records of your farm's soil data",
            Icons.layers_rounded,
            Colors.orange,
          ),
          _buildFeatureTile(
            context,
            "Community Forum",
            "Connect with other farmers",
            Icons.groups_rounded,
            Colors.indigo,
          ),
        ].animate(interval: 100.ms).fadeIn().slideX(),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Opening $title... (Demo)")),
          );
        },
      ),
    );
  }
}
