import 'dart:math';

class MarketSentiment {
  final double score; // 0 to 100
  final String label; // Bullish, Bearish, Neutral
  final String reason;

  MarketSentiment(
      {required this.score, required this.label, required this.reason});
}

class SocialPost {
  final String author;
  final String handle;
  final String content;
  final String timeAgo;
  final String platform; // 'X' or 'Facebook'
  final int likes;
  final int shares;

  SocialPost({
    required this.author,
    required this.handle,
    required this.content,
    required this.timeAgo,
    required this.platform,
    required this.likes,
    required this.shares,
  });
}

class MarketIntelligenceService {
  final Random _random = Random();

  // Simulate AI Analysis of Market Sentiment
  Future<MarketSentiment> getMarketSentiment() async {
    await Future.delayed(
        const Duration(milliseconds: 800)); // Simulate API delay
    return MarketSentiment(
      score: 72.5,
      label: "Bullish",
      reason:
          "Rising demand detected in social discussions due to upcoming festival season.",
    );
  }

  // Simulate Trending Hashtags
  Future<List<String>> getTrendingHashtags() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      "#WheatPriceHike",
      "#MonsoonUpdate",
      "#MSP2026",
      "#SustainableFarming",
      "#AgriTechIndia",
      "#OnionExport"
    ];
  }

  // Simulate Social Media Feed Analysis
  Future<List<SocialPost>> getSocialFeed() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return [
      SocialPost(
        author: "AgriMarket Watch",
        handle: "@AgriWatchIN",
        content:
            "Analysis: Wheat prices expected to rise by 5-8% next week due to supply constraints in Punjab. #WheatPriceHike",
        timeAgo: "2h ago",
        platform: "X",
        likes: 1240,
        shares: 450,
      ),
      SocialPost(
        author: "Kisan Forum",
        handle: "@KisanForum",
        content:
            "Reports coming in from Nashik Mandi indicate a huge influx of red onions. Prices might stabilize soon.",
        timeAgo: "4h ago",
        platform: "Facebook",
        likes: 89,
        shares: 12,
      ),
      SocialPost(
        author: "Economy Daily",
        handle: "@EconomyDaily",
        content:
            "Govt announces new MSP rates for Rabi crops. Farmers react positively. #MSP2026",
        timeAgo: "5h ago",
        platform: "X",
        likes: 3400,
        shares: 1200,
      ),
      SocialPost(
        author: "Weather Man",
        handle: "@IndWeather",
        content:
            "Heavy rains predicted in MP belt. Soyabean harvest could be delayed. Farmers advised to take precautions.",
        timeAgo: "6h ago",
        platform: "X",
        likes: 560,
        shares: 230,
      ),
    ];
  }

  // Simulate Price Prediction Data (for Graphite)
  Future<List<double>> getPricePredictionData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Generate a slightly upward trend with some volatility
    double start = 2100.0;
    return List.generate(7, (index) {
      start += _random.nextInt(50) - 20; // Random fluctuation
      return start;
    });
  }
}
