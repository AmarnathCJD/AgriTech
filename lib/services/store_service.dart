import 'dart:convert';
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

  Future<List<Product>> getProducts({String? category}) async {
    try {
      String url = '$baseUrl/store/products';
      if (category != null) {
        url += '?category=$category';
      }

      final response = await http.get(Uri.parse(url));

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
    final response = await http.get(
      Uri.parse('$baseUrl/store/cart'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      // If cart not found or error, return empty cart
      return Cart(items: [], totalPrice: 0.0, totalItems: 0);
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/store/cart/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> removeFromCart(String productId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/store/cart/remove'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> checkout() async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/store/checkout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}
