import 'package:flutter/material.dart';
import 'package:aroggyapath/services/socket_service.dart';
import 'package:aroggyapath/screens/common/calls/video_call_screen.dart';
import 'package:aroggyapath/screens/common/calls/audio_call_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  static CallManager get instance => _instance;

  CallManager._internal();

  BuildContext? _context;
  bool _isListening = false;

  void initialize(BuildContext context) {
    _context = context;

    if (_isListening) {
      debugPrint('⚠️ CallManager already listening - reinitializing');
      _cleanup();
    }

    _setupCallListeners();
    _isListening = true;

    debugPrint('');
    debugPrint('╔═══════════════════════════════════════════╗');
    debugPrint('║     📞 CALL MANAGER INITIALIZED           ║');
    debugPrint('╚═══════════════════════════════════════════╝');
    debugPrint('✅ Context: ${_context != null ? "Available" : "NULL"}');
    debugPrint(
      '✅ Socket: ${SocketService.instance.isConnected ? "Connected" : "Disconnected"}',
    );
    debugPrint('✅ Listening for incoming calls');
    debugPrint('');
  }

  void _setupCallListeners() {
    // Use instance directly as it wraps logic
    // final socket = SocketService.instance.socket; // REMOVED

    SocketService.instance.off('call:incoming');
    SocketService.instance.off('call:accepted');
    SocketService.instance.off('call:rejected');

    SocketService.instance.on('call:incoming', (data) {
      debugPrint('');
      debugPrint(
        '╔═══════════════════════════════════════════════════════════╗',
      );
      debugPrint(
        '║              📞 INCOMING CALL RECEIVED                    ║',
      );
      debugPrint(
        '╚═══════════════════════════════════════════════════════════╝',
      );
      debugPrint('   • Raw data: $data');
      debugPrint('   • Data type: ${data.runtimeType}');

      Map<String, dynamic> callData;
      if (data is Map<String, dynamic>) {
        callData = data;
      } else if (data is Map) {
        callData = Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ Invalid data format: ${data.runtimeType}');
        return;
      }

      debugPrint('   • From: ${callData['fromUserId']}');
      debugPrint('   • Chat: ${callData['chatId']}');
      debugPrint('   • Type: ${callData['isVideo'] ? "VIDEO 📹" : "AUDIO 📞"}');
      debugPrint('   • Context: ${_context != null ? "Available" : "NULL"}');
      debugPrint('   • Mounted: ${_context?.mounted}');

      // Check availability before proceeding
      final available = _isDoctorAvailableForCalls();
      debugPrint('   • Doctor Available: ${available ? "YES ✅" : "NO 🚫"}');
      debugPrint('');

      if (_context != null && _context!.mounted) {
        _handleIncomingCall(callData);
      } else {
        debugPrint('❌ Context not available or not mounted');
      }
    });

    SocketService.instance.on('call:accepted', (data) {
      debugPrint('✅ Call accepted by other user');
    });

    SocketService.instance.on('call:rejected', (data) {
      debugPrint('❌ Call rejected by other user');
      _showSnackbar('Call rejected');
    });

    debugPrint('👂 Listening: call:incoming, call:accepted, call:rejected');
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (_context == null || !_context!.mounted) {
      debugPrint('⚠️ Context not available');
      return;
    }

    final fromUserId =
        data['fromUserId']?.toString() ?? data['callerId']?.toString();
    final chatId = data['chatId']?.toString();
    final isVideo = data['isVideo'] == true;
    final callerName = data['callerName']?.toString() ?? 'Unknown User';
    final callerAvatar = data['callerAvatar']?.toString();

    debugPrint('📋 Extracted:');
    debugPrint('   • fromUserId: $fromUserId');
    debugPrint('   • chatId: $chatId');
    debugPrint('   • isVideo: $isVideo');
    debugPrint('   • callerName: $callerName');

    if (fromUserId == null ||
        fromUserId.isEmpty ||
        chatId == null ||
        chatId.isEmpty) {
      debugPrint('❌ Missing required fields');
      return;
    }

    // Check if doctor is available for calls
    if (!_isDoctorAvailableForCalls()) {
      debugPrint('🚫 Doctor not available for calls - Auto rejecting');
      _rejectCallAutomatically(data);
      return;
    }

    debugPrint('📱 Doctor available - Showing incoming call dialog');

    try {
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => IncomingCallDialog(
          fromUserId: fromUserId,
          chatId: chatId,
          isVideo: isVideo,
          callerName: callerName,
          callerAvatar: callerAvatar,
        ),
      );
      debugPrint('✅ Dialog shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing dialog: $e');
    }
  }

  /// Check if current user (doctor) is available for calls
  bool _isDoctorAvailableForCalls() {
    if (_context == null || !_context!.mounted) {
      debugPrint('⚠️ Context not available for availability check');
      return false;
    }

    try {
      final userProvider = Provider.of<UserProvider>(_context!, listen: false);
      final user = userProvider.user;

      if (user == null) {
        debugPrint('⚠️ No user found in provider');
        return false;
      }

      // Check if user is a doctor and their call availability
      final isDoctor = user.role == 'doctor';
      final isAvailableForCalls = user.isVideoCallAvailable;

      debugPrint('📋 Doctor Availability Check:');
      debugPrint('   • Role: ${user.role}');
      debugPrint('   • Is Doctor: $isDoctor');
      debugPrint('   • Call Available: $isAvailableForCalls');

      // Only apply availability check for doctors
      // Patients should always be able to receive calls
      return !isDoctor || isAvailableForCalls;
    } catch (e) {
      debugPrint('❌ Error checking doctor availability: $e');
      return false;
    }
  }

  /// Auto-reject call when doctor is unavailable
  Future<void> _rejectCallAutomatically(Map<String, dynamic> callData) async {
    final fromUserId =
        callData['fromUserId']?.toString() ?? callData['callerId']?.toString();
    final chatId = callData['chatId']?.toString();
    final isVideo = callData['isVideo'] == true;
    final callerName = callData['callerName']?.toString() ?? 'Unknown User';

    debugPrint('');
    debugPrint('╔═══════════════════════════════════════════════════════════╗');
    debugPrint('║              🚫 AUTO-REJECTING CALL                    ║');
    debugPrint('╚═══════════════════════════════════════════════════════════╝');
    debugPrint(
      '   • Reason: Doctor is not available for ${isVideo ? "video" : "audio"} calls',
    );
    debugPrint('   • From: $callerName ($fromUserId)');
    debugPrint('   • Chat: $chatId');

    if (fromUserId != null && chatId != null) {
      try {
        // Send reject event with reason
        await SocketService.instance.emitToUser(fromUserId, 'call:reject', {
          'chatId': chatId,
          'reason': 'Doctor is not available for calls',
          'isAutoRejected': true,
        });

        // Send call end event
        await SocketService.instance.emitToUser(fromUserId, 'call:end', {
          'chatId': chatId,
          'reason': 'Doctor is not available for calls',
          'isAutoRejected': true,
        });

        debugPrint('✅ Auto-reject events sent to caller');
        debugPrint('');
      } catch (e) {
        debugPrint('❌ Error sending auto-reject: $e');
      }
    }
  }

  void _showSnackbar(String message) {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _cleanup() {
    SocketService.instance.off('call:incoming');
    SocketService.instance.off('call:accepted');
    SocketService.instance.off('call:rejected');
    _isListening = false;
  }

  void dispose() {
    _cleanup();
    _context = null;
    debugPrint('🧹 CallManager disposed');
  }
}

class IncomingCallDialog extends StatefulWidget {
  final String fromUserId;
  final String chatId;
  final bool isVideo;
  final String callerName;
  final String? callerAvatar;

  const IncomingCallDialog({
    super.key,
    required this.fromUserId,
    required this.chatId,
    required this.isVideo,
    required this.callerName,
    this.callerAvatar,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    debugPrint('🎬 IncomingCallDialog initialized');
    debugPrint('   • From: ${widget.fromUserId}');
    debugPrint('   • Chat: ${widget.chatId}');
    debugPrint('   • Type: ${widget.isVideo ? "VIDEO" : "AUDIO"}');

    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && !_isProcessing) {
        debugPrint('⏱️ Call timeout - Auto rejecting');
        _rejectCall();
      }
    });

    _setupCallEndListener();
  }

  void _setupCallEndListener() {
    SocketService.instance.on('call:end', (data) {
      // Broadcast payload is nested: {event: '...', payload: {...}}
      final payload = data is Map ? (data['payload'] ?? data) : data;
      final endChatId = payload is Map ? payload['chatId']?.toString() : null;
      if (endChatId == widget.chatId && mounted && !_isProcessing) {
        debugPrint('📞 Call ended by caller');
        Navigator.of(context).pop();
      }
    });
  } // _setupCallEndListener

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_isProcessing) {
          _rejectCall();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1664CD), Color(0xFF0D4DA1)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isVideo ? Icons.videocam : Icons.phone,
                  color: Colors.white,
                  size: 48,
                ),
              ),

              const SizedBox(height: 24),

              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage:
                    widget.callerAvatar != null &&
                        widget.callerAvatar!.isNotEmpty &&
                        widget.callerAvatar != 'file:///' &&
                        (widget.callerAvatar!.startsWith('http://') ||
                            widget.callerAvatar!.startsWith('https://'))
                    ? NetworkImage(widget.callerAvatar!)
                    : null,
                child:
                    widget.callerAvatar == null ||
                        widget.callerAvatar!.isEmpty ||
                        widget.callerAvatar == 'file:///' ||
                        (!widget.callerAvatar!.startsWith('http://') &&
                            !widget.callerAvatar!.startsWith('https://'))
                    ? Text(
                        widget.callerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                widget.callerName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              Text(
                'Incoming ${widget.isVideo ? "Video" : "Audio"} Call',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: Colors.red,
                    onPressed: _isProcessing ? null : _rejectCall,
                  ),

                  _buildActionButton(
                    icon: widget.isVideo ? Icons.videocam : Icons.phone,
                    label: _isProcessing ? 'Connecting...' : 'Accept',
                    color: Colors.green,
                    onPressed: _isProcessing ? null : _acceptCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isDisabled ? color.withValues(alpha: 0.5) : color,
          shape: const CircleBorder(),
          elevation: isDisabled ? 0 : 4,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isProcessing && label == 'Connecting...'
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDisabled
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _acceptCall() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    debugPrint('');
    debugPrint('✅ ACCEPTING CALL');
    debugPrint('   • From: ${widget.fromUserId}');
    debugPrint('   • Chat: ${widget.chatId}');

    try {
      await SocketService.instance.emitToUser(
        widget.fromUserId,
        'call:accept',
        {'chatId': widget.chatId, 'isVideo': widget.isVideo},
      );

      debugPrint('   ✅ Accept event sent');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isVideo
              ? VideoCallScreen(
                  chatId: widget.chatId,
                  userName: widget.callerName,
                  userAvatar: widget.callerAvatar,
                  otherUserId: widget.fromUserId,
                  isInitiator: false,
                )
              : AudioCallScreen(
                  chatId: widget.chatId,
                  userName: widget.callerName,
                  userAvatar: widget.callerAvatar,
                  otherUserId: widget.fromUserId,
                  isInitiator: false,
                ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectCall() {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    debugPrint('❌ REJECTING CALL');

    try {
      SocketService.instance.emitToUser(widget.fromUserId, 'call:reject', {
        'chatId': widget.chatId,
      });

      SocketService.instance.emitToUser(widget.fromUserId, 'call:end', {
        'chatId': widget.chatId,
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    SocketService.instance.off('call:end');
    super.dispose();
  }
}
