import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/screens/patient/profile/add_dependents_screen.dart';
import 'package:aroggyapath/screens/patient/profile/edit_dependent_screen.dart';
import 'package:aroggyapath/screens/patient/profile/dependents_list_screen.dart';
import 'package:aroggyapath/services/call_manager_service.dart';
import 'package:aroggyapath/services/socket_service.dart';
import 'package:aroggyapath/screens/patient/notification/patient_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aroggyapath/screens/patient/navigation/patient_main_navigation.dart';
import 'package:aroggyapath/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:aroggyapath/screens/splash/splash_screen.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/services/notification_poller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aroggyapath/providers/locale_provider.dart';
import 'package:aroggyapath/services/auth_service.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _userRole;
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>(); // ✅ ADDED

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ Register observer
    _checkLoginStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    super.dispose();
  }

  // ✅ Handle App Lifecycle Changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 App Lifecycle State: $state');

    if (state == AppLifecycleState.resumed) {
      // App came to foreground - Refresh data
      debugPrint('⚡ App resumed - Refreshing notifications & socket...');

      if (_isLoggedIn) {
        // 1. Refresh Notifications
        NotificationPoller().refreshNotifications();

        // 2. Ensure Socket is connected
        SharedPreferences.getInstance().then((prefs) {
          final uid = prefs.getString('user_id');
          if (uid != null && !SocketService.instance.isConnected) {
            SocketService.instance.connect(uid);
          }
        });
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔍 Checking app login status...');
      debugPrint('═══════════════════════════════════════');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role');
      final userId = prefs.getString('user_id');

      debugPrint('📦 SharedPreferences Check:');
      debugPrint('   • Token: ${token != null ? "✅ Found" : "❌ Not found"}');
      debugPrint('   • Role: ${role ?? "❌ Not found"}');
      debugPrint('   • User ID: ${userId ?? "❌ Not found"}');

      // Update state immediately
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _userRole = role?.toLowerCase();
        _isLoading = false;
      });

      if (_isLoggedIn) {
        debugPrint('✅ User is logged in as: $_userRole');
        debugPrint(
          '🚀 Will navigate to: ${_userRole == "doctor" ? "Doctor Dashboard" : "Patient Dashboard"}',
        );

        // Initialize CallManager after navigation is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigatorKey.currentContext != null) {
            CallManager.instance.initialize(_navigatorKey.currentContext!);
            debugPrint('✅ CallManager initialized');
          }
        });
      } else {
        debugPrint('⚠️ User not logged in - Will show SplashScreen');
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');

      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey, // ✅ ADDED for CallManager
      title: 'AroggyaPath',
      locale: currentLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      debugShowCheckedModeBanner: false,

      home: _buildHomeScreen(),

      // ✅ Named routes for navigation
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/patient-home': (context) => const PatientMainNavigation(),
        '/doctor-home': (context) => const DoctorMainNavigation(),
        '/dependents-list': (context) => const DependentsListScreen(),
        '/add-dependent': (context) => const AddDependentScreen(),
        '/edit-dependent': (context) => const EditDependentScreen(),
        '/notifications': (context) => const NotificationScreen(),
        // Add more routes as needed
      },

      // ✅ Route generator for dynamic routes
      onGenerateRoute: (settings) {
        debugPrint('🔗 Navigating to: ${settings.name}');

        if (settings.name == '/edit-dependent') {
          return MaterialPageRoute(
            builder: (context) => const EditDependentScreen(),
            settings: settings,
          );
        }

        return null; // Let the routes table handle it
      },

      // ✅ Handle unknown routes
      onUnknownRoute: (settings) {
        debugPrint('⚠️ Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
    );
  }

  Widget _buildHomeScreen() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1664CD)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Checking authentication',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      debugPrint('📱 Rendering: SplashScreen (Not logged in)');
      return const SplashScreen();
    }

    debugPrint('📱 Rendering: ${_userRole?.toUpperCase()} Dashboard');

    switch (_userRole) {
      case 'doctor':
        debugPrint('   → DoctorMainNavigation');
        return const DoctorMainNavigation();

      case 'patient':
        debugPrint('   → PatientMainNavigation');
        return const PatientMainNavigation();

      case 'admin':
        debugPrint('   → AdminMainNavigation (Fallback to Patient)');
        return const PatientMainNavigation();

      default:
        debugPrint('⚠️ Unknown role detected: $_userRole');
        debugPrint('🔄 Logging out and redirecting to splash...');

        // Logout in background
        _logout();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange[700]),
                const SizedBox(height: 24),
                const Text(
                  'Invalid Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your session is invalid.\nPlease login again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoggedIn = false;
                      _userRole = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1664CD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _logout() async {
    try {
      debugPrint('🔄 Logging out user (Optimistic)...');

      // 1. Immediately clear local state
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
          _isLoading = false; // Ensure loading is off so splash/login shows
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear ApiService token in memory
      await ApiService.clearToken();
      debugPrint('✅ Local state cleared immediately');

      // 2. Perform background cleanup (Fire and Forget)
      Future.wait([
            // Stop notification polling
            Future(() {
              NotificationPoller().stopPolling();
              return NotificationPoller().clearAllData();
            }),

            // Backend Logout
            AuthService().logout(),

            // Socket Disconnect
            Future(() {
              SocketService.instance.disconnect();
              debugPrint('✅ Socket disconnected');
            }),

            // CallManager Dispose
            Future(() {
              CallManager.instance.dispose();
            }),
          ])
          .then((_) {
            debugPrint('✅ Background logout tasks completed');
          })
          .catchError((e) {
            debugPrint('⚠️ Background logout tasks had error: $e');
          });
    } catch (e) {
      debugPrint('❌ Error during optimistic logout: $e');
      // Even if error, ensure state is cleared
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
        });
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 🔧 DEBUGGING HELPER WIDGET (Remove in production)
// ═══════════════════════════════════════════════════════════════

/// ✅ Optional: Debug overlay to check token status
class DebugTokenOverlay extends StatelessWidget {
  final Widget child;

  const DebugTokenOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // Debug info in bottom-right corner
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ApiService.isLoggedIn ? Icons.check_circle : Icons.cancel,
                      color: ApiService.isLoggedIn ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ApiService.isLoggedIn ? 'Logged In' : 'Not Logged In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (ApiService.token != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Token: ${ApiService.token!.substring(0, 10)}...',
                    style: const TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
