// models/user_model.dart
// ✅ UPDATED with Video Call Support

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? profileImage;

  // ✅ Doctor fields from backend
  final String? bio;
  final String? specialty;
  final List<String>? specialties;
  final int? experienceYears;
  final String? medicalLicenseNumber;
  final String? visitingHoursText;

  // ✅ NEW: Video call availability
  final bool isVideoCallAvailable;

  // ✅ Fees structure
  final double? feesAmount;
  final String? feesCurrency;

  // ✅ Degrees
  final List<Degree>? degrees;

  // ✅ Weekly schedule
  final List<DaySchedule>? weeklySchedule;

  // ✅ Location fields
  final double? latitude;
  final double? longitude;

  // ✅ Helper for fees
  Map<String, dynamic>? get fees => feesAmount != null
      ? {'amount': feesAmount, 'currency': feesCurrency}
      : null;

  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.profileImage,
    this.bio,
    this.specialty,
    this.specialties,
    this.experienceYears,
    this.medicalLicenseNumber,
    this.visitingHoursText,
    this.isVideoCallAvailable = false, // ✅ Default false
    this.feesAmount,
    this.feesCurrency,
    this.degrees,
    this.weeklySchedule,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // print('🔍 UserModel.fromJson raw keys: ${json.keys.toList()}');
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      dateOfBirth: json['dob'],
      gender: json['gender'],
      bloodGroup: json['bloodGroup'] ?? json['blood_group'],
      address: json['address'],

      // ✅ Handle avatar object from backend OR snake_case from Supabase
      profileImage:
          json['avatar']?['url'] ?? json['profileImage'] ?? json['avatar_url'],

      // ✅ Doctor fields
      bio: json['bio'],
      specialty: json['specialty'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : null,
      experienceYears: json['experienceYears'] ?? json['experience_years'],
      medicalLicenseNumber:
          json['medicalLicenseNumber'] ?? json['medical_license_number'],
      visitingHoursText:
          json['visitingHoursText'] ?? json['visiting_hours_text'],

      // ✅ NEW: Video call availability - Robust parsing
      isVideoCallAvailable:
          json['isVideoCallAvailable'] ??
          json['is_video_call_available'] ?? // snake case variant
          json['is_video_available'] ?? // db column name
          json['isVideoAvailable'] ??
          (json['video']?['isAvailable'] ?? false),

      // ✅ Fees - Check nested 'fees' dict OR direct columns
      feesAmount:
          json['fees']?['amount']?.toDouble() ??
          json['fees_amount']?.toDouble() ??
          0.0,
      feesCurrency: json['fees']?['currency'] ?? json['fees_currency'] ?? 'DZD',

      // ✅ Degrees
      degrees: json['degrees'] != null
          ? (json['degrees'] as List).map((d) => Degree.fromJson(d)).toList()
          : null,

      // ✅ Weekly schedule (Supabase Join Support)
      weeklySchedule: json['weeklySchedule'] != null
          ? (json['weeklySchedule'] as List)
                .map((d) => DaySchedule.fromJson(d))
                .toList()
          : (json['doctor_schedules'] != null)
          ? (() {
              final ds = json['doctor_schedules'];
              final List? scheduleList = (ds is List && ds.isNotEmpty)
                  ? ds[0]['weekly_schedule']
                  : (ds is Map)
                  ? ds['weekly_schedule']
                  : null;
              return scheduleList?.map((d) => DaySchedule.fromJson(d)).toList();
            })()
          : json['weekly_schedule'] != null
          ? (json['weekly_schedule'] as List)
                .map((d) => DaySchedule.fromJson(d))
                .toList()
          : null,

      // ✅ Location fields - Handle nested structure from backend
      latitude:
          json['latitude']?.toDouble() ??
          (json['location'] != null
              ? double.tryParse(json['location']['lat'].toString())
              : null),
      longitude:
          json['longitude']?.toDouble() ??
          (json['location'] != null
              ? double.tryParse(json['location']['lng'].toString())
              : null),

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'dob': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'profileImage': profileImage,
      'bio': bio,
      'specialty': specialty,
      'specialties': specialties,
      'experienceYears': experienceYears,
      'medicalLicenseNumber': medicalLicenseNumber,
      'visitingHoursText': visitingHoursText,
      'isVideoCallAvailable': isVideoCallAvailable, // ✅ NEW
      'fees': {'amount': feesAmount, 'currency': feesCurrency},
      'degrees': degrees?.map((d) => d.toJson()).toList(),
      'weeklySchedule': weeklySchedule?.map((d) => d.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? profileImage,
    String? bio,
    String? specialty,
    List<String>? specialties,
    int? experienceYears,
    String? medicalLicenseNumber,
    String? visitingHoursText,
    bool? isVideoCallAvailable, // ✅ NEW
    double? feesAmount,
    String? feesCurrency,
    List<Degree>? degrees,
    List<DaySchedule>? weeklySchedule,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      specialty: specialty ?? this.specialty,
      specialties: specialties ?? this.specialties,
      experienceYears: experienceYears ?? this.experienceYears,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      visitingHoursText: visitingHoursText ?? this.visitingHoursText,
      isVideoCallAvailable:
          isVideoCallAvailable ?? this.isVideoCallAvailable, // ✅ NEW
      feesAmount: feesAmount ?? this.feesAmount,
      feesCurrency: feesCurrency ?? this.feesCurrency,
      degrees: degrees ?? this.degrees,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ✅ Degree model (unchanged)
class Degree {
  final String title;
  final String? institute;
  final int? year;

  Degree({required this.title, this.institute, this.year});

  factory Degree.fromJson(Map<String, dynamic> json) {
    return Degree(
      title: json['title'] ?? '',
      institute: json['institute'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'institute': institute, 'year': year};
  }
}

// ✅ Day schedule model (unchanged)
class DaySchedule {
  final String day;
  final bool isActive;
  final List<TimeSlot>? slots;

  DaySchedule({required this.day, required this.isActive, this.slots});

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'] ?? '',
      isActive: json['isActive'] ?? false,
      slots: json['slots'] != null
          ? (json['slots'] as List).map((s) => TimeSlot.fromJson(s)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isActive': isActive,
      'slots': slots?.map((s) => s.toJson()).toList(),
    };
  }
}

// ✅ Time slot model (unchanged)
class TimeSlot {
  final String start;
  final String end;

  TimeSlot({required this.start, required this.end});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(start: json['start'] ?? '', end: json['end'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end};
  }
}
