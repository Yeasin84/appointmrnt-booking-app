import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/widgets/custom_image.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/services/socket_service.dart';
import 'package:aroggyapath/screens/common/calls/video_call_screen.dart';
import 'package:aroggyapath/screens/common/calls/audio_call_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:aroggyapath/widgets/full_screen_image_viewer.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String doctorName;
  final String? doctorAvatar;
  final String? doctorId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.doctorName,
    this.doctorAvatar,
    this.doctorId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  List<File> _selectedFiles = [];
  String? _currentUserId;
  String? _currentUserAvatar;
  String? _currentUserName;
  String? _otherUserId;
  String? _actualDoctorAvatar; // ✅ Real avatar from API
  String? _actualDoctorName;

  bool _isAutoScrollEnabled = true;
  final Set<String> _selectedMessageIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _actualDoctorAvatar = widget.doctorAvatar;
    _actualDoctorName = widget.doctorName;
    _loadCurrentUserProfile().then((_) {
      _loadMessages();
      _setupRealtimeListeners();
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        _isAutoScrollEnabled = (maxScroll - currentScroll) < 100;
      }
    });
  }

  final supabase = ApiService.supabase;

  void _setupRealtimeListeners() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            final List<dynamic> formatted = data
                .map((m) => _convertSupabaseMessage(m))
                .toList();
            setState(() {
              _messages = formatted;
            });
            _scrollToBottom();
          }
        });
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['_id']?.toString();
          _currentUserAvatar = profileResult['data']['avatar']?['url']
              ?.toString();
          _currentUserName = profileResult['data']['fullName']?.toString();
        });
        debugPrint('✅ Current user profile loaded');
        debugPrint('   ID: $_currentUserId');
        debugPrint('   Name: $_currentUserName');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = _messages.isEmpty);

    try {
      final response = await ApiService.getChatMessages(chatId: widget.chatId);
      if (response['success'] == true && mounted) {
        final List<dynamic> data = response['data'];
        final List<dynamic> formatted = data
            .map((m) => _convertSupabaseMessage(m))
            .toList();
        setState(() {
          _messages = formatted;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _convertSupabaseMessage(Map<String, dynamic> message) {
    final bool isMe = message['sender_id'] == _currentUserId;
    final List<dynamic> fileUrls = message['file_urls'] ?? [];

    return {
      '_id': message['id'],
      'content': message['content'],
      'type': message['type'],
      'sender': {
        '_id': message['sender_id'],
        'fullName': isMe ? _currentUserName : _actualDoctorName,
        'avatar': {'url': isMe ? _currentUserAvatar : _actualDoctorAvatar},
      },
      'fileUrl': fileUrls
          .map(
            (url) => {
              'url': url,
              'type': message['type'] == 'image' ? 'image' : 'file',
            },
          )
          .toList(),
      'createdAt': message['created_at'],
    };
  }

  // ✅ Multi-select Delete Helper
  void _toggleSelection(String msgId) {
    setState(() {
      if (_selectedMessageIds.contains(msgId)) {
        _selectedMessageIds.remove(msgId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(msgId);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedMessages() async {
    // TODO: Implement Supabase message deletion
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _isAutoScrollEnabled) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();

    if (content.isEmpty && _selectedFiles.isEmpty) return;
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final response = await ApiService.sendMessage(
        chatId: widget.chatId,
        content: content,
        type: _selectedFiles.isNotEmpty ? 'image' : 'text',
        files: _selectedFiles,
      );

      if (response['success'] == true && mounted) {
        _controller.clear();
        setState(() {
          _selectedFiles = [];
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSendMessage),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedFiles.add(File(image.path)));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // ✅ Unified method to initiate Call (Audio or Video)
  void _initiateCall({required bool isVideo}) async {
    if (_otherUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotStartCallNoId),
          ),
        );
      }
      return;
    }

    if (!SocketService.instance.isConnected) {
      if (_currentUserId != null) {
        try {
          await SocketService.instance.connect(_currentUserId!);
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('❌ Socket reconnection failed: $e');
        }
      }

      if (!SocketService.instance.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.failedToStartCall('Connection failed'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // ✅ Use API Service to initiate call (matches Doctor implementation)
    // This ensures backend sets up the call properly and sends caller info
    Map<String, dynamic> result;
    try {
      result = await ApiService.initiateCall(
        chatId: widget.chatId,
        receiverId: _otherUserId!,
        isVideo: isVideo,
      );

      if (result['success'] != true) {
        final message = result['message'] as String? ?? '';
        final errorCode = result['code'] as String?;

        if (mounted) {
          // Enhanced error handling for doctor unavailable
          if (errorCode == 'DOCTOR_UNAVAILABLE' ||
              message.toLowerCase().contains('not available')) {
            _showDoctorUnavailableDialog(isVideo);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToStartCall(message),
                ),
              ),
            );
          }
        }
        return;
      }
    } catch (e) {
      debugPrint('❌ Call initiation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToStartCall(e.toString()),
            ),
          ),
        );
      }
      return;
    }

    // Call triggered successfully via API, navigation handles locally
    debugPrint('📞 Call initiated via API successfully');

    final String stableChatId =
        result['data']?['chatId']?.toString() ?? widget.chatId;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isVideo
              ? VideoCallScreen(
                  chatId: stableChatId,
                  userName: widget.doctorName,
                  userAvatar: _actualDoctorAvatar ?? widget.doctorAvatar,
                  otherUserId: _otherUserId!,
                  isInitiator: true,
                )
              : AudioCallScreen(
                  chatId: stableChatId,
                  userName: widget.doctorName,
                  userAvatar: _actualDoctorAvatar ?? widget.doctorAvatar,
                  otherUserId: _otherUserId!,
                  isInitiator: true,
                ),
        ),
      );
    }
  }

  /// Show doctor unavailable dialog
  void _showDoctorUnavailableDialog(bool isVideo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.phone_missed, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Doctor Unavailable',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2C49),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.doctorUnavailableForCallsDescription(
                isVideo ? 'video' : 'audio',
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: const TextStyle(color: Color(0xFF1664CD))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Send Message',
              style: const TextStyle(color: Color(0xFF1664CD)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: _cancelSelection,
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 26,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: _isSelectionMode
            ? Text(
                '${_selectedMessageIds.length} selected',
                style: const TextStyle(color: Colors.black, fontSize: 18),
              )
            : Row(
                children: [
                  Stack(
                    children: [
                      ClipOval(
                        child: CustomImage(
                          imageUrl: _actualDoctorAvatar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholderAsset: 'assets/images/doctor1.png',
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actualDoctorName ?? widget.doctorName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppLocalizations.of(context)!.doctorLabel,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteSelectedMessages,
                ),
                const SizedBox(width: 10),
              ]
            : [
                // Audio Call icon
                IconButton(
                  icon: const Icon(
                    Icons.phone_outlined,
                    color: Colors.black,
                    size: 26,
                  ),
                  onPressed: () => _initiateCall(isVideo: false),
                ),
                // Video icon
                IconButton(
                  icon: const Icon(
                    Icons.videocam_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () => _initiateCall(isVideo: true),
                ),
                const SizedBox(width: 10),
                // IconButton(
                //   icon: const Icon(
                //     Icons.phone_outlined,
                //     color: Colors.black,
                //     size: 26,
                //   ),
                //   onPressed: () => _initiateCall(isVideo: false),
                // ),
                // // Video icon
                // IconButton(
                //   icon: const Icon(
                //     Icons.videocam_outlined,
                //     color: Colors.black,
                //     size: 28,
                //   ),
                //   onPressed: () => _initiateCall(isVideo: true),
                // ),
                // const SizedBox(width: 10),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noMessagesYet,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.startConversationWith(widget.doctorName),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) {
                      final currentMsgDate = _messages[index]['createdAt'];
                      final nextMsgDate = (index + 1 < _messages.length)
                          ? _messages[index + 1]['createdAt']
                          : null;

                      if (nextMsgDate != null &&
                          !_isSameDay(currentMsgDate, nextMsgDate)) {
                        return _buildDateSeparator(nextMsgDate);
                      }
                      return const SizedBox.shrink();
                    },
                    itemBuilder: (context, index) {
                      // Show initial date separator for the first message
                      if (index == 0) {
                        return Column(
                          children: [
                            _buildDateSeparator(_messages[0]['createdAt']),
                            _buildBubble(_messages[index]),
                          ],
                        );
                      }
                      return _buildBubble(_messages[index]);
                    },
                  ),
          ),

          if (_selectedFiles.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedFiles[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF6C5CE7),
                      size: 26,
                    ),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeAMessage,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> message) {
    // Check for Call Log
    if (message['type'] == 'call_log') {
      return _buildCallLogBubble(message);
    }

    final String msgId = message['_id']?.toString() ?? '';
    final bool isSelected = _selectedMessageIds.contains(msgId);
    final String text = message['content']?.toString() ?? '';
    final String senderId = message['sender']?['_id']?.toString() ?? '';
    final String? senderAvatar = message['sender']?['avatar']?['url']
        ?.toString();
    final bool isMe = _currentUserId != null && senderId == _currentUserId;
    final List<dynamic> attachments = message['fileUrl'] ?? [];

    return InkWell(
      onTap: _isSelectionMode ? () => _toggleSelection(msgId) : null,
      onLongPress: () => _toggleSelection(msgId),
      child: Container(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
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
                if (!isMe) const SizedBox(width: 8),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
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
                        color: Colors.black.withOpacity(isMe ? 0.1 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attachments.isNotEmpty)
                        ...attachments.map((att) {
                          final String? url = att['url']?.toString();
                          if (url != null && url.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FullScreenImageViewer(imageUrls: [url]),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      (url.startsWith('https://') ||
                                          url.startsWith('http://'))
                                      ? CustomImage(
                                          imageUrl: url,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(url),
                                          width: 200,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      if (text.isNotEmpty)
                        Text(
                          text,
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
                if (isMe) const SizedBox(width: 8),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ClipOval(
                      child: CustomImage(
                        imageUrl: _currentUserAvatar,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        placeholderAsset: 'assets/images/profile.png',
                      ),
                    ),
                  ),
              ],
            ),
            if (message['createdAt'] != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 54,
                  right: isMe ? 54 : 0,
                  top: 6,
                ),
                child: Text(
                  _formatTime(message['createdAt']),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLogBubble(Map<String, dynamic> message) {
    final String msgId = message['_id']?.toString() ?? '';
    final bool isSelected = _selectedMessageIds.contains(msgId);
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
      onTap: _isSelectionMode ? () => _toggleSelection(msgId) : null,
      onLongPress: () => _toggleSelection(msgId),
      child: Container(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
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

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  bool _isSameDay(String? ts1, String? ts2) {
    if (ts1 == null || ts2 == null) return false;
    try {
      final d1 = DateTime.parse(ts1).toLocal();
      final d2 = DateTime.parse(ts2).toLocal();
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (e) {
      return false;
    }
  }

  Widget _buildDateSeparator(String? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(date.year, date.month, date.day);

      String text;
      if (msgDate == today) {
        text = 'Today';
      } else if (msgDate == yesterday) {
        text = 'Yesterday';
      } else {
        text = DateFormat('MMMM d, y').format(date);
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
