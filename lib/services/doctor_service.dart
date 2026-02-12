import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';

class DoctorService {
  Future<Map<String, dynamic>> getNearbyDoctors({
    double? lat,
    double? lng,
    double radiusKm = 50,
  }) async {
    try {
      if (lat == null || lng == null) {
        // Fallback to all doctors if no location
        return await getAllDoctors();
      }

      debugPrint(
        '📍 Fetching nearby doctors: Lat:$lat, Lng:$lng, Radius:$radiusKm km',
      );

      final List<dynamic> data = await Supabase.instance.client.rpc(
        'get_nearby_doctors',
        params: {
          'user_lat': lat.toDouble(),
          'user_lng': lng.toDouble(),
          'radius_km': radiusKm.toDouble(),
        },
      );

      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Get Nearby Doctors Error: $e');
      return {'success': false, 'message': 'Failed to fetch doctors: $e'};
    }
  }

  // Define getAllDoctors helper if not locally available (it is in ApiService, but good to have here or call ApiService)
  // Actually ApiService.getAllDoctors exists, let's use that as fallback or just duplicate the call here using Supabase directly if we want consistent Service layer.
  // For now, looking at the file, there is no getAllDoctors in DoctorService, only searchDoctors.
  // ApiService has getAllDoctors.
  Future<Map<String, dynamic>> getAllDoctors() async {
    return await ApiService.getAllDoctors();
  }

  Future<Map<String, dynamic>> getDoctorById(String id) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('*, doctor_schedules(weekly_schedule)')
          .eq('id', id)
          .single();

      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Get Doctor By ID Error: $e');
      return {'success': false, 'message': 'Failed to fetch doctor: $e'};
    }
  }

  Future<Map<String, dynamic>> searchDoctors(String query) async {
    try {
      debugPrint('🔍 Searching doctors with query: $query');
      final data = await Supabase.instance.client
          .from('profiles')
          .select('*, doctor_schedules(weekly_schedule)')
          .eq('role', 'doctor')
          .or(
            'full_name.ilike.%$query%,specialty.ilike.%$query%,address.ilike.%$query%,bio.ilike.%$query%',
          );

      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Search Doctors Error: $e');
      return {'success': false, 'message': 'Failed to search doctors: $e'};
    }
  }
}
