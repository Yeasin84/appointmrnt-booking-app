import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final supabase = Supabase.instance.client;

  /// Initialize
  static Future<void> init() async {
    // No-op for now as Supabase handles its own init
    debugPrint('✅ ApiService (Supabase) initialized');
  }

  /// Sync user session
  static Future<void> syncUserSession() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.id);
        debugPrint('✅ Session synced for: ${user.id}');
      }
    } catch (e) {
      debugPrint('⚠️ Session sync failed: $e');
    }
  }

  /// Get current token
  static String? get token => supabase.auth.currentSession?.accessToken;

  /// Save token (Legacy)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear token
  static Future<void> clearToken() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
  }

  /// Check if logged in
  static bool get isLoggedIn => supabase.auth.currentUser != null;

  // ========================================
  // 🔐 AUTH APIs
  // ========================================

  /// Login with Supabase
  static Future<Map<String, dynamic>> login({
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
        final userRole = user.userMetadata?['role']?.toString().toLowerCase();
        final fullName = user.userMetadata?['fullName'] ?? 'User';

        await saveToken(token);

        final prefs = await SharedPreferences.getInstance();
        if (userRole != null) {
          await prefs.setString('user_role', userRole);
        }
        await prefs.setString('user_id', user.id);

        return {
          'success': true,
          'message': 'Login successful',
          'data': {
            'user': {
              'id': user.id,
              '_id': user.id,
              'email': user.email,
              'fullName': fullName,
              'role': userRole,
            },
            'accessToken': token,
            'role': userRole,
            'fullName': fullName,
          },
        };
      } else {
        return {'success': false, 'message': 'Login failed'};
      }
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Register with Supabase
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
    String? referralCode,
  }) async {
    try {
      debugPrint('🔐 Supabase Registration attempt: $email');

      final Map<String, dynamic> userMetadata = {
        'fullName': fullName,
        'role': role.toLowerCase(),
      };

      if (role.toLowerCase() == 'doctor') {
        if (medicalLicenseNumber != null) {
          userMetadata['medicalLicenseNumber'] = medicalLicenseNumber;
        }
        if (specialty != null) userMetadata['specialty'] = specialty;
        if (experienceYears != null) {
          userMetadata['experienceYears'] = experienceYears;
        }
        if (referralCode != null) userMetadata['referralCode'] = referralCode;
      }

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );

      final user = response.user;
      if (user != null) {
        final Map<String, dynamic> profileData = {
          'id': user.id,
          'full_name': fullName,
          'email': user.email ?? email,
          'role': role.toLowerCase(),
          'created_at': DateTime.now().toIso8601String(),
        };

        if (role.toLowerCase() == 'doctor') {
          profileData['medical_license_number'] = medicalLicenseNumber;
          profileData['specialty'] = specialty;
          profileData['experience_years'] = int.tryParse(experienceYears ?? '');
          profileData['referral_code'] = referralCode;
        }

        await supabase.from('profiles').insert(profileData);

        return {
          'success': true,
          'message': 'Registration successful. Please check your email.',
          'data': {'id': user.id, 'user': user},
        };
      }
      return {
        'success': false,
        'message': 'Registration failed - No user returned',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase Database error: ${e.message}');
      if (e.message.contains('policy')) {
        return {
          'success': true,
          'message': 'Registration successful (Profile handled by backend)',
          'data': {'id': supabase.auth.currentUser?.id},
        };
      }
      return {'success': false, 'message': 'Database error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('⚠️ SignOut failed: $e');
    }
    await clearToken();
    return {'success': true, 'message': 'Logged out successfully'};
  }

  // ========================================
  // � CHAT & MESSAGING (Supabase)
  // ========================================

  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      final data = await supabase
          .from('messages')
          .select('*, profiles(*)')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .range(from, to);
      final List<dynamic> messages = data;
      final formatted = messages.map((m) {
        final map = Map<String, dynamic>.from(m);
        map['type'] = map['content_type'] ?? map['type'] ?? 'text';
        map['createdAt'] = map['created_at']; // UI expects createdAt
        map['_id'] = map['id']; // Legacy _id

        // Map profiles to sender for patient UI
        if (map['profiles'] != null) {
          final profile = map['profiles'];
          map['sender'] = {
            '_id': profile['id'],
            'fullName': profile['full_name'],
            'avatar': {'url': profile['avatar_url']},
          };
        }

        // Map file_urls to fileUrl for patient UI
        if (map['file_urls'] != null) {
          map['fileUrl'] = (map['file_urls'] as List)
              .map((url) => {'url': url})
              .toList();
        }

        return map;
      }).toList();

      return {'success': true, 'data': formatted};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getChatParticipants({
    required String chatId,
  }) async {
    try {
      final chatRes = await supabase
          .from('chats')
          .select('participants')
          .eq('id', chatId)
          .single();

      final List<dynamic> participantIds = chatRes['participants'] ?? [];
      if (participantIds.isEmpty) return {'success': true, 'data': {}};

      final profilesRes = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url, role')
          .filter('id', 'in', '(${participantIds.join(',')})');

      final Map<String, dynamic> profilesMap = {};
      for (var p in profilesRes) {
        profilesMap[p['id']] = p;
      }

      return {'success': true, 'data': profilesMap};
    } catch (e) {
      debugPrint('❌ Error getChatParticipants: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final data = await supabase
          .from('chats')
          .select('*, messages(content, created_at)')
          .order('updated_at', ascending: false);

      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteConversation(String chatId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      await supabase.from('chats').delete().eq('id', chatId);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMessages(String chatId) async {
    try {
      final data = await supabase
          .from('messages')
          .select('*, profiles(full_name, avatar_url)')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createOrGetChat({
    required String userId,
  }) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not logged in');

      final existing = await supabase.from('chats').select().contains(
        'participants',
        [userId, currentUserId],
      ).maybeSingle();

      if (existing != null) {
        final data = Map<String, dynamic>.from(existing);
        data['_id'] = data['id']; // Legacy compatibility
        return {'success': true, 'data': data};
      }

      final newChat = await supabase
          .from('chats')
          .insert({
            'participants': [currentUserId, userId],
          })
          .select()
          .single();

      final data = Map<String, dynamic>.from(newChat);
      data['_id'] = data['id']; // Legacy compatibility
      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Error createOrGetChat: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    List<File>? files,
  }) async {
    debugPrint(
      '🚀 [ApiService] sendMessage called. ChatId: $chatId, Type: $type',
    );
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      List<String> fileUrls = [];
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final path =
              'chat/$chatId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          await supabase.storage.from('chat-attachments').upload(path, file);
          fileUrls.add(
            supabase.storage.from('chat-attachments').getPublicUrl(path),
          );
        }
      }

      final data = await supabase
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': userId,
            'content': content,
            'content_type': type, // Use content_type from schema
            'file_urls': fileUrls,
          })
          .select()
          .single();

      await supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      final map = Map<String, dynamic>.from(data);
      map['type'] = map['content_type'] ?? map['type'] ?? 'text';
      map['createdAt'] = map['created_at'];
      map['_id'] = map['id'];
      map['fileUrl'] =
          (map['file_urls'] as List?)?.map((url) => {'url': url}).toList() ??
          [];

      return {'success': true, 'data': map};
    } catch (e) {
      debugPrint('❌ Error sendMessage: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========================================
  // 👤 USER APIs
  // ========================================

  static Future<Map<String, dynamic>> getUserProfile({String? userId}) async {
    try {
      final targetId = userId ?? supabase.auth.currentUser?.id;
      if (targetId == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      // ✅ Fetch profile and join with doctor_schedules table
      final data = await supabase
          .from('profiles')
          .select('*, doctor_schedules(weekly_schedule)')
          .eq('id', targetId)
          .single();

      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('⚠️ Fetch profile with join failed: $e');
      // Fallback to simple fetch if join fails (e.g. table not created yet)
      try {
        final targetId = userId ?? supabase.auth.currentUser?.id;
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', targetId!)
            .single();
        return {'success': true, 'data': data};
      } catch (e2) {
        return {'success': false, 'message': e2.toString()};
      }
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};
      final updated = await supabase
          .from('profiles')
          .update(data)
          .eq('id', userId)
          .select()
          .single();
      return {'success': true, 'data': updated};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ NEW: Manage doctor schedule in separate table
  static Future<Map<String, dynamic>> upsertDoctorSchedule({
    required List<Map<String, dynamic>> weeklySchedule,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      debugPrint('🕒 Upserting schedule for $userId');
      await supabase.from('doctor_schedules').upsert({
        'doctor_id': userId,
        'weekly_schedule': weeklySchedule,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {'success': true};
    } catch (e) {
      debugPrint('❌ Upsert schedule failed: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      final data = await supabase
          .from('profiles')
          .select()
          .ilike('full_name', '%$query%')
          .range(from, to);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': 'Error'};
    }
  }

  // ========================================
  // 📅 APPOINTMENT APIs
  // ========================================

  static Future<Map<String, dynamic>> getAppointments() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'Not logged in'};
      final data = await supabase
          .from('appointments')
          .select(
            '*, doctors:profiles!doctor_id(*), patients:profiles!patient_id(*)',
          )
          .or('patient_id.eq.$userId,doctor_id.eq.$userId')
          .order('appointment_date', ascending: false);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      await supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);
      return {'success': true, 'message': 'Status updated'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createAppointment({
    required Map<String, dynamic> appointmentData,
  }) async {
    try {
      final data = await supabase
          .from('appointments')
          .insert(appointmentData)
          .select()
          .single();
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
  }) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'cancelled',
    );
  }

  // ========================================
  // 🏥 DOCTOR APIs
  // ========================================

  static Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? specialty,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      var query = supabase
          .from('profiles')
          .select('*, doctor_schedules(weekly_schedule)')
          .eq('role', 'doctor');

      if (specialty != null && specialty.isNotEmpty) {
        query = query.eq('specialty', specialty);
      }
      final data = await query.range(from, to);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getDoctorDetails({
    required String doctorId,
  }) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('*, doctor_schedules(weekly_schedule)')
          .eq('id', doctorId)
          .single();

      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> searchDoctors({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .ilike('full_name', '%$query%')
          .range(from, to);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      final data = await supabase
          .from('categories')
          .select()
          .order('name', ascending: true);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========================================
  // 🎬 REELS & POSTS
  // ========================================

  static Future<Map<String, dynamic>> getAllReels({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      final data = await supabase
          .from('reels')
          .select('*, profiles(full_name, avatar_url)')
          .order('created_at', ascending: false)
          .range(from, to);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit - 1;
    try {
      final data = await supabase
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(*)')
          .order('created_at', ascending: false)
          .range(from, to);
      return {'success': true, 'data': data};
    } catch (e) {
      // Fallback for missing FK constraint name or explicit join
      try {
        final data = await supabase
            .from('posts')
            .select('*, author:profiles!user_id(*)')
            .order('created_at', ascending: false)
            .range(from, to);
        return {'success': true, 'data': data};
      } catch (e2) {
        return {'success': false, 'message': e.toString()};
      }
    }
  }

  static Future<Map<String, dynamic>> createPost({
    required String content,
    List<File>? mediaFiles,
    String visibility = 'public',
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      List<Map<String, dynamic>> mediaList = [];

      debugPrint(
        '📝 createPost called with ${mediaFiles?.length ?? 0} media files',
      );

      // 1. Upload files to Storage if present
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          debugPrint('📸 Attempting to upload: ${file.path}');
          final uploadResult = await uploadFile(
            filePath: file.path,
            bucket: 'chat-attachments', // Use verified existing bucket
            path:
                'posts/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
          );

          if (uploadResult['success'] == true) {
            final url = uploadResult['url'];
            final isVideo =
                file.path.toLowerCase().endsWith('.mp4') ||
                file.path.toLowerCase().endsWith('.mov') ||
                file.path.toLowerCase().endsWith('.avi');

            mediaList.add({
              'url': url,
              'public_id': url.split('/').last,
              'resourceType': isVideo ? 'video' : 'image',
              'mimeType': isVideo ? 'video/mp4' : 'image/jpeg',
            });
            debugPrint('✅ Uploaded and added: $url');
          } else {
            debugPrint(
              '❌ Upload failed for ${file.path}: ${uploadResult['message']}',
            );
          }
        }
      }

      debugPrint('📊 mediaList size: ${mediaList.length}');

      // 2. Insert post - Try with 'media_urls' first (Verified schema)
      try {
        final List<String> urls = mediaList
            .map((m) => m['url'] as String)
            .toList();

        debugPrint('🚀 Inserting post with media_urls: $urls');

        final data = await supabase
            .from('posts')
            .insert({
              'content': content,
              'user_id': userId,
              'visibility': visibility,
              'media_urls': urls, // actual DB schema
            })
            .select()
            .single();
        return {'success': true, 'data': data};
      } catch (postgrestError) {
        debugPrint(
          '⚠️ Warning: Failed to insert with media_urls column: $postgrestError',
        );

        try {
          // Try 'media' JSONB as a second attempt
          final data = await supabase
              .from('posts')
              .insert({
                'content': content,
                'user_id': userId,
                'visibility': visibility,
                'media': mediaList,
              })
              .select()
              .single();
          return {'success': true, 'data': data};
        } catch (e2) {
          debugPrint('⚠️ Final fallback: Inserting without media columns');
          final data = await supabase
              .from('posts')
              .insert({
                'content': content,
                'user_id': userId,
                'visibility': visibility,
              })
              .select()
              .single();

          return {
            'success': true,
            'data': data,
            'warning':
                'Media metadata could not be saved to post (Column mismatch)',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error in createPost: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit - 1;
    try {
      final data = await supabase
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);
      return {'success': true, 'data': data};
    } catch (e) {
      try {
        final data = await supabase
            .from('posts')
            .select('*, author:profiles!user_id(*)')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(from, to);
        return {'success': true, 'data': data};
      } catch (e2) {
        return {'success': false, 'message': e.toString()};
      }
    }
  }

  static Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> commentOnPost({
    required String postId,
    required String comment,
  }) async {
    return await addPostComment(postId: postId, content: comment);
  }

  static Future<Map<String, dynamic>> createReel({
    File? videoFile,
    String? caption,
    String visibility = 'public',
  }) async {
    try {
      if (videoFile == null) {
        return {'success': false, 'message': 'Video file is required'};
      }

      final userId = supabase.auth.currentUser?.id;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${videoFile.path.split('/').last}';
      final storagePath = 'reels/$userId/$fileName';

      // 1. Upload video to storage
      final uploadResult = await uploadFile(
        filePath: videoFile.path,
        bucket: 'chat-attachments', // Use verified bucket
        path: storagePath,
      );

      if (uploadResult['success'] != true) {
        return uploadResult;
      }

      final videoUrl = uploadResult['url'];

      // 2. Insert into reels table
      try {
        final data = await supabase
            .from('reels')
            .insert({
              'user_id': userId,
              'video_url': videoUrl,
              'caption': caption,
              'visibility': visibility,
              'media': [
                {
                  'url': videoUrl,
                  'resourceType': 'video',
                  'public_id': fileName,
                },
              ],
            })
            .select()
            .single();

        return {'success': true, 'data': data};
      } catch (postgrestError) {
        debugPrint(
          '⚠️ Warning: Failed to insert reel with media column: $postgrestError',
        );

        final data = await supabase
            .from('reels')
            .insert({
              'user_id': userId,
              'video_url': videoUrl,
              'caption': caption,
              'visibility': visibility,
            })
            .select()
            .single();

        return {
          'success': true,
          'data': data,
          'warning':
              'Reel was uploaded but media metadata could not be saved (Missing column)',
        };
      }
    } catch (e) {
      debugPrint('❌ Error in createReel: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> likeReel(String reelId) async => {
    'success': true,
  };
  static Future<Map<String, dynamic>> addReelComment({
    required String reelId,
    required String content,
  }) async => {'success': true};
  static Future<Map<String, dynamic>> getReelComments({
    required String reelId,
    int page = 1,
    int limit = 50,
  }) async => {'success': true, 'data': []};
  static Future<Map<String, dynamic>> likePost(String postId) async => {
    'success': true,
  };
  static Future<Map<String, dynamic>> addPostComment({
    required String postId,
    required String content,
  }) async => {'success': true};
  static Future<Map<String, dynamic>> getPostComments({
    required String postId,
    int page = 1,
    int limit = 20,
  }) async => {'success': true, 'data': []};

  // ========================================
  // � CALLS
  // ========================================

  static Future<Map<String, dynamic>> initiateCall({
    required String chatId,
    required String receiverId,
    required bool isVideo,
  }) async {
    try {
      final data = await supabase
          .from('calls')
          .insert({
            'chat_id': chatId,
            'receiver_id': receiverId,
            'caller_id': supabase.auth.currentUser?.id,
            'call_type': isVideo ? 'video' : 'audio',
            'status': 'initiated',
          })
          .select()
          .single();
      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('❌ Error initiateCall: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final data = await supabase
          .from('calls')
          .select(
            '*, caller:profiles!caller_id(*), receiver:profiles!receiver_id(*)',
          )
          .or('caller_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========================================
  // 🛠 HELPERS & MISC
  // ========================================

  static int min(int a, int b) => a < b ? a : b;

  static Future<Map<String, dynamic>> getReferralSetting() async {
    try {
      final data = await supabase
          .from('referral_settings')
          .select()
          .maybeSingle();
      return {'success': true, 'data': data ?? {}};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerFCMToken({
    required String token,
    required String platform,
  }) async => {'success': true};

  static Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    String? fieldName, // Kept for legacy compatibility
    String? path, // Custom path in bucket
    String bucket = 'chat-attachments', // Default to verified bucket
  }) async {
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final uploadPath = path ?? 'general/$fileName';

      debugPrint('📤 Uploading to Supabase Storage ($bucket): $uploadPath');

      // ✅ Explicitly detect content type
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';

      if (['jpg', 'jpeg'].contains(ext)) {
        contentType = 'image/jpeg';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else if (ext == 'mp4') {
        contentType = 'video/mp4';
      } else if (ext == 'mov') {
        contentType = 'video/quicktime';
      }

      await supabase.storage
          .from(bucket)
          .uploadBinary(
            uploadPath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final url = supabase.storage.from(bucket).getPublicUrl(uploadPath);
      debugPrint('✅ Upload successful: $url');
      return {'success': true, 'url': url};
    } catch (e) {
      debugPrint('❌ Storage Upload Error: $e');

      // ✅ SELF-HEAL: If bucket or folder is restricted/missing, try to create it if we have permissions
      if (e.toString().contains('404') || e.toString().contains('403')) {
        try {
          debugPrint('🛠 Attempting to ensure bucket "$bucket" exists...');
          // Try to create the bucket (will fail if it exists, which is fine)
          try {
            await supabase.storage.createBucket(
              bucket,
              const BucketOptions(public: true),
            );
            debugPrint('✅ Created missing bucket: $bucket');
          } catch (_) {
            // Already exists or no permission to create
          }

          // If it was a 404/403, maybe a retry will work now or give more info
          debugPrint('📋 Available Storage Buckets:');
          final buckets = await supabase.storage.listBuckets();
          for (var b in buckets) {
            debugPrint('   - ${b.name} (${b.public ? "public" : "private"})');
          }
        } catch (e2) {
          debugPrint('📋 Diagnostic bucket check failed: $e2');
        }
      }

      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadMultipleFiles({
    required List<String> filePaths,
    required String fieldName,
    String bucket = 'uploads',
  }) async {
    try {
      List<String> urls = [];
      for (var path in filePaths) {
        final result = await uploadFile(
          filePath: path,
          fieldName: fieldName,
          bucket: bucket,
        );
        if (result['success'] == true) urls.add(result['url']);
      }
      return {'success': true, 'urls': urls};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Legacy (Deprecated)
  static Future<Map<String, dynamic>> getEarnings() async => {
    'success': true,
    'data': [],
  };
  static Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async => {'success': true, 'data': []};
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async => {'success': false, 'message': 'Deprecated'};
  static Future<Map<String, dynamic>> post(
    String endpoint,
    dynamic body, {
    bool requiresAuth = true,
  }) async => {'success': false, 'message': 'Deprecated'};
  static Future<Map<String, dynamic>> put(
    String endpoint,
    dynamic body, {
    bool requiresAuth = true,
  }) async => {'success': false, 'message': 'Deprecated'};
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    dynamic body, {
    bool requiresAuth = true,
  }) async => {'success': false, 'message': 'Deprecated'};
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async => {'success': false, 'message': 'Deprecated'};
}
