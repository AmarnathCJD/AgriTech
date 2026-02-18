import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../services/auth_service.dart';
import '../auth/owner_login_screen.dart';
import 'booking_screen.dart';
import 'my_bookings_screen.dart';
import 'add_equipment_screen.dart';

class EquipmentListingScreen extends StatefulWidget {
  const EquipmentListingScreen({super.key});

  @override
  State<EquipmentListingScreen> createState() => _EquipmentListingScreenState();
}

class _EquipmentListingScreenState extends State<EquipmentListingScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  List<Equipment> _equipmentList = [];
  bool _isLoading = true;
  String? _error;

  // Filter states
  double _radius = 50.0;
  String _selectedType = 'All';
  final List<String> _equipmentTypes = [
    'All',
    'Tractor',
    'Harvester',
    'Tiller',
    'Seeder',
    'Sprayer',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
  }

  Future<void> _fetchEquipment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Hardcoded location for demo (Kochi)
      final equipment = await _equipmentService.fetchNearbyEquipment(
        lat: 9.9312,
        long: 76.2673,
        radiusKm: _radius,
        equipmentType: _selectedType,
      );
      setState(() {
        _equipmentList = equipment;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddEquipment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEquipmentScreen()),
    );
    if (result == true) {
      _fetchEquipment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text("Equipment Rental"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyBookingsScreen()),
              );
            },
            tooltip: "My Bookings",
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final isLoggedIn =
              userProvider.user != null || AuthService().isLoggedIn;

          if (!isLoggedIn) {
            // Navigate to Login first
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OwnerLoginScreen(onLoginSuccess: () {
                          Navigator.pop(context); // Close login screen
                          // Proceed to Add Equipment
                          _navigateToAddEquipment();
                        })));
          } else {
            _navigateToAddEquipment();
          }
        },
        label: const Text("Add My Equipment"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Radius: ${_radius.toInt()} km",
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 5,
                        max: 100,
                        divisions: 19,
                        label: "${_radius.toInt()} km",
                        activeColor: Colors.brown,
                        onChanged: (value) {
                          setState(() => _radius = value);
                        },
                        onChangeEnd: (value) => _fetchEquipment(),
                      ),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _equipmentTypes.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                              _fetchEquipment();
                            }
                          },
                          selectedColor: Colors.brown[100],
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.brown[800]
                                  : Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text("Error: $_error"))
                    : _equipmentList.isEmpty
                        ? Center(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text("No equipment found.",
                                  style:
                                      GoogleFonts.dmSans(color: Colors.grey)),
                            ],
                          ))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _equipmentList.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemBuilder: (context, index) {
                              return _buildEquipmentCard(_equipmentList[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    // Decode Base64 image
    ImageProvider imageProvider;
    if (equipment.images.isNotEmpty &&
        equipment.images[0].startsWith('data:')) {
      try {
        final base64String = equipment.images[0].split(',').last;
        imageProvider = MemoryImage(base64Decode(base64String));
      } catch (e) {
        imageProvider = const NetworkImage('https://via.placeholder.com/150');
      }
    } else {
      imageProvider = equipment.images.isNotEmpty
          ? NetworkImage(equipment.images[0])
          : const NetworkImage('https://via.placeholder.com/150?text=No+Image');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.equipmentType,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equipment.description,
                        style: GoogleFonts.dmSans(
                            color: Colors.grey[700], fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            equipment.rating.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            " (${equipment.reviewCount})",
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${equipment.hourlyPrice.toStringAsFixed(0)}/hr",
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700]),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookingScreen(equipment: equipment),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text("Book",
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
