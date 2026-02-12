import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:aroggyapath/providers/user_provider.dart';
import 'package:aroggyapath/providers/notification_provider.dart';
import 'package:aroggyapath/providers/theme_provider.dart';
import 'package:aroggyapath/screens/doctor/home/notifications/doctor_notifications.dart';
import 'package:aroggyapath/widgets/custom_image.dart';
import 'package:aroggyapath/utils/colors.dart';

class DoctorHomeHeader extends ConsumerWidget {
  final VoidCallback onProfileTap;

  const DoctorHomeHeader({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return legacy_provider.Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final generalUnreadCountValue = ref.watch(generalUnreadCountProvider);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.getBackground(context),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: CustomImage(
                  imageUrl: user?.profileImage,
                  width: 56,
                  height: 56,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Doctor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.specialty ?? 'General Physician',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Theme Toggle Button
              IconButton(
                icon: Icon(
                  ref.watch(themeProvider) == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: AppColors.getTextPrimary(context),
                  size: 24,
                ),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              // Notification Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.getTextPrimary(context),
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DoctorNotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (generalUnreadCountValue > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
