class Equipment {
  final String id;
  final String ownerId;
  final String equipmentType;
  final String description;
  final double hourlyPrice;
  final double dailyPrice;
  final String availabilityStatus;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final Map<String, dynamic> location;

  Equipment({
    required this.id,
    required this.ownerId,
    required this.equipmentType,
    required this.description,
    required this.hourlyPrice,
    required this.dailyPrice,
    required this.availabilityStatus,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.location,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['_id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      equipmentType: json['equipment_type'] ?? '',
      description: json['description'] ?? '',
      hourlyPrice: (json['hourly_price'] ?? 0).toDouble(),
      dailyPrice: (json['daily_price'] ?? 0).toDouble(),
      availabilityStatus: json['availability_status'] ?? 'unknown',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      location: json['location'] ?? {},
    );
  }
}

class EquipmentCreateByMobile {
  final String equipmentType;
  final String description;
  final double hourlyPrice;
  final double dailyPrice;
  final double locationLat;
  final double locationLong;
  final List<String> images;
  final String mobileNumber;

  EquipmentCreateByMobile({
    required this.equipmentType,
    required this.description,
    required this.hourlyPrice,
    required this.dailyPrice,
    required this.locationLat,
    required this.locationLong,
    required this.images,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'equipment_type': equipmentType,
      'description': description,
      'hourly_price': hourlyPrice,
      'daily_price': dailyPrice,
      'location_lat': locationLat,
      'location_long': locationLong,
      'images': images,
      'mobile_number': mobileNumber,
    };
  }
}
