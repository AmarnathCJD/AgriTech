import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  LocalizationProvider() {
    _loadLocale();
  }

  // Supported Languages
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi (हिंदी)'},
    {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
    {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
    {'code': 'pa', 'name': 'Punjabi (ਪੰਜਾਬੀ)'},
  ];

  // Translation Dictionary
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_title': 'Farmora',
      'home': 'Home',
      'market': 'Mandi',
      'advisory': 'Advisory',
      'profile': 'Profile',
      'location': 'Location',
      'search_location': 'Search location...',
      'market_intelligence': 'Market Intelligence',
      'crop_planning': 'Crop Planning',
      'harvest_timing': 'Harvest Timing',
      'technical_advisory': 'Technical Advisory',
      'weather': 'Weather',
      'more_services': 'More Services',
      'my_profile': 'My Profile',
      'language': 'Language',
      'select_language': 'Select Language',
      'save': 'Save',
      'cancel': 'Cancel',
      'apply': 'Apply',
      'risk_calculator': 'Risk Calculator',
      'equipment_sharing': 'Equipment Sharing',
      'govt_schemes': 'Govt Schemes',
      'storage': 'Storage',
      'chat_hint': 'Ask me anything about farming...',
      'chat_title': 'Farmora Assistant',
      // Home Screen
      'smart_services': 'Smart Services',
      'live_prices': 'Live Prices',
      'ai_guide': 'AI Guide',
      'best_window': 'Best Window',
      'secure_farm': 'Secure Farm',
      'rentals': 'Rentals',
      'critical_alert': 'CRITICAL ALERT',
      'heavy_rain': 'Heavy Rainfall Expected',
      'rain_warning':
          'Secure your harvested crops and check drainage systems immediately.',
      'tap_precautions': 'Tap for precautions',
      'wheat': 'Wheat',
      'rice': 'Rice',
      'mustard': 'Mustard',
      'cotton': 'Cotton',
      'soybean': 'Soybean',
      'locating': 'Locating...',
      'set_location': 'Set Location',
      'search_city': 'Search for your city or area',
      'start_typing': 'Start typing (e.g. New Delhi)',
      'alerts': 'Alerts',
    },
    'hi': {
      'app_title': 'फार्मोरा',
      'home': 'होम',
      'market': 'मंडी',
      'advisory': 'सलाह',
      'profile': 'प्रोफाइल',
      'location': 'स्थान',
      'search_location': 'स्थान खोजें...',
      'market_intelligence': 'बाजार भाव',
      'crop_planning': 'फसल योजना',
      'harvest_timing': 'कटाई का समय',
      'technical_advisory': 'तकनीकी सलाह',
      'weather': 'मौसम',
      'more_services': 'अधिक सेवाएं',
      'my_profile': 'मेरी प्रोफाइल',
      'language': 'भाषा',
      'select_language': 'भाषा चुनें',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'apply': 'लागू करें',
      'risk_calculator': 'जोखिम कैलकुलेटर',
      'equipment_sharing': 'उपकरण साझाकरण',
      'govt_schemes': 'सरकारी योजनाएं',
      'storage': 'भंडारण',
      'chat_hint': 'खेती के बारे में कुछ भी पूछें...',
      'chat_title': 'फार्मोरा सहायक',
      // Home Screen
      'smart_services': 'स्मार्ट सेवाएं',
      'live_prices': 'तजा भाव',
      'ai_guide': 'AI गाइड',
      'best_window': 'सही समय',
      'secure_farm': 'सुरक्षित खेत',
      'rentals': 'किराये पर',
      'critical_alert': 'महत्वपूर्ण चेतावनी',
      'heavy_rain': 'भारी बारिश की संभावना',
      'rain_warning':
          'अपनी कटी हुई फसल को सुरक्षित करें और जल निकासी की जांच करें।',
      'tap_precautions': 'सावधानियों के लिए टैप करें',
      'wheat': 'गेहूँ',
      'rice': 'चावल',
      'mustard': 'सरसों',
      'cotton': 'कपास',
      'soybean': 'सोयाबीन',
      'locating': 'खोज रहा है...',
      'set_location': 'स्थान सेट करें',
      'search_city': 'अपना शहर या क्षेत्र खोजें',
      'start_typing': 'टाइप करना शुरू करें (जैसे नई दिल्ली)',
      'alerts': 'ताज़ा खबर',
    },
    'ml': {
      'app_title': 'ഫാർമോറ',
      'home': 'ഹോം',
      'market': 'ചന്ത',
      'advisory': 'ഉപദേശം',
      'profile': 'പ്രൊഫൈൽ',
      'location': 'സ്ഥലം',
      'search_location': 'സ്ഥലം തിരയുക...',
      'market_intelligence': 'വിപണി വിവരങ്ങൾ',
      'crop_planning': 'കൃഷി ആസൂത്രണം',
      'harvest_timing': 'വിളവെടുപ്പ് സമയം',
      'technical_advisory': 'സാങ്കേതിക ഉപദേശം',
      'weather': 'കാലാവസ്ഥ',
      'more_services': 'കൂടുതൽ സേവനങ്ങൾ',
      'my_profile': 'എന്റെ പ്രൊഫൈൽ',
      'language': 'ഭാഷ',
      'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
      'save': 'സേവ് ചെയ്യുക',
      'cancel': 'റദ്ദാക്കുക',
      'apply': 'പ്രയോഗിക്കുക',
      'risk_calculator': 'റിസ്ക് കാൽക്കുലേറ്റർ',
      'equipment_sharing': 'ഉപകരണങ്ങൾ',
      'govt_schemes': 'സർക്കാർ പദ്ധതികൾ',
      'storage': 'സംഭരണം',
      'chat_hint': 'കൃഷിയെക്കുറിച്ച് എന്തും ചോദിക്കാം...',
      'chat_title': 'ഫാർമോറ അസിസ്റ്റന്റ്',
      // Home Screen
      'smart_services': 'സ്മാർട്ട് സേവനങ്ങൾ',
      'live_prices': 'തത്സമയ വിലകൾ',
      'ai_guide': 'AI സഹായി',
      'best_window': 'വിളവെടുപ്പ് സമയം',
      'secure_farm': 'സുരക്ഷിത കൃഷി',
      'rentals': 'വാടകയ്ക്ക്',
      'critical_alert': 'അടിയന്തര അറിയിപ്പ്',
      'heavy_rain': 'കനത്ത മഴയ്ക്ക് സാധ്യത',
      'rain_warning':
          'വിളവെടുത്ത വിളകൾ സുരക്ഷിതമാക്കുക, നീർവാർച്ച സൗകര്യം പരിശോധിക്കുക.',
      'tap_precautions': 'മുൻകരുതലുകൾക്കായി ടാപ്പ് ചെയ്യുക',
      'wheat': 'ഗോതമ്പ്',
      'rice': 'അരി',
      'mustard': 'കടുക്',
      'cotton': 'പരുത്തി',
      'soybean': 'സോയാബീൻ',
      'locating': 'തിരയുന്നു...',
      'set_location': 'സ്ഥലം ക്രമീകരിക്കുക',
      'search_city': 'നിങ്ങളുടെ നഗരം അല്ലെങ്കിൽ സ്ഥലം തിരയുക',
      'start_typing': 'ടൈപ്പ് ചെയ്യുക (ഉദാഹരണത്തിന് കൊച്ചി)',
      'alerts': 'അറിയിപ്പുകൾ',
    },
    // Add other languages similarly...
    // Keeping it concise for now, will generate keys for others dynamically or fallback to English
  };

  String t(String key) {
    if (_localizedStrings.containsKey(_currentLocale.languageCode)) {
      return _localizedStrings[_currentLocale.languageCode]![key] ?? key;
    }
    return _localizedStrings['en']![key] ?? key;
  }

  void setLocale(Locale locale) async {
    _currentLocale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }
}
