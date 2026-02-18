import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import 'dart:developer';

class BookingService {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';

  Future<Booking?> createBookingByMobile(BookingCreateByMobile booking) async {
    final url = Uri.parse('$baseUrl/uber/booking/create-by-mobile');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(booking.toJson()),
      );

      if (response.statusCode == 200) {
        return Booking.fromJson(json.decode(response.body));
      } else {
        log('Failed to create booking: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create booking: ${response.body}');
      }
    } catch (e) {
      log('Error creating booking: $e');
      rethrow;
    }
  }

  Future<List<Booking>> fetchBookings() async {
    // Current backend implementation lists ALL booked equipment.
    // In a real app, this should filter by user.
    // For now, we fetch all and maybe filter client-side if we knew the user ID.
    final url = Uri.parse('$baseUrl/uber/booking/list-booked');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Booking.fromJson(e)).toList();
      } else {
        log('Failed to load bookings: ${response.statusCode}');
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      log('Error fetching bookings: $e');
      return [];
    }
  }

  Future<bool> addReview(ReviewCreate review) async {
    final url = Uri.parse('$baseUrl/uber/review/add');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-User-Phone': review.mobileNumber, // Identify user by mobile
        },
        body: json.encode(review.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        log('Failed to add review: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error adding review: $e');
      return false;
    }
  }
}
