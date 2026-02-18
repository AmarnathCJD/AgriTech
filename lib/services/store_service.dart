import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoreService {
  // Replace with actual backend URL or use a config
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('auth_token'); // Adjust key based on actual auth impl
  }

  // Helper method for retry logic
  Future<http.Response> _withRetry(
      Future<http.Response> Function() requestFn) async {
    try {
      return await requestFn().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      print('StoreService: Request timed out > 3s. Retrying...');
      try {
        // Retry once with slightly longer timeout (e.g., 5s) or same?
        // User asked "call again", so we retry.
        return await requestFn().timeout(const Duration(seconds: 5));
      } on TimeoutException {
        print('StoreService: Retry also timed out.');
        throw Exception('Connection timed out');
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProducts({String? category}) async {
    try {
      String url = '$baseUrl/store/products';
      if (category != null) {
        url += '?category=$category';
      }

      final response = await _withRetry(() => http.get(Uri.parse(url)));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      return []; // Return empty list on error for now
    }
  }

  Future<Cart> getCart() async {
    final token = await _getToken();
    try {
      final response = await _withRetry(() => http.get(
            Uri.parse('$baseUrl/store/cart'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        return Cart.fromJson(jsonDecode(response.body));
      } else {
        return Cart(items: [], totalPrice: 0.0, totalItems: 0);
      }
    } catch (e) {
      print('Error fetching cart: $e');
      return Cart(items: [], totalPrice: 0.0, totalItems: 0);
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    final token = await _getToken();
    try {
      final response = await _withRetry(() => http.post(
            Uri.parse('$baseUrl/store/cart/add'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'product_id': productId,
              'quantity': quantity,
            }),
          ));

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  Future<bool> removeFromCart(String productId) async {
    final token = await _getToken();
    try {
      final response = await _withRetry(() => http.post(
            Uri.parse('$baseUrl/store/cart/remove'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'product_id': productId,
            }),
          ));

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  Future<bool> checkout() async {
    final token = await _getToken();
    try {
      final response = await _withRetry(() => http.post(
            Uri.parse('$baseUrl/store/checkout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      return response.statusCode == 200;
    } catch (e) {
      print('Error during checkout: $e');
      return false;
    }
  }
}
