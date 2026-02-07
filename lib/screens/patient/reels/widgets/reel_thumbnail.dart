import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';

class ReelThumbnail extends StatelessWidget {
  final Map<String, dynamic> reel;
  final VoidCallback onTap;

  const ReelThumbnail({super.key, required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = reel['thumbnail']?['url'];
    final author = reel['author'];
    final doctorName =
        author?['fullName'] ?? AppLocalizations.of(context)!.unknownDoctor;
    final caption = reel['caption'] ?? '';
    final likesCount = reel['likesCount'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnailImage(thumbnailUrl, reel['video']?['url']),
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              _buildLikesBadge(likesCount),
              _buildInfoOverlay(doctorName, caption),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(String? thumbnailUrl, String? videoUrl) {
    return FutureBuilder<Uint8List?>(
      future: _generateThumbnail(thumbnailUrl, videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }

        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
          return Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        }

        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.videocam, size: 50, color: Colors.grey),
    );
  }

  Widget _buildLikesBadge(int likesCount) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text(
              _formatCount(likesCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoOverlay(String doctorName, String caption) {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doctorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Future<Uint8List?> _generateThumbnail(
    String? thumbnailUrl,
    String? videoUrl,
  ) async {
    try {
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) return null;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        return await VideoThumbnail.thumbnailData(
          video: videoUrl,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 400,
          quality: 75,
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating thumbnail: $e');
    }
    return null;
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
