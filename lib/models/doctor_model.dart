// models/doctor_model.dart
// ✅ COMPLETE & FIXED - Location + Video Call + All Fields

class Doctor {
  final String id;
  final String name;
  final String fullName;
  final String specialty;
  final String image;
  final double rating;
  final int reviews;
  final String experience;
  final String location;
  final Map<String, dynamic>? fees;
  final List<WeeklySchedule>? weeklySchedule;
  final bool isAvailable;
  final String distance;

  // ✅ Location fields
  final double? latitude;
  final double? longitude;
  final String? address;

  // ✅ Dynamic fields from backend
  final String? bio;
  final bool isVideoCallAvailable;
  final String? visitingHoursText;

  Doctor({
    required this.id,
    required this.name,
    required this.fullName,
    required this.specialty,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.location,
    this.fees,
    this.weeklySchedule,
    this.isAvailable = true,
    this.distance = 'N/A',
    this.latitude,
    this.longitude,
    this.address,
    this.bio,
    this.isVideoCallAvailable = false,
    this.visitingHoursText,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // ✅ Safely extract image URL from avatar object
    String imageUrl = '';
    final avatar = json['avatar'];

    if (avatar != null && avatar is Map<String, dynamic>) {
      imageUrl = avatar['url'] ?? '';
    } else if (avatar is String) {
      imageUrl = avatar;
    }

    if (imageUrl.isEmpty) {
      imageUrl = 'assets/images/doctor_booking.png';
    }

    // ✅ Safely get rating from ratingSummary
    double ratingValue = 0.0;
    final ratingSummary = json['ratingSummary'];
    if (ratingSummary != null && ratingSummary is Map<String, dynamic>) {
      ratingValue = (ratingSummary['avgRating'] ?? 0).toDouble();
    } else if (json['rating'] != null) {
      ratingValue = (json['rating']).toDouble();
    }

    // ✅ Safely get reviews count
    int reviewsCount = 0;
    if (ratingSummary != null && ratingSummary is Map<String, dynamic>) {
      reviewsCount = ratingSummary['totalReviews'] ?? 0;
    } else if (json['reviews'] != null) {
      reviewsCount = json['reviews'];
    }

    // ✅ Parse location (lat/lng from backend)
    double? lat;
    double? lng;

    // Check if location is a Map object
    if (json['location'] != null && json['location'] is Map) {
      final locationMap = json['location'] as Map<String, dynamic>;
      lat = locationMap['lat'] != null
          ? double.tryParse(locationMap['lat'].toString())
          : null;
      lng = locationMap['lng'] != null
          ? double.tryParse(locationMap['lng'].toString())
          : null;
    }
    // Or check if latitude/longitude are direct fields
    else if (json['latitude'] != null || json['longitude'] != null) {
      lat = json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null;
      lng = json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null;
    }

    // ❌ REMOVED FALLBACK: Do not generate random locations.
    // Only show doctors with valid real locations.
    if (lat == null || lng == null) {
      print(
        '⚠️ ${json['fullName']}: No valid location found. Skipping map coordinates.',
      );
    }

    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      fullName: json['fullName'] ?? '',
      specialty: json['specialty'] ?? '',
      image: imageUrl,
      rating: ratingValue,
      reviews: reviewsCount,
      experience:
          json['experience']?.toString() ??
          json['experienceYears']?.toString() ??
          '0',
      location:
          json['location']?.toString() ??
          json['address']?.toString() ??
          json['hospital'] ??
          '',
      fees: json['fees'],
      weeklySchedule: json['weeklySchedule'] != null
          ? (json['weeklySchedule'] as List)
                .map((e) => WeeklySchedule.fromJson(e))
                .toList()
          : null,
      isAvailable: json['isAvailable'] ?? true,
      distance: json['distance']?.toString() ?? 'N/A',

      // ✅ Location fields (guaranteed to have values now)
      latitude: lat,
      longitude: lng,
      address: json['address'],

      // ✅ Dynamic fields
      bio: json['bio'],
      isVideoCallAvailable: json['isVideoCallAvailable'] ?? false,
      visitingHoursText: json['visitingHoursText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'name': name,
      'fullName': fullName,
      'specialty': specialty,
      'avatar': {'url': image},
      'image': image,
      'rating': rating,
      'ratingSummary': {'avgRating': rating, 'totalReviews': reviews},
      'reviews': reviews,
      'experience': experience,
      'experienceYears': experience,
      'location': location,
      'address': address,
      'fees': fees,
      'isAvailable': isAvailable,
      'distance': distance,

      // ✅ Location as both formats
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (latitude != null && longitude != null)
        'location': {'lat': latitude.toString(), 'lng': longitude.toString()},

      // ✅ Dynamic fields
      if (bio != null) 'bio': bio,
      'isVideoCallAvailable': isVideoCallAvailable,
      if (visitingHoursText != null) 'visitingHoursText': visitingHoursText,
      if (weeklySchedule != null)
        'weeklySchedule': weeklySchedule!.map((e) => e.toJson()).toList(),
    };
  }
}

class WeeklySchedule {
  final String day;
  final bool isActive;
  final List<TimeSlot> slots;

  WeeklySchedule({
    required this.day,
    required this.isActive,
    required this.slots,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    return WeeklySchedule(
      day: json['day'] ?? '',
      isActive: json['isActive'] ?? false,
      slots: json['slots'] != null
          ? (json['slots'] as List).map((e) => TimeSlot.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isActive': isActive,
      'slots': slots.map((e) => e.toJson()).toList(),
    };
  }
}

class TimeSlot {
  final String start;
  final String end;
  final bool? isBooked;

  TimeSlot({required this.start, required this.end, this.isBooked});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      isBooked: json['isBooked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      if (isBooked != null) 'isBooked': isBooked,
    };
  }
}
