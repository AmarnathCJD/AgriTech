import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipmentService _equipmentService = EquipmentService();

  String _selectedType = 'Tractor';
  final List<String> _equipmentTypes = [
    'Tractor',
    'Harvester',
    'Tiller',
    'Seeder',
    'Sprayer',
    'Other'
  ];

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyPriceController = TextEditingController();
  final TextEditingController _dailyPriceController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _convertImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      String base64Image = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an image'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Hardcoded location for demo (Kochi) to match listing default
    const double lat = 9.9312;
    const double long = 76.2673;

    final String? base64Image = await _convertImageToBase64(_selectedImage!);
    List<String> images = base64Image != null ? [base64Image] : [];

    final equipment = EquipmentCreateByMobile(
      equipmentType: _selectedType,
      description: _descriptionController.text.trim(),
      hourlyPrice: double.parse(_hourlyPriceController.text.trim()),
      dailyPrice: double.parse(_dailyPriceController.text.trim()),
      locationLat: lat,
      locationLong: long,
      images: images,
      mobileNumber: _mobileController.text.trim(),
    );

    final result = await _equipmentService.registerEquipment(equipment);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Equipment added successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to add equipment.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add My Equipment"),
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
              Text("Equipment Details",
                  style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text("Add Photo",
                                style: GoogleFonts.dmSans(
                                    color: Colors.grey[600])),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Equipment Type",
                  border: OutlineInputBorder(),
                ),
                items: _equipmentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "e.g. Mahindra 575 DI, 45HP, Good condition",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hourlyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Hourly Price (₹)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dailyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Daily Price (₹)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text("Contact Information",
                  style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "Enter 10-digit mobile number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => (value == null || value.length < 10)
                    ? 'Valid mobile required'
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEquipment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register Equipment"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
