class Booking {
  final String id;
  final String equipmentId;
  final String renterId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.equipmentId,
    required this.renterId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      equipmentId: json['equipment_id'] ?? '',
      renterId: json['renter_id'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BookingCreateByMobile {
  final String equipmentId;
  final DateTime startTime;
  final DateTime endTime;
  final String mobileNumber;

  BookingCreateByMobile({
    required this.equipmentId,
    required this.startTime,
    required this.endTime,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'equipment_id': equipmentId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'mobile_number': mobileNumber,
    };
  }
}
