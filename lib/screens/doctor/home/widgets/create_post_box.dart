import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/providers/user_provider.dart';
import 'package:aroggyapath/utils/colors.dart';

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
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          l10n.shareInsights,
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Divider(height: 1, color: AppColors.getBorder(context)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPostAction(
                    context,
                    Icons.image_outlined,
                    l10n.photo,
                    Colors.brown,
                    onNavigateToCreatePost,
                  ),
                  _buildPostAction(
                    context,
                    Icons.videocam_outlined,
                    l10n.video,
                    Colors.redAccent,
                    onNavigateToCreatePost,
                  ),
                  _buildPostAction(
                    context,
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
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        l10n.createPost,
                        style: TextStyle(
                          color: AppColors.primary,
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
    BuildContext context,
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
