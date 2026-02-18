import 'package:flutter/material.dart';
import 'widgets/chat_floating_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/market_intelligence_service.dart';
import 'dart:async';

class MarketIntelligenceScreen extends StatefulWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  State<MarketIntelligenceScreen> createState() =>
      _MarketIntelligenceScreenState();
}

class _MarketIntelligenceScreenState extends State<MarketIntelligenceScreen> {
  final MarketIntelligenceService _service = MarketIntelligenceService();
  bool _isLoading = true;

  // Real Data
  List<StockMarketData> _marketData = [];
  List<NewsItem> _news = [];
  Map<String, dynamic> _sentiment = {};

  int _selectedCommodityIndex = 0; // For graph

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoCycle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoCycle() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading && _marketData.isNotEmpty) {
        setState(() {
          _selectedCommodityIndex =
              (_selectedCommodityIndex + 1) % _marketData.length;
        });
      }
    });
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _service.fetchAgmarknetLive(),
      _service.fetchAgriNews(),
      _service.getSentimentAndTrends(),
    ]);

    if (mounted) {
      setState(() {
        _marketData = results[0] as List<StockMarketData>;
        _news = results[1] as List<NewsItem>;
        _sentiment = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Light warm grey/beige
      appBar: AppBar(
        title: Text("Market Pulse Live",
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.sync, color: Colors.green),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Ticker
                  _buildLiveTicker(),

                  // 2. Main Graph Area
                  _buildStockMarketGraph(),

                  // 3. Commodity Selector Chips
                  _buildCommoditySelector(),

                  const SizedBox(height: 24),

                  // 4. Sentiment & Trends
                  _buildSentimentSection(),

                  const SizedBox(height: 24),

                  // 5. Breaking News
                  _buildNewsSection(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
      floatingActionButton: const ChatFloatingButton(),
    );
  }

  Widget _buildLiveTicker() {
    return Container(
      height: 40,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _marketData.length,
        itemBuilder: (context, index) {
          final item = _marketData[index];
          final isUp = item.change >= 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Text(item.commodityName.toUpperCase(),
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(width: 8),
                Text("₹${item.currentPrice.toStringAsFixed(0)}",
                    style: GoogleFonts.dmSans(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text("${isUp ? '+' : ''}${item.change.toStringAsFixed(2)}%",
                    style: GoogleFonts.dmSans(
                        color: isUp ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(width: 4),
                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isUp ? Colors.green : Colors.red, size: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockMarketGraph() {
    if (_marketData.isEmpty) return const SizedBox.shrink();

    final selectedItem = _marketData[_selectedCommodityIndex];
    final isUp = selectedItem.change >= 0;
    final color = isUp ? Colors.green : Colors.red;

    // Prepare spots
    List<FlSpot> spots = [];
    for (int i = 0; i < selectedItem.historyPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), selectedItem.historyPoints[i]));
    }

    return Container(
      height: 350,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selectedItem.commodityName,
              style: GoogleFonts.playfairDisplay(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text("₹${selectedItem.currentPrice.toStringAsFixed(2)}",
                  style: GoogleFonts.dmSans(
                      color: Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.w300)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                    "${isUp ? '+' : ''}${selectedItem.change.toStringAsFixed(2)}%",
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(LineChartData(
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 2,
              minY: selectedItem.historyPoints.reduce((a, b) => a < b ? a : b) *
                  0.95,
              maxY: selectedItem.historyPoints.reduce((a, b) => a > b ? a : b) *
                  1.05,
              lineBarsData: [
                LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                                radius: 6,
                                color: color,
                                strokeWidth: 3,
                                strokeColor: Colors.white)),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.0)
                            ]))),
              ],
              lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> pageSpots) {
                  return pageSpots.map((spot) {
                    return LineTooltipItem(
                      '₹${spot.y.toStringAsFixed(2)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              )),
            )).animate().slideX(duration: 600.ms, curve: Curves.easeOutQuint),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("2 Days Ago",
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text("Yesterday",
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text("Today", style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCommoditySelector() {
    return SizedBox(
      height: 45, // Much more compact
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _marketData.length,
        itemBuilder: (context, index) {
          final item = _marketData[index];
          final isSelected = index == _selectedCommodityIndex;
          final isUp = item.change >= 0;
          final trendColor = isUp ? Colors.green : Colors.red;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCommodityIndex = index;
                _timer?.cancel();
                _startAutoCycle();
              });
            },
            child: AnimatedContainer(
              duration: 300.ms,
              curve: Curves
                  .easeOut, // Changed from easeOutBack to avoid negative blur radius
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: isSelected ? trendColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isSelected ? Colors.transparent : Colors.grey.shade300),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: trendColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(isUp ? Icons.trending_up : Icons.trending_down,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(item.commodityName,
                      style: GoogleFonts.dmSans(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        "${isUp ? '+' : ''}${item.change.toStringAsFixed(1)}%",
                        style: GoogleFonts.dmSans(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentimentSection() {
    final trends = _sentiment['trends'] as List<String>;
    // final isBullish = _sentiment['label'] == 'Bullish'; // Usage handled dynamically in UI

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4A00E0), // Deep Purple
              Color(0xFF8E2DE2) // Violet
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Background Patterns
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.psychology,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 20,
              child: Icon(
                Icons.ssid_chart,
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.amberAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "AI FORECAST",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]),
                        child: Row(
                          children: [
                            Text(
                              "SCORE",
                              style: GoogleFonts.dmSans(
                                color: Colors.deepPurple.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${_sentiment['score']}",
                              style: GoogleFonts.dmSans(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    "Market is ${_sentiment['label']}",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    _sentiment['reason'],
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.2), height: 1),
                  const SizedBox(height: 16),
                  // Footer Trends
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.trending_up,
                            color: Colors.white70, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: trends
                              .map((t) => Text(
                                    t,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    if (_news.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("LATEST AGRI NEWS",
                    style: GoogleFonts.bebasNeue(
                        color: Colors.red, fontSize: 24, letterSpacing: 1.2)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _news.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.shade200,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final item = _news[index];
              return InkWell(
                onTap: () => launchUrl(Uri.parse(item.link)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 100,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 70,
                          color: Colors.grey.shade200,
                          child:
                              const Icon(Icons.image_not_supported, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                item.source,
                                style: GoogleFonts.dmSans(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.circle,
                                  size: 4, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                "Just Now", // Placeholder since we don't have time
                                style: GoogleFonts.dmSans(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
