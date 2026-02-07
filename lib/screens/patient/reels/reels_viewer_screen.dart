import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'widgets/reel_comments_sheet.dart';
import 'widgets/reel_viewer_widgets.dart';

class ReelsViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> reelsList;
  final int initialIndex;

  const ReelsViewerScreen({
    super.key,
    required this.reelsList,
    required this.initialIndex,
  });

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen> {
  late PageController _pageController;
  late int currentPage;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _likedReels = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, int> _commentCounts = {};
  final Map<String, int> _shareCounts = {};
  bool _showControls = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoForPage(currentPage);

    for (var reel in widget.reelsList) {
      final reelId = reel['_id'] ?? '';
      _likedReels[reelId] = reel['isLiked'] ?? false;
      _likeCounts[reelId] = reel['likesCount'] ?? 0;
      _commentCounts[reelId] = reel['commentsCount'] ?? 0;
      _shareCounts[reelId] = reel['sharesCount'] ?? 0;
    }

    _showControls = true;
    _startHideControlsTimer();
  }

  Future<void> _initializeVideoForPage(int index) async {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]!.play();
      return;
    }

    final videoUrl = widget.reelsList[index]['video']?['url'];
    if (videoUrl == null) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      if (mounted && currentPage == index) {
        controller.play();
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error initializing video at index $index: $e');
    }
  }

  void _pauseAllExcept(int index) {
    _videoControllers.forEach((key, controller) {
      if (key != index) {
        controller.pause();
      }
    });
  }

  Future<void> _toggleLike(String reelId) async {
    final wasLiked = _likedReels[reelId] ?? false;
    setState(() {
      _likedReels[reelId] = !wasLiked;
      _likeCounts[reelId] = (_likeCounts[reelId] ?? 0) + (wasLiked ? -1 : 1);
    });

    try {
      final result = await ApiService.likeReel(reelId);
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _likedReels[reelId] = data['isLiked'] ?? !wasLiked;
          _likeCounts[reelId] = data['likesCount'] ?? _likeCounts[reelId];
        });
      } else {
        setState(() {
          _likedReels[reelId] = wasLiked;
          _likeCounts[reelId] =
              (_likeCounts[reelId] ?? 0) + (wasLiked ? 1 : -1);
        });
      }
    } catch (e) {
      debugPrint('❌ Error liking reel: $e');
      setState(() {
        _likedReels[reelId] = wasLiked;
        _likeCounts[reelId] = (_likeCounts[reelId] ?? 0) + (wasLiked ? 1 : -1);
      });
    }
  }

  void _showComments(String reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReelCommentsBottomSheet(
        reelId: reelId,
        onCommentAdded: () {
          setState(() {
            _commentCounts[reelId] = (_commentCounts[reelId] ?? 0) + 1;
          });
        },
      ),
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _seekForward(VideoPlayerController controller) {
    final currentPosition = controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 5);
    final maxDuration = controller.value.duration;
    controller.seekTo(newPosition < maxDuration ? newPosition : maxDuration);
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _seekBackward(VideoPlayerController controller) {
    final currentPosition = controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 5);
    controller.seekTo(
      newPosition > Duration.zero ? newPosition : Duration.zero,
    );
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _togglePlayPause(VideoPlayerController controller) {
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _hideControlsTimer?.cancel();
    _pageController.dispose();
    _videoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.reelsList.length,
        onPageChanged: (index) {
          setState(() => currentPage = index);
          _pauseAllExcept(index);
          _initializeVideoForPage(index);
        },
        itemBuilder: (context, index) =>
            _buildReelPage(widget.reelsList[index], index),
      ),
    );
  }

  Widget _buildReelPage(Map<String, dynamic> reel, int index) {
    final author = reel['author'];
    final doctorName =
        author?['fullName'] ?? AppLocalizations.of(context)!.unknownDoctor;
    final specialty = author?['specialty'] ?? '';
    final caption = reel['caption'] ?? '';
    final avatarUrl = author?['avatar']?['url'];
    final videoController = _videoControllers[index];
    final reelId = reel['_id'] ?? '';
    final isLiked = _likedReels[reelId] ?? false;
    final likesCount = _likeCounts[reelId] ?? 0;
    final commentsCount = _commentCounts[reelId] ?? 0;

    return Stack(
      children: [
        Positioned.fill(
          child: videoController != null && videoController.value.isInitialized
              ? _buildVideoPlayer(videoController)
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
        _buildGradientOverlay(),
        _buildBackButton(),
        _buildSidebar(reelId, isLiked, likesCount, commentsCount, avatarUrl),
        _buildInfoOverlay(doctorName, specialty, caption, avatarUrl),
      ],
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onLongPress: () => controller.setPlaybackSpeed(2.0),
          onLongPressEnd: (_) => controller.setPlaybackSpeed(1.0),
          child: Container(color: Colors.transparent),
        ),
        if (_showControls) _buildControlsOverlay(controller),
        if (controller.value.playbackSpeed > 1.0)
          _buildSpeedIndicator(controller.value.playbackSpeed),
        _buildProgressBar(controller),
      ],
    );
  }

  Widget _buildControlsOverlay(VideoPlayerController controller) {
    return Stack(
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlCircle(
                Icons.replay,
                "5s",
                () => _seekBackward(controller),
              ),
              _buildControlCircle(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                null,
                () => _togglePlayPause(controller),
                isLarge: true,
              ),
              _buildControlCircle(
                Icons.forward_10,
                "5s",
                () => _seekForward(controller),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlCircle(
    IconData icon,
    String? label,
    VoidCallback onTap, {
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 80 : 70,
        height: isLarge ? 80 : 70,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isLarge ? 45 : 28),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedIndicator(double speed) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fast_forward, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.playbackSpeed(speed.toString()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(VideoPlayerController controller) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, VideoPlayerValue value, child) => Text(
                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 50,
      left: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.pop(context, true),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    String reelId,
    bool isLiked,
    int likesCount,
    int commentsCount,
    String? avatarUrl,
  ) {
    return Positioned(
      right: 12,
      bottom: 120,
      child: Column(
        children: [
          ReelActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(likesCount),
            color: isLiked ? Colors.red : Colors.white,
            onTap: () => _toggleLike(reelId),
          ),
          const SizedBox(height: 25),
          ReelActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(commentsCount),
            color: Colors.white,
            onTap: () => _showComments(reelId),
          ),
          const SizedBox(height: 25),
          _buildAvatarCircle(avatarUrl, size: 50),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(String? avatarUrl, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: avatarUrl != null
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl == null
          ? Icon(Icons.person, color: Colors.white, size: size * 0.5)
          : null,
    );
  }

  Widget _buildInfoOverlay(
    String doctorName,
    String specialty,
    String caption,
    String? avatarUrl,
  ) {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 120,
      child: ReelInfoOverlay(
        doctorName: doctorName,
        specialty: specialty,
        caption: caption,
        avatarUrl: avatarUrl,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
