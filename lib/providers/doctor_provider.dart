import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  List<Doctor> _nearbyDoctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get nearbyDoctors => _nearbyDoctors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> fetchNearbyDoctors({double? lat, double? lng}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 Fetching doctors from API...');
      final response = await _doctorService.getNearbyDoctors(
        lat: lat,
        lng: lng,
      );

      print('📥 API Response:');
      print('   - Success: ${response['success']}');
      print('   - Data count: ${(response['data'] as List?)?.length ?? 0}');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];

        print('✅ Fetched ${data.length} doctors raw data');

        // Parse to Doctor objects
        _nearbyDoctors = data.map((json) => Doctor.fromJson(json)).toList();

        print('✅ Successfully parsed ${_nearbyDoctors.length} doctors');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch doctors';
        print('❌ API Error: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error: $e';
      print('❌ Exception in fetchNearbyDoctors:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearDoctors() {
    print('🗑️ Clearing doctors list');
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
