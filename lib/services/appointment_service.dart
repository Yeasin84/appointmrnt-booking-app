import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';
import 'api_service.dart';

class AppointmentService {
  static final supabase = Supabase.instance.client;

  /// Get current user's appointments (patient or doctor)
  Future<Map<String, dynamic>> getMyAppointments() async {
    try {
      debugPrint('📤 Fetching my appointments (Supabase)...');
      return await ApiService.getAppointments();
    } catch (e) {
      debugPrint('❌ Get My Appointments Error: $e');
      return {'success': false, 'message': 'Failed to fetch appointments: $e'};
    }
  }

  /// Get single appointment by ID
  Future<Map<String, dynamic>> getAppointmentById(String id) async {
    try {
      final data = await supabase
          .from('appointments')
          .select(
            '*, doctors:profiles!doctor_id(*), patients:profiles!patient_id(*)',
          )
          .eq('id', id)
          .single();
      return {'success': true, 'data': data};
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
    Map<String, dynamic>? bookedFor,
    List<String>? medicalDocuments,
    String? paymentScreenshot,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final body = {
        'doctor_id': doctorId,
        'patient_id': userId,
        'appointment_date': appointmentDate,
        'time': appointmentTime,
        'appointment_type': appointmentType ?? 'physical',
        'status': 'pending',
        if (symptoms != null && symptoms.isNotEmpty) 'symptoms': symptoms,
        'booked_for': ?bookedFor,
        'medical_documents': ?medicalDocuments,
        'payment_screenshot': ?paymentScreenshot,
      };

      debugPrint('📤 Creating appointment (Supabase) with body: $body');
      return await ApiService.createAppointment(appointmentData: body);
    } catch (e) {
      debugPrint('❌ Create Appointment Error: $e');
      return {'success': false, 'message': 'Failed to create appointment: $e'};
    }
  }

  /// Update appointment status (for doctor/admin only)
  Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status, // "accepted" | "cancelled" | "completed"
  }) async {
    try {
      debugPrint('📤 Updating appointment status to: $status (Supabase)');
      return await ApiService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );
    } catch (e) {
      debugPrint('❌ Update Status Error: $e');
      return {'success': false, 'message': 'Failed to update status: $e'};
    }
  }

  /// Get upcoming appointments
  Future<Map<String, dynamic>> getUpcomingAppointments() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final data = await supabase
          .from('appointments')
          .select(
            '*, doctors:profiles!doctor_id(*), patients:profiles!patient_id(*)',
          )
          .or('patient_id.eq.$userId,doctor_id.eq.$userId')
          .or('status.eq.pending,status.eq.accepted')
          .order('appointment_date', ascending: true);

      return {'success': true, 'data': data};
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
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final data = await supabase
          .from('appointments')
          .select(
            '*, doctors:profiles!doctor_id(*), patients:profiles!patient_id(*)',
          )
          .or('patient_id.eq.$userId,doctor_id.eq.$userId')
          .or('status.eq.completed,status.eq.cancelled')
          .order('appointment_date', ascending: false);

      return {'success': true, 'data': data};
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
    String? notes,
  }) async {
    try {
      debugPrint('📤 Completing appointment $appointmentId (Supabase)');
      final body = {
        'status': 'completed',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      await supabase.from('appointments').update(body).eq('id', appointmentId);

      return {'success': true};
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
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'accepted',
    );
  }

  /// Cancel appointment (for doctor/admin)
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    return await ApiService.cancelAppointment(appointmentId: appointmentId);
  }

  /// Get available appointment slots (Locally calculated)
  Future<Map<String, dynamic>> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    try {
      debugPrint(
        '📤 Calculating available slots for doctor: $doctorId on $date',
      );

      // 1. Fetch Doctor's Schedule
      final doctorRes = await ApiService.getDoctorDetails(doctorId: doctorId);
      if (doctorRes['success'] != true) throw Exception('Doctor not found');

      final doctor = Doctor.fromJson(doctorRes['data']);
      if (doctor.weeklySchedule == null) {
        return {
          'success': true,
          'data': {'slots': []},
        };
      }

      // 2. Identify day of week
      final dayName = _getDayName(DateTime.parse(date));
      final daySchedule = doctor.weeklySchedule!.firstWhere(
        (s) => s.day.toLowerCase() == dayName.toLowerCase(),
        orElse: () => WeeklySchedule(day: dayName, isActive: false, slots: []),
      );

      if (!daySchedule.isActive) {
        return {
          'success': true,
          'data': {'slots': []},
        };
      }

      // 3. Fetch existing appointments for that doctor on that date
      final appointmentsRes = await supabase
          .from('appointments')
          .select('time')
          .eq('doctor_id', doctorId)
          .eq('appointment_date', date)
          .neq('status', 'cancelled');

      final List bookedTimes = (appointmentsRes as List)
          .map((a) => a['time'])
          .toList();

      // 4. Map slots and mark isBooked
      final availableSlots = daySchedule.slots.map((slot) {
        return {
          'start': slot.start,
          'end': slot.end,
          'isBooked': bookedTimes.contains(slot.start),
        };
      }).toList();

      return {
        'success': true,
        'data': {'slots': availableSlots},
      };
    } catch (e) {
      debugPrint('❌ Get Available Slots Error: $e');
      return {
        'success': false,
        'message': 'Failed to calculate available slots: $e',
      };
    }
  }

  String _getDayName(DateTime date) {
    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return dayNames[date.weekday - 1];
  }
}
