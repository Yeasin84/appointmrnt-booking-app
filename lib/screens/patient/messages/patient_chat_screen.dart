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
import 'package:aroggyapath/widgets/full_screen_image_viewer.dart';
import 'package:aroggyapath/widgets/chat/chat_date_separator.dart';
import 'package:aroggyapath/widgets/chat/call_log_bubble.dart';
import 'package:aroggyapath/widgets/chat/message_bubble.dart';
import 'package:aroggyapath/widgets/chat/chat_input.dart';

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
  Map<String, dynamic> _participantProfiles =
      {}; // ✅ For looking up avatars in Realtime
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
      _loadChatParticipants();
      _loadMessages();
      _setupSupabaseListener();
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

  StreamSubscription? _messagesSubscription;

  void _setupSupabaseListener() {
    _messagesSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .order('created_at', ascending: true)
        .handleError((error) {
          debugPrint('❌ Message stream error: $error');
          if (mounted) setState(() => _isLoading = false);
        })
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              _messages = data;
              _isLoading = false;
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
          _currentUserId = profileResult['data']['id']?.toString();
          _currentUserAvatar = profileResult['data']['avatar_url']?.toString();
          _currentUserName = profileResult['data']['full_name']?.toString();
        });
        debugPrint('✅ Current user profile loaded');
        debugPrint('   ID: $_currentUserId');
        debugPrint('   Name: $_currentUserName');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
  }

  Future<void> _loadChatParticipants() async {
    try {
      final res = await ApiService.getChatParticipants(chatId: widget.chatId);
      if (res['success'] == true) {
        setState(() {
          _participantProfiles = res['data'];

          // Resolve otherUserId from profiles (the one who isn't current user)
          if (_currentUserId != null) {
            final otherId = _participantProfiles.keys.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => '',
            );
            if (otherId.isNotEmpty) {
              _otherUserId = otherId;
              debugPrint('✅ Resolved otherUserId from cache: $_otherUserId');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading chat participants: $e');
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
    final String senderId = message['sender_id']?.toString() ?? '';
    final bool isMe = senderId == _currentUserId;
    final List<dynamic> fileUrls = message['file_urls'] ?? [];
    final String contentType =
        message['content_type'] ?? message['type'] ?? 'text';

    return {
      'id': message['id'],
      '_id': message['id'],
      'content': message['content'],
      'type': contentType,
      'sender_id': senderId,
      'sender': {
        '_id': senderId,
        'fullName': isMe ? _currentUserName : _actualDoctorName,
        'avatar': {'url': isMe ? _currentUserAvatar : _actualDoctorAvatar},
      },
      'file_urls': fileUrls,
      'fileUrl': fileUrls
          .map(
            (url) => {
              'url': url,
              'type': contentType == 'image' ? 'image' : 'file',
            },
          )
          .toList(),
      'created_at': message['created_at'],
      'createdAt': message['created_at'] ?? message['createdAt'],
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
    if (_selectedMessageIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMessages),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteMessagesConfirm(_selectedMessageIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.deleteLabel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final idsToDelete = _selectedMessageIds.toList();
        await Future.wait(
          idsToDelete.map(
            (id) => ApiService.supabase.from('messages').delete().eq('id', id),
          ),
        );

        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => idsToDelete.contains(m['_id']));
            _cancelSelection();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.messagesDeleted),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to delete messages: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToDelete(e.toString()),
              ),
            ),
          );
        }
      }
    }
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
    debugPrint(
      '📩 [Patient] _sendMessage triggered. Content: "$content", Files: ${_selectedFiles.length}',
    );

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
          _isAutoScrollEnabled = true;
        });
        _scrollToBottom();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  AppLocalizations.of(context)!.failedToSendMessage,
            ),
            backgroundColor: Colors.red,
          ),
        );
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
    // Attempt rescue if _otherUserId is null but cache is full
    if (_otherUserId == null &&
        _participantProfiles.isNotEmpty &&
        _currentUserId != null) {
      _otherUserId = _participantProfiles.keys.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => '',
      );
      if (_otherUserId!.isEmpty) _otherUserId = null;
    }

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
    final l10n = AppLocalizations.of(context)!;
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
                          l10n.doctorLabel,
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
                IconButton(
                  icon: const Icon(
                    Icons.phone_outlined,
                    color: Colors.black,
                    size: 26,
                  ),
                  onPressed: () => _initiateCall(isVideo: false),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.videocam_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () => _initiateCall(isVideo: true),
                ),
                const SizedBox(width: 10),
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
                          l10n.noMessagesYet,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.startConversationWith(widget.doctorName),
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
                      final currentMsgDate =
                          _messages[index]['created_at'] ??
                          _messages[index]['createdAt'];
                      final nextMsgDate = (index + 1 < _messages.length)
                          ? (_messages[index + 1]['created_at'] ??
                                _messages[index + 1]['createdAt'])
                          : null;

                      if (nextMsgDate != null &&
                          !_isSameDay(currentMsgDate, nextMsgDate)) {
                        return ChatDateSeparator(timestamp: nextMsgDate);
                      }
                      return const SizedBox.shrink();
                    },
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            ChatDateSeparator(
                              timestamp: _messages[0]['createdAt'],
                            ),
                            _buildItem(index),
                          ],
                        );
                      }
                      return _buildItem(index);
                    },
                  ),
          ),
          ChatInput(
            controller: _controller,
            selectedFiles: _selectedFiles,
            isSending: _isSending,
            onPickImage: _pickImage,
            onRemoveFile: _removeFile,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final message = _messages[index];
    final String msgId = (message['id'] ?? message['_id'])?.toString() ?? '';

    if (message['type'] == 'call_log') {
      return CallLogBubble(
        message: message,
        isSelected: _selectedMessageIds.contains(msgId),
        onTap: _isSelectionMode ? () => _toggleSelection(msgId) : null,
        onLongPress: () => _toggleSelection(msgId),
      );
    }

    final String senderId = message['sender_id']?.toString() ?? '';
    final bool isMe = _currentUserId != null && senderId == _currentUserId;

    // Look up profile from cache if not joined (joins don't work in Realtime stream)
    final profile = _participantProfiles[senderId];
    final List<dynamic> attachments = message['file_urls'] ?? [];

    return MessageBubble(
      messageId: msgId,
      content: message['content']?.toString() ?? '',
      isMe: isMe,
      senderAvatar: profile?['avatar_url']?.toString(),
      currentUserAvatar: _currentUserAvatar,
      fileUrls: attachments
          .map((att) => att.toString())
          .where((url) => url.isNotEmpty)
          .toList(),
      formattedTime: _formatTime(message['created_at'] ?? message['createdAt']),
      isSelected: _selectedMessageIds.contains(msgId),
      onTap: _isSelectionMode ? () => _toggleSelection(msgId) : null,
      onLongPress: () => _toggleSelection(msgId),
      onFileTap: (url) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenImageViewer(imageUrls: [url]),
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
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

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
