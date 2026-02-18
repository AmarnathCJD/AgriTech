import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'add_review_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final bookings = await _bookingService.fetchBookings();
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text("No bookings found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final bool isCompleted = booking.status.toLowerCase() == 'completed';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Booking #${booking.id.substring(booking.id.length - 6)}",
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          isCompleted ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Start: ${DateFormat('MMM dd, hh:mm a').format(booking.startTime)}",
              style: GoogleFonts.dmSans(color: Colors.grey[700]),
            ),
            Text(
              "End:   ${DateFormat('MMM dd, hh:mm a').format(booking.endTime)}",
              style: GoogleFonts.dmSans(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            if (isCompleted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddReviewScreen(bookingId: booking.id),
                      ),
                    );
                  },
                  child: const Text("Write a Review"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
