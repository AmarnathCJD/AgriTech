import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/market_intelligence_service.dart';
import '../services/price_alert_service.dart';
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
  bool _isSentimentLoading = true;

  // Real Data
  List<StockMarketData> _marketData = [];
  List<NewsItem> _news = [];
  Map<String, dynamic> _sentiment = {};
  List<TwitterPost> _tweets = [];

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

  // ── Price Alert Sheet ────────────────────────────────────────────────────

  Future<void> _showPriceAlertSheet() async {
    final alertService = PriceAlertService();
    await alertService.requestPermission();

    final cropController = TextEditingController();
    final priceController = TextEditingController();
    String condition = 'above';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F5F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: Colors.deepPurple, size: 22),
                    const SizedBox(width: 10),
                    Text('Price Alerts',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final crop = alertService.alerts.isNotEmpty
                            ? alertService.alerts.first.cropName
                            : 'Wheat';
                        final target = alertService.alerts.isNotEmpty
                            ? alertService.alerts.first.targetPrice
                            : 2200.0;
                        await alertService.simulateAlert(
                          cropName: crop,
                          price: target + 150,
                          condition: 'above',
                          targetPrice: target,
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('🔔 Demo alert fired for $crop!'),
                            backgroundColor: Colors.deepPurple,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                      icon: const Icon(Icons.play_circle_outline,
                          color: Colors.deepPurple, size: 16),
                      label: Text('Simulate',
                          style: GoogleFonts.dmSans(
                            color: Colors.deepPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Add Alert Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SET NEW ALERT',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey,
                            fontSize: 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cropController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Crop (e.g. Wheat)',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: '₹ Target/q',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _conditionChip('above', condition,
                                    (v) => setSheetState(() => condition = v)),
                                const SizedBox(width: 8),
                                _conditionChip('below', condition,
                                    (v) => setSheetState(() => condition = v)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final crop = cropController.text.trim();
                              final price =
                                  double.tryParse(priceController.text.trim());
                              if (crop.isEmpty || price == null) return;
                              await alertService.addAlert(PriceAlert(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                cropName: crop,
                                targetPrice: price,
                                condition: condition,
                              ));
                              cropController.clear();
                              priceController.clear();
                              setSheetState(() {});
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            child: Text('Add',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Active Alerts List
                if (alertService.alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No alerts set yet.',
                          style: GoogleFonts.dmSans(
                              color: Colors.grey, fontSize: 14)),
                    ),
                  )
                else
                  ...alertService.alerts.map((alert) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: alert.triggered
                              ? Colors.green.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: alert.triggered
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              alert.triggered
                                  ? Icons.check_circle
                                  : Icons.notifications_outlined,
                              color: alert.triggered
                                  ? Colors.green
                                  : Colors.deepPurple,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert.cropName,
                                      style: GoogleFonts.dmSans(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      )),
                                  Text(
                                    '${alert.condition == "above" ? "↑ Above" : "↓ Below"} ₹${alert.targetPrice.toStringAsFixed(0)}/q',
                                    style: GoogleFonts.dmSans(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (alert.triggered)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Text('Triggered',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.green[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () async {
                                await alertService.removeAlert(alert.id);
                                setSheetState(() {});
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _conditionChip(
      String value, String selected, ValueChanged<String> onTap) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.white24),
        ),
        child: Text(
          value == 'above' ? '↑ Above' : '↓ Below',
          style: GoogleFonts.dmSans(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
    // Load market data and news first so UI renders immediately
    final results = await Future.wait([
      _service.fetchAgmarknetLive(),
      _service.fetchAgriNews(),
    ]);

    if (mounted) {
      setState(() {
        _marketData = results[0] as List<StockMarketData>;
        _news = results[1] as List<NewsItem>;
        _isLoading = false;
      });
    }

    // Load sentiment in background — doesn't block UI
    _loadSentimentInBackground();
  }

  Future<void> _loadSentimentInBackground() async {
    final sentiment = await _service.getSentimentAndTrends();
    if (mounted) {
      setState(() {
        _sentiment = sentiment;
        _tweets = _service.fetchedTweets;
        _isSentimentLoading = false;
      });
    }
  }

  // --- New Methods for Twitter Trends ---

  Widget _buildTwitterTrends() {
    if (_tweets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // X Logo (or just text "Trending on X")
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("TRENDING ON TWITTER",
                        style: GoogleFonts.bebasNeue(
                            color: Colors.red,
                            fontSize: 24,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _tweets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tweet = _tweets[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(12),
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
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(tweet.url)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(tweet.authorAvatar),
                            onBackgroundImageError: (_, __) {},
                            child: tweet.authorAvatar.isEmpty
                                ? const Icon(Icons.person, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tweet.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(Icons.open_in_new,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          tweet.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (tweet.image.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.image,
                                size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              "View Media",
                              style: GoogleFonts.dmSans(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------

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
          // Bell with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _showPriceAlertSheet,
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.deepPurple),
                tooltip: 'Price Alerts',
              ),
              if (PriceAlertService().alerts.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${PriceAlertService().alerts.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

                  // 2. AI Forecast & Sentiment (moved to top)
                  const SizedBox(height: 16),
                  _buildSentimentSection(),

                  const SizedBox(height: 16),

                  // 3. Main Graph Area
                  _buildStockMarketGraph(),

                  // 4. Commodity Selector Chips
                  _buildCommoditySelector(),

                  const SizedBox(height: 16),

                  // 5. Farmer Advisory + Crop Production
                  _buildFarmerAdvisoryCard(),

                  const SizedBox(height: 8),

                  // 6. Twitter Trends
                  _buildTwitterTrends(),

                  // 6. Breaking News
                  _buildNewsSection(),
                  const SizedBox(height: 32),
                  _buildDataSourcesFooter(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
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

  // Static UPAG crop production data (2025-26 Kharif, First Advance Estimates)
  static const _upagData = [
    {'crop': 'Food Grains', 'production': 1733.3, 'unit': 'Lakh T'},
    {'crop': 'Cereals', 'production': 1659.2, 'unit': 'Lakh T'},
    {'crop': 'Pulses', 'production': 74.1, 'unit': 'Lakh T'},
    {'crop': 'Oil Seeds', 'production': 275.6, 'unit': 'Lakh T'},
  ];

  Widget _buildFarmerAdvisoryCard() {
    if (_isSentimentLoading && _sentiment.isEmpty)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Farmer Advisory ──────────────────────────────────────────────
          if (!_isSentimentLoading && _sentiment['farmer_advice'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A00E0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.agriculture,
                                color: Color(0xFF4A00E0), size: 15),
                            const SizedBox(width: 6),
                            Text('FARMER ADVISORY',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF4A00E0),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                )),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Crop badge
                      if (_sentiment['top_crop'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.4)),
                          ),
                          child: Text('🌾 ${_sentiment['top_crop']}',
                              style: GoogleFonts.dmSans(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Action badge
                  if (_sentiment['crop_action'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(_sentiment['crop_action'] ?? '',
                          style: GoogleFonts.dmSans(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  const SizedBox(height: 10),
                  // Advice text
                  Text(
                    _sentiment['farmer_advice'] ?? '',
                    style: GoogleFonts.dmSans(
                      color: Colors.black87,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),

          // ── Crop Production Summary (UPAG 2025-26 Kharif) ────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart,
                              color: Colors.green, size: 15),
                          const SizedBox(width: 6),
                          Text('CROP PRODUCTION',
                              style: GoogleFonts.dmSans(
                                color: Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              )),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('2025–26 Kharif',
                        style: GoogleFonts.dmSans(
                          color: Colors.grey,
                          fontSize: 11,
                        )),
                  ],
                ),
                const SizedBox(height: 14),
                ..._upagData.map((d) {
                  final pct = (d['production'] as double) / 1733.3;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(d['crop'] as String,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ),
                            Text(
                                '${(d['production'] as double).toStringAsFixed(1)} ${d['unit']}',
                                style: GoogleFonts.dmSans(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Source: UPAG Gov API · First Advance Estimates',
                      style:
                          GoogleFonts.dmSans(color: Colors.grey, fontSize: 10)),
                ),
              ],
            ),
          ),
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
    if (_isSentimentLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Analysing market sentiment…',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final trends =
        (_sentiment['trends'] as List<dynamic>? ?? []).cast<String>();
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
                    _sentiment['reason'] ?? '',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SizedBox(height: 4),
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
                              .toList()
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
                                // "Just Now", // Placeholder since we don't have time
                                "",
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

  Widget _buildDataSourcesFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'DATA SOURCES & ATTRIBUTION',
                style: GoogleFonts.dmSans(
                  color: Colors.grey[700],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sourceItem('Agmarknet (Govt. of India)',
              'Real-time Mandi Prices & Arrivals', Icons.bar_chart),
          _sourceItem('UPAG (Ministry of Agriculture)',
              'Crop Production Estimates 2025-26', Icons.agriculture),
          _sourceItem('Grok AI + Twitter',
              'Market Sentiment Analysis & Forecasts', Icons.psychology),
          _sourceItem('Krishi Jagran', 'Global & Local Agricultural News',
              Icons.newspaper),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Market data is indicative. Please verify with local mandis before trading.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.grey[400],
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceItem(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.dmSans(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
