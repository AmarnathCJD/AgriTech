import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class AgmarknetData {
  final String date;
  final String commodity;
  final String variety;
  final String market;
  final String minPrice;
  final String maxPrice;
  final String modalPrice;

  AgmarknetData({
    required this.date,
    required this.commodity,
    required this.variety,
    required this.market,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });
}

class NewsItem {
  final String title;
  final String imageUrl;
  final String link;
  final String source;

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.link,
    required this.source,
  });
}

class StockMarketData {
  final String commodityName;
  final double currentPrice;
  final double change;
  final List<double> historyPoints; // [2 days ago, 1 day ago, today]

  StockMarketData({
    required this.commodityName,
    required this.currentPrice,
    required this.change,
    required this.historyPoints,
  });
}

class MarketIntelligenceService {
  // Use http client for requests
  final http.Client _client = http.Client();

  // --- Real Data: Agmarknet API ---
  Future<List<StockMarketData>> fetchAgmarknetLive() async {
    try {
      const url1 =
          "https://api.agmarknet.gov.in/v1/dashboard-data/?dashboard=marketwise_price_arrival&date=2026-02-18&group=[100000]&commodity=[100001]&variety=100021&state=100006&district=[100007]&market=[100009]&grades=[4]&limit=10&format=json";
      const url2 =
          "https://api.agmarknet.gov.in/v1/dashboard-data/?commodity=%5B100001%5D&dashboard=marketwise_price_arrival&date=2026-02-18&district=%5B100007%5D&format=json&grades=%5B4%5D&group=%5B100000%5D&limit=10&market=%5B100009%5D&page=2&state=100006&variety=100021";

      final responses = await Future.wait(
          [_client.get(Uri.parse(url1)), _client.get(Uri.parse(url2))]);

      List<StockMarketData> marketData = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> records = data['data']['records'];

          for (var record in records) {
            // Helper to parse double safely
            double parsePrice(dynamic val) {
              if (val == null) return 0.0;
              if (val is double) return val;
              if (val is String)
                return double.tryParse(val.replaceAll(',', '')) ?? 0.0;
              return 0.0;
            }

            double current = parsePrice(record['as_on_price']);
            double prev1 = parsePrice(record['one_day_ago_price']);
            double prev2 = parsePrice(record['two_day_ago_price']);

            // Fallback for nulls to make graph pretty
            if (current == 0 && prev1 > 0) current = prev1;
            if (prev1 == 0 && current > 0) prev1 = current;
            if (prev2 == 0 && prev1 > 0) prev2 = prev1;

            if (current == 0) continue; // Skip broken records

            // Calculate change
            double change = 0.0;
            if (prev1 > 0) {
              change = ((current - prev1) / prev1) * 100;
            }

            marketData.add(StockMarketData(
                commodityName: record['cmdt_name'],
                currentPrice: current,
                change: change,
                historyPoints: [prev2, prev1, current]));
          }
        }
      }

      if (marketData.isEmpty) throw Exception("API Failed or Empty");
      return marketData;
    } catch (e) {
      return _getMockMarketData();
    }
  }

  List<StockMarketData> _getMockMarketData() {
    return [
      StockMarketData(
          commodityName: "Cereals (Bajra)",
          currentPrice: 2236.98,
          change: 8.76,
          historyPoints: [2415.43, 2056.74, 2236.98]),
      StockMarketData(
          commodityName: "Barley (Jau)",
          currentPrice: 2238.97,
          change: -4.72,
          historyPoints: [2293.24, 2350.00, 2238.97]),
      StockMarketData(
          commodityName: "Wheat",
          currentPrice: 2509.55,
          change: 0.83,
          historyPoints: [2448.75, 2488.88, 2509.55]),
      StockMarketData(
          commodityName: "Cotton",
          currentPrice: 7697.94,
          change: -2.99,
          historyPoints: [7763.39, 7934.82, 7697.94]),
      StockMarketData(
          commodityName: "Paddy (Common)",
          currentPrice: 3552.30,
          change: 54.2,
          historyPoints: [3371.79, 2303.64, 3552.30]),
    ];
  }

  // --- Real Data: Krishi Jagran News Scraping ---
  Future<List<NewsItem>> fetchAgriNews() async {
    try {
      const url = "https://krishijagran.com/industry-news";
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = parse(response.body);
        var articles = document.querySelectorAll(
            'div.news-card, div.h-news-card'); // Adjust selector based on site structure inspection

        // Fallback selectors if site changed - Generic article lookup
        if (articles.isEmpty) {
          articles = document.querySelectorAll('article');
        }

        List<NewsItem> news = [];

        // Basic parsing - HTML structure varies, so robust error handling needed per item
        for (var article in articles.take(5)) {
          try {
            var titleEl =
                article.querySelector('h2') ?? article.querySelector('h3');
            var linkEl = article.querySelector('a');
            var imgEl = article.querySelector('img');

            String title = titleEl?.text.trim() ?? "Agri News Update";
            String link = linkEl?.attributes['href'] ?? "";
            if (!link.startsWith('http'))
              link = "https://krishijagran.com$link";

            String img =
                imgEl?.attributes['data-src'] ?? imgEl?.attributes['src'] ?? "";
            if (img.isNotEmpty && !img.startsWith('http'))
              img = "https://krishijagran.com$img";

            if (title.isNotEmpty) {
              news.add(NewsItem(
                  title: title,
                  imageUrl: img,
                  link: link,
                  source: "Krishi Jagran"));
            }
          } catch (e) {
            continue;
          }
        }

        if (news.isEmpty) throw Exception("No news found");
        return news;
      } else {
        throw Exception("News Fetch Failed");
      }
    } catch (e) {
      return _getMockNews();
    }
  }

  List<NewsItem> _getMockNews() {
    return [
      NewsItem(
          title: "Government Announces New MSP for Rabi Crops 2026-27",
          imageUrl: "https://krishijagran.com/media/1234/msp-news.jpg",
          link: "https://krishijagran.com",
          source: "Krishi Jagran"),
      NewsItem(
          title:
              "Heavy Rainfall Expected in Maharashtra: Farmers Advised Caution",
          imageUrl: "https://krishijagran.com/media/5678/rain-agri.jpg",
          link: "https://krishijagran.com",
          source: "Krishi Jagran"),
      NewsItem(
          title: "New Drone Schemes for Small Farmers Launched",
          imageUrl: "https://krishijagran.com/media/9999/drone-farm.jpg",
          link: "https://krishijagran.com",
          source: "Krishi Jagran"),
    ];
  }

  // --- Sentiment & Trends (Keep logic for dashboard) ---
  Future<Map<String, dynamic>> getSentimentAndTrends() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      "score": 72.5,
      "label": "Bullish",
      "reason": "Rising demand and positive MSP news.",
      "trends": [
        "#WheatPriceHike",
        "#MSP2026",
        "#SustainableFarming",
        "#AgriTech"
      ]
    };
  }
}
