import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/providers/user_provider.dart';

class CreatePostBox extends StatelessWidget {
  final VoidCallback onNavigateToCreatePost;

  const CreatePostBox({super.key, required this.onNavigateToCreatePost});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return legacy_provider.Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        user?.profileImage != null &&
                            user!.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : const AssetImage('assets/images/doctor_booking.png')
                              as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onNavigateToCreatePost,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          l10n.shareInsights,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPostAction(
                    Icons.image_outlined,
                    l10n.photo,
                    Colors.brown,
                    onNavigateToCreatePost,
                  ),
                  _buildPostAction(
                    Icons.videocam_outlined,
                    l10n.video,
                    Colors.redAccent,
                    onNavigateToCreatePost,
                  ),
                  _buildPostAction(
                    Icons.play_circle_outline,
                    l10n.reels,
                    Colors.blueAccent,
                    onNavigateToCreatePost,
                  ),

                  InkWell(
                    onTap: onNavigateToCreatePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1664CD)),
                      ),
                      child: Text(
                        l10n.createPost,
                        style: const TextStyle(
                          color: Color(0xFF1664CD),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildPostAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
