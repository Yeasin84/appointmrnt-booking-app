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

class DoctorChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String userRole;
  final String? otherUserId;

  const DoctorChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.userRole,
    this.otherUserId,
  });

  @override
  State<DoctorChatDetailScreen> createState() => _DoctorChatDetailScreenState();
}

class _DoctorChatDetailScreenState extends State<DoctorChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  List<File> _selectedFiles = [];
  String? _currentUserId;
  String? _currentUserRole;
  String? _currentUserAvatar;
  String? _currentUserName;
  String? _resolvedOtherUserId;
  String? _otherUserRole;
  String? _actualUserAvatar;
  String? _actualUserName;
  bool _isAutoScrollEnabled = true;
  final Set<String> _selectedMessageIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _resolvedOtherUserId = widget.otherUserId;
    _otherUserRole = widget.userRole;
    _actualUserAvatar = widget.userAvatar;
    _actualUserName = widget.userName;
    _loadCurrentUserProfile().then((_) {
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

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] == true) {
        setState(() {
          _currentUserId = profileResult['data']['id']?.toString();
          _currentUserRole = profileResult['data']['role']?.toString();
          _currentUserAvatar = profileResult['data']['avatar_url']?.toString();
          _currentUserName = profileResult['data']['full_name']?.toString();
        });
        debugPrint('✅ Current user profile loaded:');
        debugPrint('   ID: $_currentUserId');
        debugPrint('   Role: $_currentUserRole');
        debugPrint('   Avatar: $_currentUserAvatar');
        debugPrint('   Name: $_currentUserName');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getChatMessages(chatId: widget.chatId);

      if (result['success'] == true && mounted) {
        setState(() {
          _messages = result['data'];
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSupabaseListener() {
    ApiService.supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .listen((data) {
          if (mounted) {
            setState(() {
              _messages = data;
            });
            _scrollToBottom();
          }
        });
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
        // Efficiently delete messages in parallel
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
      '📤 [Doctor] Attempting to send message. Content length: ${content.length}',
    );

    if (content.isEmpty && _selectedFiles.isEmpty) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final otherId = _resolvedOtherUserId ?? widget.otherUserId;
      if (otherId == null) throw Exception('Recipient ID missing');

      debugPrint('✉️ [Doctor] Sending to PatientID: $otherId');

      final result = await ApiService.sendMessage(
        chatId: widget.chatId,
        content: content,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      );

      if (result['success'] == true && mounted) {
        _controller.clear();
        setState(() {
          _selectedFiles = [];
          _isAutoScrollEnabled = true;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ [Doctor] Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSendMessage),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
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

  void _initiateCall({required bool isVideo}) async {
    final targetUserId = _resolvedOtherUserId ?? widget.otherUserId;

    if (targetUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotStartCallNoId),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      debugPrint(
        '${isVideo ? "📹" : "🎤"} Starting ${isVideo ? "video" : "audio"} call...',
      );
      debugPrint('👤 Current user: $_currentUserId');
      debugPrint('👤 Other user: $targetUserId');
      debugPrint('💬 Chat ID: ${widget.chatId}');

      // ✅ Use API instead of direct socket emission
      final socketService = SocketService.instance;
      if (!socketService.isConnected) {
        debugPrint('⚠️ Socket not connected, attempting to connect...');
        if (_currentUserId != null) {
          await socketService.connect(_currentUserId!);
          // Wait a bit for connection to stabilize
          await Future.delayed(const Duration(seconds: 1));
        }

        if (!socketService.isConnected) {
          throw Exception('Socket connection failed');
        }
      }

      debugPrint('✅ Socket connected, initiating call via API...');

      // ✅ Use API instead of direct socket emission
      final result = await ApiService.initiateCall(
        chatId: widget.chatId,
        receiverId: targetUserId,
        isVideo: isVideo,
      );

      if (result['success'] == true) {
        debugPrint('📤 Call initiated successfully');

        if (mounted) {
          final String stableChatId =
              result['data']?['chatId']?.toString() ?? widget.chatId;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isVideo
                  ? VideoCallScreen(
                      chatId: stableChatId,
                      userName: widget.userName,
                      userAvatar: _actualUserAvatar ?? widget.userAvatar,
                      otherUserId: targetUserId,
                      isInitiator: true,
                    )
                  : AudioCallScreen(
                      chatId: stableChatId,
                      userName: widget.userName,
                      userAvatar: _actualUserAvatar ?? widget.userAvatar,
                      otherUserId: targetUserId,
                      isInitiator: true,
                    ),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to initiate call');
      }
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToStartCall(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                  size: 24,
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
                          imageUrl: _actualUserAvatar,
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
                          _actualUserName ?? widget.userName,
                          style: const TextStyle(
                            color: Color(0xFF1B2C49),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _otherUserRole == 'doctor'
                              ? l10n.doctorLabel
                              : l10n.patientLabel,
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
                    size: 24,
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
                        const SizedBox(height: 8),
                        Text(
                          l10n.startConversationWith(widget.userName),
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
                      vertical: 10,
                    ),
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) {
                      final currentDate =
                          _messages[index]['createdAt'] as String;
                      final nextDate = (index + 1 < _messages.length)
                          ? _messages[index + 1]['createdAt'] as String
                          : null;

                      if (nextDate != null &&
                          !_isSameDay(currentDate, nextDate)) {
                        return ChatDateSeparator(timestamp: nextDate);
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
    final String msgId = message['id']?.toString() ?? '';

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

    return MessageBubble(
      messageId: msgId,
      content: message['content']?.toString() ?? '',
      isMe: isMe,
      senderAvatar: message['profiles']?['avatar_url']?.toString(),
      currentUserAvatar: _currentUserAvatar,
      fileUrls: List<String>.from(message['file_urls'] ?? []),
      formattedTime: _formatTime(message['created_at']),
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
