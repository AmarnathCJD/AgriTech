// import 'package:flutter/material.dart'; // Unused

class MockBackend {
  // Simulate login
  Future<bool> login(String mobile, String otp) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true; // Always succeed for demo
  }

  // Simulate fetching features data
  Future<List<Map<String, dynamic>>> getMarketTrends() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      {'crop': 'Wheat', 'price': '₹2,100', 'trend': 'up', 'change': '+2.5%'},
      {'crop': 'Rice', 'price': '₹1,950', 'trend': 'stable', 'change': '0%'},
      {
        'crop': 'Mustard',
        'price': '₹4,800',
        'trend': 'down',
        'change': '-1.2%',
      },
    ];
  }
}
