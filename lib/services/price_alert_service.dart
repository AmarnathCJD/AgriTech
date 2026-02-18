import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single price alert set by the farmer.
class PriceAlert {
  final String id;
  final String cropName;
  final double targetPrice;
  final String condition; // 'above' or 'below'
  bool triggered;

  PriceAlert({
    required this.id,
    required this.cropName,
    required this.targetPrice,
    required this.condition,
    this.triggered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropName': cropName,
        'targetPrice': targetPrice,
        'condition': condition,
        'triggered': triggered,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> j) => PriceAlert(
        id: j['id'],
        cropName: j['cropName'],
        targetPrice: (j['targetPrice'] as num).toDouble(),
        condition: j['condition'],
        triggered: j['triggered'] ?? false,
      );
}

class PriceAlertService extends ChangeNotifier {
  static final PriceAlertService _instance = PriceAlertService._internal();
  factory PriceAlertService() => _instance;
  PriceAlertService._internal();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);

  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _fln.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Request Android 13+ permission
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _loadAlerts();
  }

  Future<void> requestPermission() async {
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('price_alerts');
    if (raw != null) {
      final list = json.decode(raw) as List;
      _alerts = list.map((e) => PriceAlert.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'price_alerts', json.encode(_alerts.map((a) => a.toJson()).toList()));
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addAlert(PriceAlert alert) async {
    _alerts.add(alert);
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> removeAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _saveAlerts();
    notifyListeners();
  }

  // ── Price Check ───────────────────────────────────────────────────────────

  /// Call this whenever fresh mandi prices arrive.
  Future<void> checkPrices(Map<String, double> currentPrices) async {
    for (final alert in _alerts) {
      if (alert.triggered) continue;
      final price = currentPrices[alert.cropName];
      if (price == null) continue;

      final hit = alert.condition == 'above'
          ? price >= alert.targetPrice
          : price <= alert.targetPrice;

      if (hit) {
        alert.triggered = true;
        await _fireNotification(
          id: alert.id.hashCode,
          title: '🔔 Price Alert: ${alert.cropName}',
          body: alert.condition == 'above'
              ? '${alert.cropName} is now ₹${price.toStringAsFixed(0)}/q — above your target of ₹${alert.targetPrice.toStringAsFixed(0)}/q!'
              : '${alert.cropName} is now ₹${price.toStringAsFixed(0)}/q — below your target of ₹${alert.targetPrice.toStringAsFixed(0)}/q!',
        );
      }
    }
    await _saveAlerts();
    notifyListeners();
  }

  // ── Demo Simulation ───────────────────────────────────────────────────────

  /// Fires a fake notification immediately — for demo purposes.
  Future<void> simulateAlert({
    String cropName = 'Wheat',
    double price = 2350,
    String condition = 'above',
    double targetPrice = 2200,
  }) async {
    await _fireNotification(
      id: 9999,
      title: '🔔 Price Alert: $cropName [DEMO]',
      body: condition == 'above'
          ? '$cropName hit ₹${price.toStringAsFixed(0)}/q — above your target ₹${targetPrice.toStringAsFixed(0)}/q!'
          : '$cropName dropped to ₹${price.toStringAsFixed(0)}/q — below your target ₹${targetPrice.toStringAsFixed(0)}/q!',
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _fireNotification(
      {required int id, required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      channelDescription: 'Mandi price alerts for your crops',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _fln.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
