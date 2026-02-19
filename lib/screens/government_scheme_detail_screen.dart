import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/government_scheme.dart';

class GovernmentSchemeDetailScreen extends StatelessWidget {
  final GovernmentScheme scheme;
  final List<Color> gradient;

  const GovernmentSchemeDetailScreen({
    super.key,
    required this.scheme,
    required this.gradient,
  });

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch URL: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: gradient[0],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  centerTitle: true,
                  title: Text(
                    'Scheme Insights',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Icon(
                            Icons.eco_outlined,
                            size: 200,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.account_balance,
                                      color: Colors.white, size: 32),
                                ).animate().scale(
                                    delay: 200.ms,
                                    duration: 400.ms,
                                    curve: Curves.easeOutBack),
                                const SizedBox(height: 16),
                                Text(
                                  scheme.name,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        context,
                        'Core Objective',
                        Icons.insights_rounded,
                        [scheme.description],
                        0,
                      ),
                      _buildSection(
                        context,
                        'Key Benefits',
                        Icons.auto_awesome_outlined,
                        scheme.benefits,
                        1,
                      ),
                      _buildSection(
                        context,
                        'Eligibility Criteria',
                        Icons.verified_user_outlined,
                        scheme.eligibility,
                        2,
                      ),
                      _buildSection(
                        context,
                        'Documentation',
                        Icons.assignment_outlined,
                        scheme.documents,
                        3,
                      ),
                      _buildSection(
                        context,
                        'How to Apply',
                        Icons.touch_app_outlined,
                        [scheme.process],
                        4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Button - Glassmorphism style
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: gradient[0],
                  child: InkWell(
                    onTap: () => _launchUrl(context, scheme.url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Access Government Portal',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().slideY(
                begin: 1.5,
                end: 0,
                delay: 600.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      List<String> items, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gradient[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: gradient[0], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: (400 + (index * 100)).ms)
              .slideX(begin: -0.1, end: 0),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                final bool isLast = items.last == item;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, right: 12.0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                gradient[0],
                                gradient[0].withOpacity(0.6)
                              ]),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: Colors.black.withOpacity(0.7),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
              .animate()
              .fadeIn(delay: (500 + (index * 100)).ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}
