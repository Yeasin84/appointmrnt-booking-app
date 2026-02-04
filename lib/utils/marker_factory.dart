import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../models/doctor_model.dart';
import '../widgets/custom_image.dart';

class MarkerFactory {
  // Singleton pattern
  static final MarkerFactory _instance = MarkerFactory._internal();
  factory MarkerFactory() => _instance;
  MarkerFactory._internal();

  /// Create a marker for the user's location
  fm.Marker createUserMarker(LatLng position) {
    return fm.Marker(
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.my_location, color: Colors.blue, size: 24),
        ),
      ),
    );
  }

  /// Create a marker for a doctor
  Future<fm.Marker> createCustomDoctorMarker({
    required Doctor doctor,
    required double distanceKm,
    required VoidCallback onTap,
  }) async {
    LatLng position = LatLng(doctor.latitude ?? 0, doctor.longitude ?? 0);

    return fm.Marker(
      point: position,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: doctor.isAvailable ? Colors.green : Colors.red,
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: CustomImage(
                  imageUrl: doctor.image,
                  placeholderAsset: 'assets/images/doctor1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a generic marker for selection
  fm.Marker createSelectedMarker(LatLng position) {
    return fm.Marker(
      point: position,
      width: 40,
      height: 40,
      child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
    );
  }
}
