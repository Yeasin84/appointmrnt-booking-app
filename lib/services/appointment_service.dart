import 'package:flutter/material.dart';

import '../utils/api_config.dart';
import 'api_service.dart';

class AppointmentService {
  /// Get current user's appointments (patient or doctor)
  Future<Map<String, dynamic>> getMyAppointments() async {
    try {
      debugPrint('📤 Fetching my appointments...');

      final response = await ApiService.get(
        ApiConfig.appointments,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint(
          '✅ Appointments fetched: ${response['data']?.length ?? 0} items',
        );
      } else {
        debugPrint('❌ Failed to fetch appointments: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Get My Appointments Error: $e');
      return {'success': false, 'message': 'Failed to fetch appointments: $e'};
    }
  }

  /// Get single appointment by ID
  Future<Map<String, dynamic>> getAppointmentById(String id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.appointments}/$id',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      debugPrint('❌ Get Appointment Error: $e');
      return {'success': false, 'message': 'Failed to fetch appointment: $e'};
    }
  }

  /// Create new appointment
  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String appointmentDate, // "2026-01-05"
    required String appointmentTime, // "10:30"
    String? symptoms,
    String? appointmentType, // "physical" or "video"
  }) async {
    try {
      final body = {
        'doctorId': doctorId,
        'appointmentType': appointmentType ?? 'physical',
        'date': appointmentDate,
        'time': appointmentTime,
        if (symptoms != null && symptoms.isNotEmpty) 'symptoms': symptoms,
      };

      debugPrint('📤 Creating appointment with body: $body');

      final response = await ApiService.post(
        ApiConfig.appointments,
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('✅ Appointment created successfully');
      } else {
        debugPrint('❌ Failed to create appointment: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Create Appointment Error: $e');
      return {'success': false, 'message': 'Failed to create appointment: $e'};
    }
  }

  /// Update appointment status (for doctor/admin only)
  Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status, // "accepted" | "cancelled" | "completed"
    String? patient,
    double? price,
  }) async {
    try {
      final body = {'status': status, 'patient': ?patient, 'price': ?price};

      debugPrint('📤 Updating appointment status to: $status');
      debugPrint('📦 Body: $body');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('✅ Status updated successfully');
      } else {
        debugPrint('❌ Failed to update status: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Update Status Error: $e');
      return {'success': false, 'message': 'Failed to update status: $e'};
    }
  }

  /// Get upcoming appointments
  Future<Map<String, dynamic>> getUpcomingAppointments() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.appointments}?status=pending,accepted',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      debugPrint('❌ Get Upcoming Appointments Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch upcoming appointments: $e',
      };
    }
  }

  /// Get past appointments
  Future<Map<String, dynamic>> getPastAppointments() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.appointments}?status=completed,cancelled',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      debugPrint('❌ Get Past Appointments Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch past appointments: $e',
      };
    }
  }

  /// Complete appointment (for doctor)
  Future<Map<String, dynamic>> completeAppointment({
    required String appointmentId,
    required String patientName,
    required double price,
    String? prescription,
    String? notes,
  }) async {
    try {
      final body = {
        'status': 'completed',
        'patient': patientName,
        'price': price,
        if (prescription != null && prescription.isNotEmpty)
          'prescription': prescription,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      debugPrint('📤 Completing appointment $appointmentId');
      debugPrint('📦 Body: $body');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('✅ Appointment completed successfully');
      } else {
        debugPrint('❌ Failed to complete appointment: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Complete Appointment Error: $e');
      return {
        'success': false,
        'message': 'Failed to complete appointment: $e',
      };
    }
  }

  /// Accept appointment (for doctor)
  Future<Map<String, dynamic>> acceptAppointment(String appointmentId) async {
    try {
      debugPrint('📤 Accepting appointment: $appointmentId');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        {'status': 'accepted'},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('✅ Appointment accepted successfully');
      } else {
        debugPrint('❌ Failed to accept appointment: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Accept Appointment Error: $e');
      return {'success': false, 'message': 'Failed to accept appointment: $e'};
    }
  }

  /// Cancel appointment (for doctor/admin)
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    try {
      debugPrint('📤 Cancelling appointment: $appointmentId');

      final response = await ApiService.patch(
        '${ApiConfig.appointments}/$appointmentId/status',
        {'status': 'cancelled'},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('✅ Appointment cancelled successfully');
      } else {
        debugPrint('❌ Failed to cancel appointment: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Cancel Appointment Error: $e');
      return {'success': false, 'message': 'Failed to cancel appointment: $e'};
    }
  }

  /// Get available appointment slots
  Future<Map<String, dynamic>> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    try {
      debugPrint('📤 Fetching available slots for doctor: $doctorId on $date');

      final response = await ApiService.post(
        '${ApiConfig.appointments}/available',
        {'doctorId': doctorId, 'date': date},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final slots = response['data']?['slots'] ?? [];
        debugPrint('✅ Found ${slots.length} available slots');
      } else {
        debugPrint('❌ Failed to fetch slots: ${response['message']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Get Available Slots Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch available slots: $e',
      };
    }
  }
}
