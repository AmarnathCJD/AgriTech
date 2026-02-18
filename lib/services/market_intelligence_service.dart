import 'dart:convert';
import 'dart:math';
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

class TwitterPost {
  final String author;
  final String content;
  final String url;
  final String image;
  final String authorAvatar;

  TwitterPost({
    required this.author,
    required this.content,
    required this.url,
    required this.image,
    required this.authorAvatar,
  });
}

class MarketIntelligenceService {
  // Use http client for requests
  final http.Client _client = http.Client();

  // --- Real Data: Agmarknet API ---
  Future<List<StockMarketData>> fetchAgmarknetLive() async {
    try {
      const url1 =
          "https://api.agmarknet.gov.in/v1/dashboard-data/?dashboard=marketwise_price_arrival&date=2026-02-18&group=[100000]&commodity=[100001]&variety=100021&state=17&district=[100007]&grades=[4]&limit=10&format=json";
      const url2 =
          "https://api.agmarknet.gov.in/v1/dashboard-data/?commodity=%5B100001%5D&dashboard=marketwise_price_arrival&date=2026-02-18&district=%5B100007%5D&format=json&grades=%5B4%5D&group=%5B100000%5D&limit=10&page=2&state=17&variety=100021";

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
              if (val is String) {
                return double.tryParse(val.replaceAll(',', '')) ?? 0.0;
              }
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

  // Store the raw JSON data for AI analysis
  List<Map<String, dynamic>> scrapedNewsJson = [];

  // --- Real Data: Krishi Jagran News Scraping ---
  Future<List<NewsItem>> fetchAgriNews() async {
    try {
      const url = "https://krishijagran.com/industry-news";
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        var document = parse(response.body);
        var articles =
            document.querySelectorAll('div.main-post, div.post, div.nc-item');

        // Fallback
        if (articles.isEmpty) {
          articles = document.querySelectorAll('article');
        }

        List<NewsItem> news = [];
        List<Map<String, dynamic>> tempJsonList = [];

        for (var article in articles.take(15)) {
          try {
            var titleEl =
                article.querySelector('h2') ?? article.querySelector('h3');
            var linkEl = article.querySelector('a');
            var imgEl = article.querySelector('img');

            String title = titleEl?.text.trim() ?? "";
            String link = linkEl?.attributes['href'] ?? "";
            if (link.isNotEmpty && !link.startsWith('http')) {
              link = "https://krishijagran.com$link";
            }

            String img =
                imgEl?.attributes['data-src'] ?? imgEl?.attributes['src'] ?? "";
            if (img.isNotEmpty && !img.startsWith('http')) {
              img = "https://krishijagran.com$img";
            }

            if (title.isNotEmpty) {
              // Add to NewsItem list
              news.add(NewsItem(
                  title: title,
                  imageUrl: img,
                  link: link,
                  source: "Krishi Jagran"));

              // Add to JSON list
              tempJsonList.add({
                "title": title,
                "poster": img,
                "link": link,
              });
            }
          } catch (e) {
            continue;
          }
        }

        if (news.isNotEmpty) {
          scrapedNewsJson = tempJsonList; // Update class property
          print("Scraped ${news.length} news items. JSON stored.");
          return news;
        } else {
          throw Exception("No news found");
        }
      } else {
        throw Exception("News Fetch Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Scraping Error: $e");
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

  // --- Sentiment & Trends (Twitter + AI) ---

  List<TwitterPost> fetchedTweets = [];

  Future<Map<String, dynamic>> fetchTwitterSentiment() async {
    try {
      final hashtag = _getRandomHashtag();
      print("Fetching tweets for $hashtag...");

      final queryParams = {
        'type': 'Latest',
        'count': '20',
        'query': hashtag,
      };

      final uri = Uri.https(
        'twitter241.p.rapidapi.com',
        '/search-v3',
        queryParams,
      );

      final response = await _client.get(
        uri,
        headers: {
          'x-rapidapi-host': 'twitter241.p.rapidapi.com',
          'x-rapidapi-key':
              'cf9e67ea99mshecc7e1ddb8e93d1p1b9e04jsn3f1bb9103c3f',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tweets = _parseTweets(data);
        fetchedTweets = tweets; // Store for UI

        if (tweets.isNotEmpty) {
          return await _analyzeWithAI(tweets);
        } else {
          print(
              "Response Data: $data"); // Debug print to see structure if empty
          throw Exception("No Tweets Found");
        }
      } else {
        throw Exception("Twitter API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Twitter Sentiment Failed: $e");
      return getMockSentiment();
    }
  }

  String _getRandomHashtag() {
    // Use plain hashtags, Uri.https will handle encoding
    const tags = [
      '#KeralaAgriculture',
      '#KeralaFarmers',
      '#CoconutFarming',
      '#RubberPrice',
      '#KeralaSpices',
      '#VFPCK',
      '#Kisan',
      '#AgricultureIndia',
      '#IndianFarmers',
      '#MSP',
      '#MandiPrice'
    ];
    return tags[Random().nextInt(tags.length)];
  }

  List<TwitterPost> _parseTweets(Map<String, dynamic> json) {
    List<TwitterPost> posts = [];
    try {
      final timeline = json['result']?['timeline_response']?['timeline'];
      if (timeline == null) return [];

      final instructions = timeline['instructions'] as List?;
      if (instructions == null) return [];

      for (var instruction in instructions) {
        if (instruction['__typename'] == 'TimelineAddEntries') {
          final entries = instruction['entries'] as List?;
          if (entries == null) continue;

          for (var entry in entries) {
            try {
              // 1. Get Outer Content
              final contentItem = entry['content'];
              if (contentItem == null) {
                // print("Skipping entry: No content");
                continue;
              }

              // 2. Get Inner Tweet Content (usually in 'content' field of the item)
              final tweetContent = contentItem['content'];
              if (tweetContent == null) {
                // print("Skipping entry: No tweet content");
                continue;
              }

              // 3. Get Tweet Results
              final tweetResults = tweetContent['tweet_results'];
              if (tweetResults == null) {
                // print("Skipping entry: No tweet results");
                continue;
              }

              // 4. Get Result Object
              var result = tweetResults['result'];
              if (result == null) {
                // print("Skipping entry: No result");
                continue;
              }

              // Handle nested "TweetWithVisibilityResults" or similar wrappers if present
              if (result['tweet'] != null) {
                result = result['tweet'];
              }

              // 5. Extract Details — support both old 'legacy' and new 'details'/'core' structures
              final legacy = result['legacy'];
              final details = result['details'];

              // full_text: new API puts it in 'details', old API in 'legacy'
              final fullText = details?['full_text'] ?? legacy?['full_text'];
              if (fullText == null) continue;

              // User info: new API uses 'core' object, old API uses 'legacy' object
              final userResult = result['core']?['user_results']?['result'];
              if (userResult == null) continue;

              final coreUser = userResult['core'] ?? userResult['legacy'];
              if (coreUser == null) continue;

              final author = coreUser['screen_name'];
              // Avatar: new API uses avatar.image_url, old uses legacy.profile_image_url_https
              final authorAvatar = userResult['avatar']?['image_url'] ??
                  userResult['legacy']?['profile_image_url_https'] ??
                  "";

              final tweetId = result['rest_id'] ?? legacy?['id_str'];
              final link = "https://twitter.com/$author/status/$tweetId";

              String image = "";
              // Images: check result-level media_entities or legacy
              final mediaEntities = result['media_entities'] as List? ??
                  legacy?['media_entities'] as List?;
              if (mediaEntities != null && mediaEntities.isNotEmpty) {
                image = mediaEntities[0]['media_url_https'] ??
                    mediaEntities[0]['url'] ??
                    "";
              }

              posts.add(TwitterPost(
                  author: author ?? "Unknown",
                  content: fullText ?? "",
                  url: link,
                  image: image,
                  authorAvatar: authorAvatar ?? ""));
            } catch (e) {
              print("Error parsing specific tweet entry: $e");
            }
          }
        }
      }
    } catch (e) {
      print("Global Parsing Error: $e");
    }

    print("Parsed ${posts.length} tweets.");
    return posts;
  }

  Future<Map<String, dynamic>> _analyzeWithAI(List<TwitterPost> tweets) async {
    try {
      final tweetTexts = tweets
          .take(10)
          .map((t) => "- ${t.content.replaceAll('\n', ' ')}")
          .join("\n");

      final prompt = """
SYSTEM: You are an expert agricultural market advisor for Kerala, India. Analyze the following tweets about Kerala agriculture and respond ONLY in valid JSON.
JSON Fields required:
- "label": Overall market sentiment (Bullish/Bearish/Neutral)
- "score": Number 0-100 representing positive sentiment strength.
- "reason": 1-sentence market summary (max 15 words).
- "trends": List of 3 top trending keywords/hashtags from the text.
- "top_crop": The single most profitable crop to focus on right now based on sentiment (e.g. "Wheat", "Tomato", "Onion").
- "crop_action": One of: "Sow Now" / "Hold Stock" / "Sell Immediately" / "Wait & Watch" — for that top crop.
- "farmer_advice": A 1-2 sentence actionable advice for a farmer (what to do this week). Be specific and practical.

Strictly return ONLY JSON. No Markdown.

DATA:
$tweetTexts
""";

      final response = await _client.post(
          Uri.parse('https://zai.gogram.fun/message'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"message": prompt, "k": "ak"}));

      if (response.statusCode == 200) {
        final resBody = json.decode(response.body);
        // expecting {'response': '{...json string...}'} or directly json?
        // User example was {'response': 'Paris is...'}
        // So the actual AI text response is in 'response' key.

        final aiText = resBody['response'];

        // Clean up markdown block if present ```json ... ```
        String cleanJson = aiText.trim();
        if (cleanJson.startsWith('```json')) {
          cleanJson = cleanJson.replaceAll('```json', '').replaceAll('```', '');
        } else if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.replaceAll('```', '');
        }

        return json.decode(cleanJson);
      } else {
        throw Exception("AI API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("AI Analysis Error: $e");
      return getMockSentiment();
    }
  }

  Map<String, dynamic> getMockSentiment() {
    return {
      "score": 65.0,
      "label": "Neutral",
      "reason": "Mixed updates on crop yields and MSP announcements.",
      "trends": ["#Kisan", "#MSP", "#Monsoon"],
      "top_crop": "Wheat",
      "crop_action": "Hold Stock",
      "farmer_advice":
          "Wheat prices are stable. Hold your stock for 2 more weeks as MSP revision is expected. Avoid selling tomatoes at current low rates."
    };
  }

  // Fallback alias for old code
  Future<Map<String, dynamic>> getSentimentAndTrends() async {
    return fetchTwitterSentiment();
  }
}
