import 'package:flutter/material.dart';
import 'package:aroggyapath/services/socket_service.dart';
import 'package:aroggyapath/screens/common/calls/video_call_screen.dart';
import 'package:aroggyapath/screens/common/calls/audio_call_screen.dart';
import 'package:aroggyapath/services/api_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String chatId;
  final String callerName;
  final String? callerAvatar;
  final String callerId;
  final bool isVideoCall;

  const IncomingCallScreen({
    super.key,
    required this.chatId,
    required this.callerName,
    this.callerAvatar,
    required this.callerId,
    required this.isVideoCall,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupCallEndListener();
  }

  void _setupCallEndListener() {
    SocketService.instance.on('call:ended', (data) async {
      debugPrint('📞 Call ended event received: $data');
      if (data['chatId'] == widget.chatId && mounted) {
        // ✅ Log as missed call on receiver side
        try {
          await ApiService.sendMessage(
            chatId: widget.chatId,
            content: 'Missed ${widget.isVideoCall ? "video" : "audio"} call',
            type: 'call_log',
          );
        } catch (e) {
          debugPrint('⚠️ Failed to log missed call: $e');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Call was cancelled')));
            Navigator.pop(context);
          }
        });
      }
    });

    SocketService.instance.on('call:failed', (data) {
      debugPrint('❌ Call failed event received: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Call failed: ${data['message']}')),
            );
            Navigator.pop(context);
          }
        });
      }
    });
    // }
  }

  void _acceptCall() async {
    if (_isAccepting) {
      debugPrint('⚠️ Already accepting call');
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    debugPrint('✅ Accepting call...');
    debugPrint('💬 Chat ID: ${widget.chatId}');
    debugPrint('👤 Caller ID: ${widget.callerId}');
    debugPrint('📹 Is Video: ${widget.isVideoCall}');

    try {
      // ✅ Send accept event BEFORE navigating
      await SocketService.instance.emitToUser(widget.callerId, 'call:accept', {
        'chatId': widget.chatId,
        'fromUserId': widget
            .callerId, // Is this needed? 'fromUserId' usually refers to Caller, but here we are accepting.
        // Wait, 'call:accept' payload usually should invoke who ACCEPTED.
        // But backend might depend on existing payload structure.
        // 'fromUserId': widget.callerId seems wrong if it implies sender of this event.
        // The original code sent 'fromUserId': widget.callerId.
        // If 'callerId' is the OTHER person, then we are saying "Accept call from X".
        // I will keep payload same but use emitToUser to send to caller.
      });

      debugPrint('📤 Call accept event sent');

      // ✅ Small delay to ensure event is sent
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ Navigate to appropriate call screen
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isVideoCall
              ? VideoCallScreen(
                  chatId: widget.chatId,
                  userName: widget.callerName,
                  userAvatar: widget.callerAvatar,
                  otherUserId: widget.callerId,
                  isInitiator: false, // ✅ Receiver
                )
              : AudioCallScreen(
                  chatId: widget.chatId,
                  userName: widget.callerName,
                  userAvatar: widget.callerAvatar,
                  otherUserId: widget.callerId,
                  isInitiator: false, // ✅ Receiver
                ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept call: $e')));
      }
    }
  }

  void _rejectCall() async {
    debugPrint('❌ Rejecting call...');
    debugPrint('💬 Chat ID: ${widget.chatId}');
    debugPrint('👤 Caller ID: ${widget.callerId}');

    try {
      // ✅ Log as declined call
      try {
        await ApiService.sendMessage(
          chatId: widget.chatId,
          content: 'Declined ${widget.isVideoCall ? "video" : "audio"} call',
          type: 'call_log',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to log declined call: $e');
      }

      await SocketService.instance.emitToUser(widget.callerId, 'call:reject', {
        'chatId': widget.chatId,
      });

      debugPrint('📤 Call reject event sent');

      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2C49),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isVideoCall ? Icons.videocam : Icons.phone,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isVideoCall ? 'Video Call' : 'Audio Call',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage:
                          widget.callerAvatar != null &&
                              widget.callerAvatar!.isNotEmpty &&
                              widget.callerAvatar != 'file:///' &&
                              (widget.callerAvatar!.startsWith('http://') ||
                                  widget.callerAvatar!.startsWith('https://'))
                          ? NetworkImage(widget.callerAvatar!)
                          : const AssetImage('assets/images/doctor1.png')
                                as ImageProvider,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Incoming ${widget.isVideoCall ? 'Video' : 'Audio'} Call...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: _rejectCall,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Decline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: _isAccepting
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      widget.isVideoCall
                                          ? Icons.videocam
                                          : Icons.phone,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: _acceptCall,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SocketService.instance.off('call:ended');
    SocketService.instance.off('call:failed');
    super.dispose();
  }
}
