import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aroggyapath/utils/api_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Use Supabase client
  static final supabase = Supabase.instance.client;

  // Use ApiConfig for base URL (Keep for legacy compatibility if needed)
  static String get baseUrl => ApiConfig.baseUrl;

  static String? _cachedToken;
  static String? _cachedRole;

  /// ✅ Initialize - Load token from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      _cachedRole = prefs.getString('user_role');

      debugPrint('✅ AuthService initialized');
      debugPrint('   Token: ${_cachedToken != null ? "Found" : "Not found"}');
      debugPrint('   Role: $_cachedRole');
    } catch (e) {
      debugPrint('❌ Error initializing AuthService: $e');
    }
  }

  /// ✅ Get token (from memory cache first)
  Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      return _cachedToken;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  /// ✅ Save token
  Future<void> saveToken(String token) async {
    try {
      _cachedToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint('✅ Token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  /// ✅ Save user role
  Future<void> saveUserRole(String role) async {
    try {
      _cachedRole = role;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      debugPrint('✅ User role saved: $role');
    } catch (e) {
      debugPrint('❌ Error saving role: $e');
    }
  }

  /// ✅ LOGIN with Supabase
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Supabase Login attempt: $email');

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        final token = session.accessToken;
        // User metadata can contain the role if set during registration
        final userRole = user.userMetadata?['role']?.toString().toLowerCase();

        await saveToken(token);
        if (userRole != null) {
          await saveUserRole(userRole);
        }

        debugPrint('✅ Supabase login successful');
        return {
          'success': true,
          'data': {'user': user, 'session': session},
          'message': 'Login successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed - No user or session returned',
        };
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Login error: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// ✅ REGISTER with Supabase
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String userType,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
  }) async {
    try {
      debugPrint('🔐 Supabase Registration attempt: $email');

      final Map<String, dynamic> userMetadata = {
        'fullName': name,
        'role': userType.toLowerCase(),
      };

      if (userType.toLowerCase() == 'doctor') {
        if (medicalLicenseNumber != null) {
          userMetadata['medicalLicenseNumber'] = medicalLicenseNumber;
        }
        if (specialty != null) userMetadata['specialty'] = specialty;
        if (experienceYears != null) {
          userMetadata['experienceYears'] = experienceYears;
        }
      }

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );

      final user = response.user;
      if (user != null) {
        debugPrint('✅ Supabase registration successful');
        return {
          'success': true,
          'data': user,
          'message':
              'Registration successful. Please check your email for verification.',
        };
      } else {
        return {'success': false, 'message': 'Registration failed'};
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Registration error: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// ✅ LOGOUT with Supabase
  Future<Map<String, dynamic>> logout() async {
    try {
      await supabase.auth.signOut();

      _cachedToken = null;
      _cachedRole = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');

      debugPrint('✅ Supabase Logout successful');
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      return {'success': false, 'message': 'Error logging out'};
    }
  }

  /// ✅ CHECK IF LOGGED IN
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// ✅ GET USER ROLE
  Future<String?> getUserRole() async {
    if (_cachedRole != null) {
      return _cachedRole;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedRole = prefs.getString('user_role');
      return _cachedRole;
    } catch (e) {
      debugPrint('❌ Error getting role: $e');
      return null;
    }
  }

  /// ✅ VERIFY SESSION with Supabase
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final response = await supabase.auth.getUser();
      if (response.user != null) {
        return {
          'success': true,
          'message': 'Session is valid',
          'user': response.user,
        };
      } else {
        await logout();
        return {
          'success': false,
          'message': 'Session expired or invalid',
          'requiresLogin': true,
        };
      }
    } catch (e) {
      debugPrint('❌ Session verification error: $e');
      return {'success': false, 'message': 'Could not verify session'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔑 FORGOT PASSWORD METHODS
  // ═══════════════════════════════════════════════════════════════

  /// ✅ Forgot Password (Send Reset Email) with Supabase
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint('� Supabase Forgot Password attempt: $email');

      await supabase.auth.resetPasswordForEmail(email);

      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Forgot Password error: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Forgot password error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// ✅ Verify OTP with Supabase
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      debugPrint('🔐 Supabase Verify OTP attempt: $email');

      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      if (response.user != null) {
        return {'success': true, 'message': 'OTP Verified'};
      } else {
        return {'success': false, 'message': 'Invalid OTP'};
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Verify OTP error: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Verify OTP error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// ✅ Reset Password with Supabase
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      debugPrint('� Supabase Reset Password attempt');

      // In Supabase, usually after verifying OTP for recovery, you are signed in and can update password
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        return {'success': true, 'message': 'Password reset successfully'};
      } else {
        return {'success': false, 'message': 'Failed to reset password'};
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Reset Password error: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
}
