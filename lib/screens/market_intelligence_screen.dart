import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/market_intelligence_service.dart';

class MarketIntelligenceScreen extends StatefulWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  State<MarketIntelligenceScreen> createState() =>
      _MarketIntelligenceScreenState();
}

class _MarketIntelligenceScreenState extends State<MarketIntelligenceScreen> {
  final MarketIntelligenceService _service = MarketIntelligenceService();
  bool _isLoading = true;
  MarketSentiment? _sentiment;
  List<String> _trends = [];
  List<SocialPost> _feed = [];
  List<double> _priceData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Parallel fetching for faster load
    final results = await Future.wait([
      _service.getMarketSentiment(),
      _service.getTrendingHashtags(),
      _service.getSocialFeed(),
      _service.getPricePredictionData(),
    ]);

    if (mounted) {
      setState(() {
        _sentiment = results[0] as MarketSentiment;
        _trends = results[1] as List<String>;
        _feed = results[2] as List<SocialPost>;
        _priceData = results[3] as List<double>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Market Intelligence",
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSentimentCard(),
                  const SizedBox(height: 24),
                  _buildPricePredictionChart(),
                  const SizedBox(height: 24),
                  _buildTrendingTopics(),
                  const SizedBox(height: 24),
                  Text("Live Social Pulse",
                      style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800])),
                  const SizedBox(height: 12),
                  ..._feed.map((post) => _buildSocialPostCard(post)).toList(),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),
    );
  }

  Widget _buildSentimentCard() {
    Color sentimentColor =
        _sentiment?.label == "Bullish" ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Market Mood",
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_sentiment!.label.toUpperCase(),
                      style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: sentimentColor)),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sentimentColor.withOpacity(0.1),
                  border: Border.all(color: sentimentColor, width: 2),
                ),
                child: Center(
                  child: Text("${_sentiment!.score.toInt()}",
                      style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: sentimentColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _sentiment!.score / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(sentimentColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            _sentiment!.reason,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildPricePredictionChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AI Price Forecast (7 Days)",
              style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 2000,
                maxY: 2200,
                lineBarsData: [
                  LineChartBarData(
                    spots: _priceData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                        show: true, color: Colors.blueAccent.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Trending Topics",
            style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trends
              .map((tag) => Chip(
                    label: Text(tag,
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800])),
                    backgroundColor: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSocialPostCard(SocialPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    post.platform == 'X' ? Colors.black : Colors.blue[900],
                radius: 16,
                child: Icon(post.platform == 'X' ? Icons.close : Icons.facebook,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(post.handle,
                      style:
                          GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(post.timeAgo,
                  style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content,
              style: GoogleFonts.dmSans(
                  fontSize: 15, height: 1.4, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text("${post.likes}",
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.grey[600])),
              const SizedBox(width: 16),
              Icon(Icons.share, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text("${post.shares}",
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
