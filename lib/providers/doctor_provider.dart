import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';
import '../services/location_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  final LocationService _locationService = LocationService();

  LatLng? _currentUserLocation;

  List<Doctor> _nearbyDoctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get nearbyDoctors => _nearbyDoctors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateLocation(LatLng location) {
    _currentUserLocation = location;
    // Optionally recalculate distances if lists are already loaded,
    // but typically we fetch after location is known or on refresh.
  }

  Future<bool> fetchNearbyDoctors({double? lat, double? lng}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (lat != null && lng != null) {
      _currentUserLocation = LatLng(lat, lng);
    }

    try {
      debugPrint('📡 Fetching doctors from API...');
      final response = await _doctorService.getNearbyDoctors(
        lat: lat,
        lng: lng,
      );

      debugPrint('📥 API Response:');
      debugPrint('   - Success: ${response['success']}');
      debugPrint(
        '   - Data count: ${(response['data'] as List?)?.length ?? 0}',
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        debugPrint('✅ Fetched ${data.length} doctors raw data');

        // Parse to Doctor objects
        _nearbyDoctors = data.map((json) => Doctor.fromJson(json)).toList();

        debugPrint('✅ Successfully parsed ${_nearbyDoctors.length} doctors');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch doctors';
        debugPrint('❌ API Error: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error: $e';
      debugPrint('❌ Exception in fetchNearbyDoctors:');
      debugPrint('   Error: $e');
      debugPrint('   StackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ New method to fetch ALL doctors for the "See All" screen
  List<Doctor> _allDoctors = [];
  bool _isAllLoading = false;
  String? _allError;

  List<Doctor> get allDoctors => _allDoctors;
  bool get isAllLoading => _isAllLoading;
  String? get allError => _allError;

  Doctor _updateDoctorDistance(Doctor doctor) {
    if (_currentUserLocation == null ||
        doctor.latitude == null ||
        doctor.longitude == null) {
      return doctor;
    }

    final doctorLoc = LatLng(doctor.latitude!, doctor.longitude!);
    final distanceKm = _locationService.calculateDistanceInKm(
      _currentUserLocation!,
      doctorLoc,
    );

    String distanceStr;
    if (distanceKm < 1) {
      distanceStr = '${(distanceKm * 1000).round()} m';
    } else {
      distanceStr = '${distanceKm.toStringAsFixed(1)} km';
    }

    return doctor.copyWith(distance: distanceStr);
  }

  Future<bool> fetchAllDoctors() async {
    _isAllLoading = true;
    _allError = null;
    notifyListeners();

    try {
      debugPrint('📡 Fetching ALL doctors...');
      final response = await _doctorService.getAllDoctors();

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _allDoctors = data.map((json) {
          final doctor = Doctor.fromJson(json);
          return _updateDoctorDistance(doctor);
        }).toList();
        _isAllLoading = false;
        notifyListeners();
        return true;
      } else {
        _allError = response['message'] ?? 'Failed to fetch all doctors';
        _isAllLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _allError = 'Error: $e';
      _isAllLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Search Doctors
  Future<void> searchDoctors(String query) async {
    if (query.isEmpty) {
      await fetchAllDoctors();
      return;
    }

    _isAllLoading = true;
    _allError = null;
    notifyListeners();

    try {
      final response = await _doctorService.searchDoctors(query);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _allDoctors = data.map((json) {
          final doctor = Doctor.fromJson(json);
          return _updateDoctorDistance(doctor);
        }).toList();
      } else {
        _allError = response['message'] ?? 'Failed to search doctors';
      }
    } catch (e) {
      _allError = 'Error: $e';
    } finally {
      _isAllLoading = false;
      notifyListeners();
    }
  }

  void clearDoctors() {
    debugPrint('🗑️ Clearing doctors list');
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
