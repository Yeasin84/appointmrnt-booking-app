import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DependentService {
  static final supabase = Supabase.instance.client;

  /// Get all dependents for current user
  Future<Map<String, dynamic>> getMyDependents() async {
    try {
      debugPrint('📤 Fetching dependents (Supabase)...');

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final data = await supabase
          .from('dependents')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      debugPrint('✅ Dependents fetched: ${data.length}');

      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Get Dependents Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch dependents: $e',
        'data': [],
      };
    }
  }

  /// Create new dependent
  Future<Map<String, dynamic>> createDependent({
    required String fullName,
    required String relationship,
    required DateTime dob,
    required String gender,
    String? phone,
    String? notes,
  }) async {
    try {
      debugPrint('📤 Creating dependent (Supabase)...');

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final body = {
        'user_id': userId,
        'full_name': fullName,
        'relationship': relationship,
        'dob': dob.toIso8601String().split('T')[0],
        'gender': gender,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final data = await supabase
          .from('dependents')
          .insert(body)
          .select()
          .single();

      debugPrint('✅ Dependent created successfully');
      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Create Dependent Error: $e');
      return {'success': false, 'message': 'Failed to create dependent: $e'};
    }
  }

  /// Update dependent
  Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    String? fullName,
    String? relationship,
    DateTime? dob,
    String? gender,
    String? phone,
    String? notes,
    bool? isActive,
  }) async {
    try {
      debugPrint('📤 Updating dependent: $dependentId (Supabase)');

      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (relationship != null) body['relationship'] = relationship;
      if (dob != null) body['dob'] = dob.toIso8601String().split('T')[0];
      if (gender != null) body['gender'] = gender;
      if (phone != null) body['phone'] = phone;
      if (notes != null) body['notes'] = notes;
      if (isActive != null) body['is_active'] = isActive;

      if (body.isEmpty) return {'success': true};

      final data = await supabase
          .from('dependents')
          .update(body)
          .eq('id', dependentId)
          .select()
          .single();

      debugPrint('✅ Dependent updated successfully');
      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Update Dependent Error: $e');
      return {'success': false, 'message': 'Failed to update dependent: $e'};
    }
  }

  /// Delete dependent
  Future<Map<String, dynamic>> deleteDependent(String dependentId) async {
    try {
      debugPrint('📤 Deleting dependent: $dependentId (Supabase)');

      await supabase
          .from('dependents')
          .update({'is_active': false})
          .eq('id', dependentId);

      debugPrint('✅ Dependent deleted (inactivated) successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('❌ Delete Dependent Error: $e');
      return {'success': false, 'message': 'Failed to delete dependent: $e'};
    }
  }
}
