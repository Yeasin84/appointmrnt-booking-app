import 'package:flutter/material.dart';
import 'package:aroggyapath/models/dependent_model.dart';
import 'package:aroggyapath/services/dependent_service.dart';

class DependentProvider with ChangeNotifier {
  final DependentService _dependentService = DependentService();
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
      final response = await _dependentService.getMyDependents();

      if (response['success'] == true) {
        final List<dynamic> dependentsJson = response['data'] ?? [];
        _dependents = dependentsJson
            .map((json) => DependentModel.fromJson(json))
            .toList();

        debugPrint('✅ Loaded ${_dependents.length} dependents');
      } else {
        throw Exception(response['message'] ?? 'Failed to load dependents');
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
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dependentService.createDependent(
        fullName: fullName,
        relationship: relationship,
        dob: dob,
        gender: gender,
        phone: phone,
        notes: notes,
      );

      if (response['success'] == true) {
        // Refresh the list
        await fetchDependents();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create dependent';
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error creating dependent: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dependentService.updateDependent(
        dependentId: dependentId,
        fullName: fullName,
        relationship: relationship,
        dob: dob,
        gender: gender,
        phone: phone,
        notes: notes,
        isActive: isActive,
      );

      if (response['success'] == true) {
        // Refresh the list
        await fetchDependents();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update dependent';
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating dependent: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ DELETE DEPENDENT
  Future<bool> deleteDependent(String dependentId) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dependentService.deleteDependent(dependentId);

      if (response['success'] == true) {
        // Remove from local list
        _dependents.removeWhere((dep) => dep.id == dependentId);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete dependent';
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting dependent: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
