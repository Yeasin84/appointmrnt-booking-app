import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aroggyapath/models/dependent_model.dart';
import 'package:aroggyapath/utils/api_config.dart';

class DependentProvider with ChangeNotifier {
  List<DependentModel> _dependents = [];
  bool _isLoading = false;
  String? _error;

  List<DependentModel> get dependents => _dependents;

  // ✅ Get only active dependents
  List<DependentModel> get activeDependents =>
      _dependents.where((dep) => dep.isActive ?? true).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ FETCH ALL DEPENDENTS
  Future<void> fetchDependents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Fetch Dependents Response: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> dependentsJson = data['data'] ?? [];
          _dependents = dependentsJson
              .map((json) => DependentModel.fromJson(json))
              .toList();

          debugPrint('✅ Loaded ${_dependents.length} dependents');
        } else {
          throw Exception(data['message'] ?? 'Failed to load dependents');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to load dependents');
      }
    } catch (e) {
      debugPrint('❌ Error fetching dependents: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ CREATE DEPENDENT
  Future<bool> createDependent({
    required String fullName,
    required String relationship,
    required DateTime dob,
    required String gender,
    String? phone,
    String? notes,
  }) async {
    _error = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        'fullName': fullName,
        'relationship': relationship,
        'dob': dob.toIso8601String(),
        'gender': gender,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      debugPrint('📤 Creating dependent: $body');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      debugPrint('📥 Create Response: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Refresh the list
          await fetchDependents();
          return true;
        } else {
          _error = data['message'] ?? 'Failed to create dependent';
          notifyListeners();
          return false;
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to create dependent';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error creating dependent: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ UPDATE DEPENDENT
  Future<bool> updateDependent({
    required String dependentId,
    String? fullName,
    String? relationship,
    DateTime? dob,
    String? gender,
    String? phone,
    String? notes,
    bool? isActive,
  }) async {
    _error = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (relationship != null) body['relationship'] = relationship;
      if (dob != null) body['dob'] = dob.toIso8601String();
      if (gender != null) body['gender'] = gender;
      if (phone != null) body['phone'] = phone;
      if (notes != null) body['notes'] = notes;
      if (isActive != null) body['isActive'] = isActive;

      debugPrint('📤 Updating dependent $dependentId: $body');

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}/$dependentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      debugPrint('📥 Update Response: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Refresh the list
          await fetchDependents();
          return true;
        } else {
          _error = data['message'] ?? 'Failed to update dependent';
          notifyListeners();
          return false;
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to update dependent';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating dependent: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ DELETE DEPENDENT (with error handling for active appointments)
  Future<bool> deleteDependent(String dependentId) async {
    _error = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('🗑️ Deleting dependent: $dependentId');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}/$dependentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Delete Response: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Remove from local list
          _dependents.removeWhere((dep) => dep.id == dependentId);
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Failed to delete dependent';
          notifyListeners();
          return false;
        }
      } else {
        // ✅ Parse error message from backend
        try {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to delete dependent';
        } catch (e) {
          _error = 'Failed to delete dependent';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting dependent: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ GET SINGLE DEPENDENT BY ID
  DependentModel? getDependentById(String id) {
    try {
      return _dependents.firstWhere((dep) => dep.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ CLEAR ERROR
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
