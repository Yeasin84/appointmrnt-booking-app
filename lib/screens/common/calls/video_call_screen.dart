import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/socket_service.dart';
import '../../../services/jitsi_meet_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String otherUserId;
  final bool isInitiator;

  const VideoCallScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.otherUserId,
    required this.isInitiator,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _setupSocketListeners();

    // Auto-join meeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinMeeting();
    });
  }

  void _setupSocketListeners() {
    SocketService.instance.on('call:ended', (data) {
      if (data['chatId'] == widget.chatId && mounted) {
        debugPrint('📴 Call ended by remote user');
        _onCallEnded();
      }
    });
  }

  Future<void> _joinMeeting() async {
    try {
      await JitsiMeetService.instance.joinMeeting(
        roomName: widget.chatId,
        userName: 'AroggyaPath User', // Ideally get current user name
        userAvatar: widget.userAvatar,
        isAudioOnly: false,
      );

      // After Jitsi activity closes, we might want to return
      if (mounted) {
        _onCallEnded();
      }
    } catch (e) {
      debugPrint('❌ Error launching Jitsi: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join call: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _onCallEnded() {
    if (_isDisposed) return;
    _isDisposed = true;

    // Notify server call ended
    SocketService.instance.emitToUser(widget.otherUserId, 'call:end', {
      'chatId': widget.chatId,
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WakelockPlus.disable();
    SocketService.instance.off('call:ended');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage(widget.userAvatar!)
                  : null,
              child: widget.userAvatar == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Connecting to video call...',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _onCallEnded,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
