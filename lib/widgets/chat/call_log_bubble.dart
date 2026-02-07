import 'package:flutter/material.dart';

class CallLogBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CallLogBubble({
    super.key,
    required this.message,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Both doctor and patient use slightly different keys for ID in their maps
    // but the bubble logic itself is the same.
    // We'll normalize keys or handle both.
    final String callType = message['call_type']?.toString() ?? 'audio';
    final String status = message['status']?.toString() ?? 'ended';
    final String duration = message['duration']?.toString() ?? '';
    final String content = message['content']?.toString() ?? 'Call';

    final bool isVideo = callType == 'video';
    Color iconColor;
    IconData iconData;

    switch (status) {
      case 'missed':
        iconColor = Colors.red;
        iconData = isVideo ? Icons.missed_video_call : Icons.phone_missed;
        break;
      case 'declined':
        iconColor = Colors.grey;
        iconData = isVideo ? Icons.videocam_off : Icons.phone_disabled;
        break;
      case 'cancelled':
        iconColor = Colors.grey;
        iconData = isVideo ? Icons.videocam : Icons.phone;
        break;
      default:
        iconColor = const Color(0xFF6C5CE7);
        iconData = isVideo ? Icons.videocam : Icons.phone;
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Text(
                  status == 'ended' && duration.isNotEmpty
                      ? '${content.replaceFirst(' ($duration)', '')} ($duration)'
                      : content,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
