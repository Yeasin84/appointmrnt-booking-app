import 'package:aroggyapath/app.dart';
import 'package:aroggyapath/providers/user_provider.dart';
import 'package:aroggyapath/providers/dependent_provider.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/services/socket_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aroggyapath/firebase_options.dart';
import 'package:aroggyapath/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:aroggyapath/providers/doctor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroggyapath/providers/locale_provider.dart';
import 'package:aroggyapath/providers/theme_provider.dart';
import 'package:aroggyapath/utils/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background Message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // ========================================
  // CRITICAL: Initialize only essential services synchronously
  // ========================================

  // 1. Initialize Firebase (required for background message handler)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Firebase core initialized');
  } catch (e) {
    debugPrint('❌ Firebase Init Error: $e');
  }

  debugPrint('Starting app initialization...');

  // 2. Load saved locale for immediate application startup
  final savedLocaleCode = await getSavedLocaleCode();
  final initialLocale = Locale(savedLocaleCode ?? 'en');

  // 3. Load saved theme mode for immediate application startup
  final savedThemeMode = await getSavedThemeMode();

  // 4. Load token (fast - no network calls)
  await ApiService.init();
  final isLoggedIn = ApiService.isLoggedIn;
  debugPrint('🔍 Token status: ${isLoggedIn ? "Logged In" : "Not Logged In"}');

  debugPrint('✅ Critical initialization complete - Starting app');

  // ========================================
  // START THE APP IMMEDIATELY
  // ========================================
  runApp(
    ProviderScope(
      overrides: [
        // We initialize the localeProvider with the saved locale to avoid flicker
        localeProvider.overrideWith(
          () => LocaleNotifier()..setInitialLocale(initialLocale),
        ),
        // We initialize the themeProvider with the saved theme mode to avoid flicker
        themeProvider.overrideWith(
          () => ThemeNotifier()..setInitialThemeMode(savedThemeMode),
        ),
      ],
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider(create: (_) => UserProvider()),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => AppointmentProvider(),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => DoctorProvider(),
          ),
          legacy_provider.ChangeNotifierProvider(
            create: (_) => DependentProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // ========================================
  // DEFERRED: Initialize non-critical services in background
  // ========================================
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('🔄 Starting deferred service initialization...');

    // Initialize services in parallel for faster loading
    await Future.wait([
      // Notification Service
      _initNotificationService(),

      // User session sync (network call - deferred)
      _syncUserSession(),

      // Chat and Socket services (only if logged in)
      if (isLoggedIn) _initChatAndSocketServices(),
    ]);

    debugPrint('✅ All deferred services initialized');
  });
}

/// Initialize Notification Service in background
Future<void> _initNotificationService() async {
  try {
    await NotificationService.init();
    debugPrint('✅ Notification Service ready');
  } catch (e) {
    debugPrint('❌ Notification Service Error: $e');
  }
}

/// Sync user session in background (network call)
Future<void> _syncUserSession() async {
  try {
    await ApiService.syncUserSession();
  } catch (e) {
    debugPrint('⚠️ User session sync failed: $e');
  }
}

/// Initialize Chat and Socket services for logged-in users
Future<void> _initChatAndSocketServices() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null && userId.isNotEmpty) {
      // Initialize Socket Service
      try {
        await SocketService.instance.connect(userId);
        debugPrint('✅ Socket initialized for user: $userId');
      } catch (e) {
        debugPrint('⚠️ Socket initialization failed: $e');
      }
    } else {
      debugPrint('⚠️ User ID not found - Socket not connected');
    }
  } catch (e) {
    debugPrint('❌ Chat/Socket initialization error: $e');
  }
}
