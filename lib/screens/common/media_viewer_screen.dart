// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:gal/gal.dart';
// import 'package:video_player/video_player.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'dart:io';
// import 'package:aroggyapath/l10n/app_localizations.dart';

// class MediaViewerScreen extends StatefulWidget {
//   final List<String> urls;
//   final int initialIndex;
//   final bool isVideo;

//   const MediaViewerScreen({
//     super.key,
//     required this.urls,
//     this.initialIndex = 0,
//     this.isVideo = false,
//   });

//   @override
//   State<MediaViewerScreen> createState() => _MediaViewerScreenState();
// }

// class _MediaViewerScreenState extends State<MediaViewerScreen> {
//   late int _currentIndex;
//   late PageController _pageController;
//   VideoPlayerController? _videoController;
//   bool _isDownloading = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: widget.initialIndex);
//     if (widget.isVideo) {
//       _initializeVideo();
//     }
//   }

//   void _initializeVideo() {
//     _videoController =
//         VideoPlayerController.networkUrl(Uri.parse(widget.urls[_currentIndex]))
//           ..initialize().then((_) {
//             setState(() {});
//             _videoController?.play();
//           });
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _videoController?.dispose();
//     super.dispose();
//   }

//   Future<void> _downloadMedia() async {
//     if (_isDownloading) return;

//     setState(() {
//       _isDownloading = true;
//     });

//     try {
//       final url = widget.urls[_currentIndex];

//       // Request permissions if needed (gal handles some of this)
//       final hasAccess = await Gal.hasAccess();
//       if (!hasAccess) {
//         await Gal.requestAccess();
//       }

//       await Gal.putUrl(url);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Saved to gallery!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to save: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isDownloading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white, size: 30),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           if (_isDownloading)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.0),
//                 child: SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               ),
//             )
//           else
//             IconButton(
//               icon: const Icon(Icons.download, color: Colors.white, size: 30),
//               onPressed: _downloadMedia,
//             ),
//         ],
//       ),
//       extendBodyBehindAppBar: true,
//       body: Stack(
//         children: [
//           if (widget.isVideo)
//             Center(
//               child: _videoController?.value.isInitialized ?? false
//                   ? AspectRatio(
//                       aspectRatio: _videoController!.value.aspectRatio,
//                       child: VideoPlayer(_videoController!),
//                     )
//                   : const CircularProgressIndicator(color: Colors.white),
//             )
//           else
//             PhotoViewGallery.builder(
//               scrollPhysics: const BouncingScrollPhysics(),
//               builder: (BuildContext context, int index) {
//                 return PhotoViewGalleryPageOptions(
//                   imageProvider: CachedNetworkImageProvider(widget.urls[index]),
//                   initialScale: PhotoViewComputedScale.contained,
//                   minScale: PhotoViewComputedScale.contained * 0.8,
//                   maxScale: PhotoViewComputedScale.covered * 2,
//                   heroAttributes: PhotoViewHeroAttributes(
//                     tag: widget.urls[index],
//                   ),
//                 );
//               },
//               itemCount: widget.urls.length,
//               loadingBuilder: (context, event) => const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//               pageController: _pageController,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentIndex = index;
//                 });
//               },
//             ),

//           // Counter for multiple images
//           if (widget.urls.length > 1)
//             Positioned(
//               bottom: 40,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '${_currentIndex + 1} / ${widget.urls.length}',
//                     style: const TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
