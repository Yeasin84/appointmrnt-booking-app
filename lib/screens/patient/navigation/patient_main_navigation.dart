import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroggyapath/screens/patient/home/patient_home_screen.dart';
import 'package:aroggyapath/screens/patient/appointments/patient_appointments_screen.dart';
import 'package:aroggyapath/screens/patient/reels/patient_reels_screen.dart';
import 'package:aroggyapath/screens/patient/messages/patient_messages_list_screen.dart';
import 'package:aroggyapath/screens/patient/profile/patient_profile_screen.dart';
import 'package:aroggyapath/providers/notification_provider.dart';
import 'package:aroggyapath/services/call_manager_service.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/utils/colors.dart';

class PatientMainNavigation extends ConsumerStatefulWidget {
  const PatientMainNavigation({super.key});

  @override
  ConsumerState<PatientMainNavigation> createState() =>
      _PatientMainNavigationState();
}

class _PatientMainNavigationState extends ConsumerState<PatientMainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🏥 Patient Dashboard Loaded - Initializing CallManager');
      CallManager.instance.initialize(context);
    });
  }

  final List<Widget> _screens = const [
    PatientHomeScreen(),
    PatientAppointmentsScreen(),
    PatientReelsScreen(),
    PatientMessagesListScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySoft,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(
                Icons.home_outlined,
                color: AppColors.textSecondary,
              ),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: _buildBadgeIcon(
                Icons.calendar_today_outlined,
                appointmentUnreadCountProvider,
                isSelected: false,
              ),
              selectedIcon: _buildBadgeIcon(
                Icons.calendar_today,
                appointmentUnreadCountProvider,
                isSelected: true,
              ),
              label: l10n.navAppointments,
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.video_library_outlined,
                color: AppColors.textSecondary,
              ),
              selectedIcon: const Icon(
                Icons.video_library,
                color: AppColors.primary,
              ),
              label: l10n.navReels,
            ),
            NavigationDestination(
              icon: _buildBadgeIcon(
                Icons.mail_outline,
                messageUnreadCountProvider,
                isSelected: false,
              ),
              selectedIcon: _buildBadgeIcon(
                Icons.mail,
                messageUnreadCountProvider,
                isSelected: true,
              ),
              label: l10n.navMessages,
            ),
            NavigationDestination(
              icon: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
              ),
              selectedIcon: const Icon(Icons.person, color: AppColors.primary),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(
    IconData iconData,
    dynamic provider, {
    required bool isSelected,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final unreadCount = ref.watch(provider);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              iconData,
              size: 26,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
