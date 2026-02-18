import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'add_review_screen.dart';
import 'my_listings_tab.dart';
import 'incoming_requests_screen.dart';

import '../../services/auth_service.dart';
import '../auth/owner_login_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // Mobile number handling
  String? _currentUserMobile;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    setState(() {
      _currentUserMobile = AuthService().currentMobileNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5F2),
        appBar: AppBar(
          title: const Text("My Activity"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.brown,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.brown,
            tabs: [
              Tab(text: "Rentals"),
              Tab(text: "Listings"),
              Tab(text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: My Rentals (Bookings I made)
            MyRentalsTab(mobileNumber: _currentUserMobile),

            // Tab 2: My Listings (Equipment I own)
            _currentUserMobile != null
                ? MyListingsTab(mobileNumber: _currentUserMobile!)
                : _buildLoginPrompt(),

            // Tab 3: Incoming Requests (Bookings on my equipment)
            _currentUserMobile != null
                ? IncomingRequestsScreen(mobileNumber: _currentUserMobile!)
                : _buildLoginPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Please login to view this section"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OwnerLoginScreen(onLoginSuccess: () {
                          Navigator.pop(context);
                          _checkAuth(); // Refresh state
                        })),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            child: const Text("Owner Login"),
          )
        ],
      ),
    );
  }
}

class MyRentalsTab extends StatefulWidget {
  final String? mobileNumber;
  const MyRentalsTab({super.key, this.mobileNumber});

  @override
  State<MyRentalsTab> createState() => _MyRentalsTabState();
}

class _MyRentalsTabState extends State<MyRentalsTab> {
  final BookingService _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (widget.mobileNumber == null) {
      setState(() => _isLoading = false);
      return;
    }

    final bookings =
        await _bookingService.fetchBookings(mobileNumber: widget.mobileNumber);
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mobileNumber == null) {
      return const Center(child: Text("Please login to view rentals"));
    }

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: _bookings.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(child: Text("No rentals found.")),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) =>
                  _buildBookingCard(_bookings[index]),
            ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final bool isCompleted = booking.status.toLowerCase() == 'completed';
    final String displayId = booking.id.length >= 6
        ? booking.id.substring(booking.id.length - 6)
        : booking.id;

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
                  "Booking #$displayId",
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
                            AddReviewScreen(bookingId: booking.id!),
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
