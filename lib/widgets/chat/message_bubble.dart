import 'package:flutter/material.dart';
import 'package:aroggyapath/widgets/custom_image.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final String content;
  final bool isMe;
  final String? senderAvatar;
  final String? currentUserAvatar;
  final List<String> fileUrls;
  final String formattedTime;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String)? onFileTap;

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.content,
    required this.isMe,
    this.senderAvatar,
    this.currentUserAvatar,
    required this.fileUrls,
    required this.formattedTime,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipOval(
                  child: CustomImage(
                    imageUrl: senderAvatar,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholderAsset: 'assets/images/doctor1.png',
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: isMe
                          ? const Radius.circular(22)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isMe ? 0.1 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileUrls.isNotEmpty)
                        ...fileUrls.map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => onFileTap?.call(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CustomImage(
                                  imageUrl: url,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (content.isNotEmpty && content.trim() != '')
                        Text(
                          content,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : const Color(0xFF1B2C49),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 6,
                    left: isMe ? 0 : 8,
                    right: isMe ? 8 : 0,
                  ),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ClipOval(
                  child: CustomImage(
                    imageUrl: currentUserAvatar,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholderAsset: isMe
                        ? 'assets/images/profile.png'
                        : 'assets/images/doctor1.png',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
