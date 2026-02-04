import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroggyapath/providers/notification_provider.dart';
import 'package:aroggyapath/screens/doctor/home/doctor_home_screen.dart';
import 'package:aroggyapath/screens/doctor/appointments/doctor_appointments_screen.dart';
import 'package:aroggyapath/screens/doctor/reels/doctor_reels_screen.dart';
import 'package:aroggyapath/screens/doctor/profile/doctor_profile_screen.dart';
import 'package:aroggyapath/screens/doctor/messages/doctor_messages_list_screen.dart';
import 'package:aroggyapath/services/call_manager_service.dart';

import 'package:aroggyapath/l10n/app_localizations.dart';

class DoctorMainNavigation extends ConsumerStatefulWidget {
  const DoctorMainNavigation({super.key});

  @override
  ConsumerState<DoctorMainNavigation> createState() =>
      _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends ConsumerState<DoctorMainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize CallManager when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('👨‍⚕️ Doctor Dashboard Loaded - Initializing CallManager');
      CallManager.instance.initialize(context);
    });
  }

  final List<Widget> _screens = const [
    DoctorHomeScreen(),
    DoctorAppointmentsScreen(),
    DoctorReelsScreen(),
    DoctorMessagesListScreen(),
    DoctorProfileScreen(),
  ];

  // ✅ Public method to navigate to specific tab
  void navigateToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 10,
          selectedItemColor: const Color(0xFF1664CD),
          unselectedItemColor: const Color(0xFF4B5563),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.home_outlined, size: 28),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.home, size: 28),
              ),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(
                Icons.calendar_today_outlined,
                appointmentUnreadCountProvider,
              ),
              activeIcon: _buildBadgeIcon(
                Icons.calendar_today,
                appointmentUnreadCountProvider,
              ),
              label: l10n.navAppointments,
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.video_library_outlined, size: 26),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.video_library, size: 26),
              ),
              label: l10n.navReels,
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(
                Icons.mail_outline,
                messageUnreadCountProvider,
              ),
              activeIcon: _buildBadgeIcon(
                Icons.mail,
                messageUnreadCountProvider,
              ),
              label: l10n.navMessages,
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.person_outline, size: 28),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.person, size: 28),
              ),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(IconData iconData, dynamic provider) {
    final unreadCount = ref.watch(provider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Icon(iconData, size: 26),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF1664CD), // Blue dot
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
