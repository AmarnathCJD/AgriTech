import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import 'dart:developer';

class BookingService {
  String get baseUrl => dotenv.env['BACKEND_URL']!;

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

  Future<List<Booking>> fetchBookings({String? mobileNumber}) async {
    // If mobile number is provided, fetch specific user's rentals
    final String endpoint = mobileNumber != null ? 'user' : 'list-booked';
    final url = Uri.parse('$baseUrl/uber/booking/$endpoint');

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (mobileNumber != null) {
        headers['X-User-Phone'] = mobileNumber;
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Booking.fromJson(e)).toList();
      } else {
        log('Failed to load bookings: ${response.statusCode}');
        // Return empty list instead of throwing to avoid UI crash
        return [];
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

  Future<List<Booking>> fetchIncomingBookings(String mobileNumber) async {
    final url =
        Uri.parse('$baseUrl/uber/booking/incoming?mobile_number=$mobileNumber');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Booking.fromJson(e)).toList();
      } else {
        log('Failed to load incoming bookings: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error fetching incoming bookings: $e');
      return [];
    }
  }

  Future<bool> updateBookingStatus(
      String bookingId, String status, String mobileNumber) async {
    final url =
        Uri.parse('$baseUrl/uber/booking/status/$bookingId?status=$status');
    try {
      final response =
          await http.patch(url, headers: {'X-User-Phone': mobileNumber});
      return response.statusCode == 200;
    } catch (e) {
      log('Error updating booking status: $e');
      return false;
    }
  }
}
