import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final Equipment equipment;

  const BookingScreen({super.key, required this.equipment});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _isLoading = false;

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final startDateTime = DateTime(_startDate.year, _startDate.month,
        _startDate.day, _startTime.hour, _startTime.minute);

    final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day,
        _endTime.hour, _endTime.minute);

    final booking = BookingCreateByMobile(
      equipmentId: widget.equipment.id,
      startTime: startDateTime,
      endTime: endDateTime,
      mobileNumber: _mobileController.text.trim(),
    );

    try {
      await BookingService().createBookingByMobile(booking);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back to listing
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking: ${widget.equipment.equipmentType}",
                style: GoogleFonts.dmSans(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.equipment.description,
                style: GoogleFonts.dmSans(color: Colors.grey[600]),
              ),
              const Divider(height: 32),
              const Text("Your Mobile Number",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Enter 10-digit mobile number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.length < 10) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text("Select Dates",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDateTimeRow("Start", _startDate, _startTime, true),
              const SizedBox(height: 16),
              _buildDateTimeRow("End", _endDate, _endTime, false),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    disabledBackgroundColor: Colors.brown.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm & Book",
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(
      String label, DateTime date, TimeOfDay time, bool isStart) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$label Date"),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context, isStart),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(date)),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$label Time"),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectTime(context, isStart),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(time.format(context)),
                      const Icon(Icons.access_time, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
