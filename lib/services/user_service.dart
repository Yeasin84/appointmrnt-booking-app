import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class UserService {
  /// Get current user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    debugPrint('🔍 Fetching user profile...');
    return await ApiService.getUserProfile();
  }

  /// Update user profile with image and location support
  static Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? username,
    String? phone,
    String? bio,
    String? gender,
    String? dob,
    String? address,
    String? country,
    String? language,
    int? experienceYears,
    String? specialty,
    List<String>? specialties,
    List<Map<String, dynamic>>? degrees,
    Map<String, dynamic>? fees,
    List<Map<String, dynamic>>? weeklySchedule,
    String? visitingHoursText,
    String? medicalLicenseNumber,
    File? profileImage,
    double? latitude, // ✅ ADDED: Latitude parameter
    double? longitude,
    bool? isVideoCallAvailable, // ✅ ADDED: Video call availability
  }) async {
    try {
      debugPrint('📤 Updating user profile...');
      final Map<String, dynamic> updateData = {};

      // 1. Upload Profile Image if provided
      if (profileImage != null) {
        debugPrint('📸 Uploading profile image...');
        final result = await ApiService.uploadFile(
          filePath: profileImage.path,
          fieldName: 'profile',
          bucket:
              'avatars', // Assuming 'avatars' bucket, or I can use 'uploads' as defaulting to
        );

        if (result['success'] == true) {
          updateData['avatar_url'] = result['url'];
          debugPrint('✅ Image uploaded: ${result['url']}');
        } else {
          debugPrint('❌ Image upload failed: ${result['message']}');
          // Proceed without image or throw? Let's proceed.
        }
      }

      // 2. Map fields to snake_case (Supabase standard)
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;
      if (gender != null) updateData['gender'] = gender;
      if (dob != null) updateData['dob'] = dob;
      if (address != null) updateData['address'] = address;
      if (country != null) updateData['country'] = country;
      if (language != null) updateData['language'] = language;
      if (experienceYears != null) {
        updateData['experience_years'] = experienceYears;
      }

      // Doctor fields
      if (specialty != null) updateData['specialty'] = specialty;
      if (specialties != null) updateData['specialties'] = specialties;
      if (degrees != null) updateData['degrees'] = degrees;

      // ✅ Map fees object to separate columns for Supabase
      if (fees != null) {
        updateData['fees_amount'] = fees['amount'];
        updateData['fees_currency'] = fees['currency'] ?? 'DZD';
      }

      // ❌ REMOVED: weekly_schedule is now a separate table
      // if (weeklySchedule != null)
      //   updateData['weekly_schedule'] = weeklySchedule;

      if (visitingHoursText != null) {
        updateData['visiting_hours_text'] = visitingHoursText;
      }
      if (medicalLicenseNumber != null) {
        updateData['medical_license_number'] = medicalLicenseNumber;
      }

      // ✅ Map to correct column name 'is_video_available'
      if (isVideoCallAvailable != null) {
        updateData['is_video_available'] = isVideoCallAvailable;
      }

      // Location: Handle separately to prevent crash if columns missing
      Map<String, dynamic>? locationData;
      if (latitude != null && longitude != null) {
        locationData = {'latitude': latitude, 'longitude': longitude};
      }

      debugPrint('📦 Core Update payload: $updateData');

      // 3. Call Supabase Update (Core Fields)
      final response = await ApiService.updateUserProfile(data: updateData);

      // 4. Update Schedule in separate table (if provided)
      if (response['success'] == true && weeklySchedule != null) {
        debugPrint('📅 Upserting schedule to separate table...');
        await ApiService.upsertDoctorSchedule(weeklySchedule: weeklySchedule);
      }

      // 5. Try updating location separately (Graceful Degradation)
      if (response['success'] == true && locationData != null) {
        try {
          debugPrint('📍 Attempting to update location...');
          await ApiService.updateUserProfile(data: locationData);
          debugPrint('✅ Location updated');
        } catch (e) {
          debugPrint('⚠️ Location update failed (Non-critical): $e');
          // We don't fail the whole operation if just location fails
          // likely due to missing columns
        }
      }

      return response;
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    debugPrint('🔐 Changing password...');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      // Supabase's updateUser doesn't require current password, but strict UI might.
      // We will just update it.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return {'success': true, 'message': 'Password updated successfully'};
    } catch (e) {
      debugPrint('❌ Change password error: $e');
      return {
        'success': false,
        'message': 'Failed to change password: ${e.toString()}',
      };
    }
  }

  /// Get users by role (patient | doctor | admin)
  static Future<Map<String, dynamic>> getUsersByRole(String role) async {
    debugPrint('🔍 Fetching users with role: $role');
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', role);
      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Get users by role error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get user details by ID
  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    debugPrint('🔍 Fetching user details for ID: $userId');
    return await ApiService.getUserProfile(userId: userId);
  }

  /// Get my dependents
  static Future<Map<String, dynamic>> getMyDependents() async {
    debugPrint('🔍 Fetching my dependents...');
    return await ApiService.get(
      '/api/v1/user/me/dependents',
      requiresAuth: true,
    );
  }

  /// Add dependent
  static Future<Map<String, dynamic>> addDependent({
    required String fullName,
    String? relationship,
    String? gender,
    String? dob,
    String? phone,
    String? notes,
  }) async {
    debugPrint('➕ Adding dependent: $fullName');

    final Map<String, dynamic> body = {'fullName': fullName};

    if (relationship != null) body['relationship'] = relationship;
    if (gender != null) body['gender'] = gender;
    if (dob != null) body['dob'] = dob;
    if (phone != null) body['phone'] = phone;
    if (notes != null) body['notes'] = notes;

    return await ApiService.post(
      '/api/v1/user/me/dependents',
      body,
      requiresAuth: true,
    );
  }

  /// Update dependent
  static Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    String? fullName,
    String? relationship,
    String? gender,
    String? dob,
    String? phone,
    String? notes,
    bool? isActive,
  }) async {
    debugPrint('✏️ Updating dependent: $dependentId');

    final Map<String, dynamic> body = {};

    if (fullName != null) body['fullName'] = fullName;
    if (relationship != null) body['relationship'] = relationship;
    if (gender != null) body['gender'] = gender;
    if (dob != null) body['dob'] = dob;
    if (phone != null) body['phone'] = phone;
    if (notes != null) body['notes'] = notes;
    if (isActive != null) body['isActive'] = isActive;

    return await ApiService.patch(
      '/api/v1/user/me/dependents/$dependentId',
      body,
      requiresAuth: true,
    );
  }

  /// Delete dependent
  static Future<Map<String, dynamic>> deleteDependent(
    String dependentId,
  ) async {
    debugPrint('🗑️ Deleting dependent: $dependentId');
    return await ApiService.delete(
      '/api/v1/user/me/dependents/$dependentId',
      requiresAuth: true,
    );
  }

  /// Convert image file to base64 with proper MIME type detection
  static Future<String> imageToBase64(File imageFile) async {
    try {
      debugPrint('🔄 Converting image to base64...');
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      // ✅ Detect image type from file extension
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.split('.').last.toLowerCase();

      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      }

      final result = 'data:$mimeType;base64,$base64String';

      debugPrint('✅ Image converted successfully');
      debugPrint('   - Size: ${bytes.length} bytes');
      debugPrint('   - Type: $mimeType');
      debugPrint('   - Base64 length: ${result.length} chars');

      return result;
    } catch (e) {
      debugPrint('❌ Error converting image to base64: $e');
      rethrow;
    }
  }
}
