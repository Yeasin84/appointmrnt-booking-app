import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

// New Imports
import 'reels_viewer_screen.dart';
import 'package:aroggyapath/utils/colors.dart';

class DoctorReelsScreen extends StatefulWidget {
  const DoctorReelsScreen({super.key});

  @override
  State<DoctorReelsScreen> createState() => _DoctorReelsScreenState();
}

class _DoctorReelsScreenState extends State<DoctorReelsScreen> {
  List<Map<String, dynamic>> reelsList = [];
  bool isLoading = true;
  bool hasError = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReels();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMore) {
      _loadMoreReels();
    }
  }

  Future<void> _loadReels() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      debugPrint('📤 Loading reels...');
      final response = await ApiService.getAllReels(page: 1, limit: 20);

      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList = items
              .map((item) => item as Map<String, dynamic>)
              .toList();
          currentPage = 1;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
        debugPrint('✅ Loaded ${reelsList.length} reels');
      }
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.failedLoadReels}: $e')));
      }
    }
  }

  Future<void> _loadMoreReels() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getAllReels(
        page: currentPage + 1,
        limit: 20,
      );

      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList.addAll(
            items.map((item) => item as Map<String, dynamic>).toList(),
          );
          currentPage++;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more reels: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshReels() async {
    await _loadReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorMainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.reelsLabel,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReels,
        child: isLoading && reelsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.failedLoadReels),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadReels,
                      child: Text(AppLocalizations.of(context)!.retryLabel),
                    ),
                  ],
                ),
              )
            : reelsList.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context)!.noReelsAvailable),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: reelsList.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reelsList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildReelThumbnail(reelsList[index], index);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildReelThumbnail(Map<String, dynamic> reel, int index) {
    final thumbnailUrl = reel['thumbnail']?['url'];
    final author = reel['author'];
    final doctorName =
        author?['fullName'] ?? AppLocalizations.of(context)!.unknownDoctor;
    final caption = reel['caption'] ?? '';
    final likesCount = reel['likesCount'] ?? 0;
    final visibility = reel['visibility'] ?? 'public';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReelsViewerScreen(reelsList: reelsList, initialIndex: index),
          ),
        );

        if (result == true) {
          _loadReels();
        }
      },
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
              FutureBuilder<Uint8List?>(
                future: _generateThumbnail(thumbnailUrl, reel['video']?['url']),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.videocam,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    );
                  }

                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.videocam,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              if (visibility == 'private')
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.doctorsOnlyLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
              ),

              Positioned(
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoUrl,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 400,
          quality: 75,
        );
        return uint8list;
      }
    } catch (e) {
      debugPrint('❌ Error generating thumbnail: $e');
    }
    return null;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
