import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/government_scheme.dart';
import '../services/scheme_service.dart';
import 'government_scheme_detail_screen.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({super.key});

  @override
  State<GovernmentSchemesScreen> createState() =>
      _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  final SchemeService _schemeService = SchemeService();
  final TextEditingController _searchController = TextEditingController();
  List<GovernmentScheme> _allSchemes = [];
  List<GovernmentScheme> _filteredSchemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredSchemes = _allSchemes
          .where((scheme) =>
              scheme.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              scheme.description
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _loadSchemes() async {
    final schemes = await _schemeService.getSchemes();
    if (mounted) {
      setState(() {
        _allSchemes = schemes;
        _filteredSchemes = schemes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      "Govt Schemes",
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            const Color(0xFF2E7D32),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Icon(
                              Icons.account_balance,
                              size: 150,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 40.0, left: 24, right: 24),
                              child: Text(
                                "Empowering Farmers through Government Initiatives",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .slideY(begin: 0.5, end: 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Container(
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
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search schemes...",
                          hintStyle:
                              GoogleFonts.dmSans(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search,
                              color: Theme.of(context).colorScheme.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                ),
                _filteredSchemes.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "No schemes found",
                                style:
                                    GoogleFonts.dmSans(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final scheme = _filteredSchemes[index];
                              return _buildSchemeCard(scheme, index, context)
                                  .animate()
                                  .fadeIn(
                                      delay: (index * 50).ms, duration: 400.ms)
                                  .slideX(begin: 0.1, end: 0);
                            },
                            childCount: _filteredSchemes.length,
                          ),
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildSchemeCard(
      GovernmentScheme scheme, int index, BuildContext context) {
    final List<List<Color>> gradients = [
      [Theme.of(context).colorScheme.primary, const Color(0xFF2E7D32)],
      [const Color(0xFF1B4D3E), const Color(0xFF00695C)],
      [const Color(0xFF5D4037), const Color(0xFF8D6E63)],
      [const Color(0xFF3E2723), const Color(0xFF5D4037)],
      [const Color(0xFF827717), const Color(0xFFAFB42B)],
    ];

    final gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GovernmentSchemeDetailScreen(
                    scheme: scheme,
                    gradient: gradient,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 60,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const Icon(
                        Icons.article_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheme.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3436),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scheme.description,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "View Details",
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: gradient[0],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 14, color: gradient[0]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
