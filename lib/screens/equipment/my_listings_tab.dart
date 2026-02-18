import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';

class MyListingsTab extends StatefulWidget {
  final String mobileNumber;

  const MyListingsTab({super.key, required this.mobileNumber});

  @override
  State<MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<MyListingsTab> {
  final EquipmentService _equipmentService = EquipmentService();
  List<Equipment> _equipmentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    setState(() => _isLoading = true);
    final equipment =
        await _equipmentService.fetchMyEquipment(widget.mobileNumber);
    if (mounted) {
      setState(() {
        _equipmentList = equipment;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEquipment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: const Text("Are you sure you want to remove this equipment?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await _equipmentService.deleteEquipment(id, widget.mobileNumber);
      if (success) {
        _fetchMyListings();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Listing removed")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Failed to remove listing"),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_equipmentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("No equipment listed",
                style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _equipmentList.length,
      itemBuilder: (context, index) {
        final equipment = _equipmentList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: equipment.images.isNotEmpty
                          ? NetworkImage(equipment.images
                              .first) // Handle base64 if needed via helper
                          : const NetworkImage(
                              'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                    color: Colors.grey[200],
                  ),
                ),
                title: Text(equipment.equipmentType,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                subtitle: Text("₹${equipment.hourlyPrice}/hr",
                    style: GoogleFonts.dmSans(
                        color: Colors.green[700], fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteEquipment(equipment.id!),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
