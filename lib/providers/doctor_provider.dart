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

  void clearDoctors() {
    debugPrint('🗑️ Clearing doctors list');
    _nearbyDoctors = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
