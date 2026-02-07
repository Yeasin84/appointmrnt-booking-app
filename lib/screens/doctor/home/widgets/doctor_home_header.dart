import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:aroggyapath/providers/user_provider.dart';
import 'package:aroggyapath/providers/notification_provider.dart';
import 'package:aroggyapath/screens/doctor/home/notifications/doctor_notifications.dart';
import 'package:aroggyapath/widgets/custom_image.dart';

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
                const Color(0xFF1664CD).withValues(alpha: 0.1),
                Colors.white,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2C49),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.specialty ?? 'General Physician',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF1B2C49),
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
