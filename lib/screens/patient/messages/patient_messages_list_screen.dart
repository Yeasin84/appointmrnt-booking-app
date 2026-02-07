import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/screens/patient/messages/patient_chat_screen.dart';
import 'package:aroggyapath/screens/patient/navigation/patient_main_navigation.dart';
import 'package:aroggyapath/services/api_service.dart';

import 'dart:async';

class PatientMessagesListScreen extends StatefulWidget {
  const PatientMessagesListScreen({super.key});

  @override
  State<PatientMessagesListScreen> createState() =>
      _PatientMessagesListScreenState();
}

class _PatientMessagesListScreenState extends State<PatientMessagesListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _currentUserId;
  final Set<String> _selectedConversationIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadChats();
    _setupSupabaseListener();
  }

  // ✅ Setup Supabase listener for real-time updates
  void _setupSupabaseListener() {
    final supabase = ApiService.supabase;
    supabase.from('chats').stream(primaryKey: ['id']).listen((
      List<Map<String, dynamic>> data,
    ) {
      if (mounted) {
        _loadChats(quiet: true);
      }
    });
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final result = await ApiService.getUserProfile();
      if (result['success'] == true) {
        setState(() {
          _currentUserId = result['data']['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading current user ID: $e');
    }
  }

  Future<void> _loadChats({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);

    try {
      final result = await ApiService.getConversations();

      if (result['success'] == true) {
        final List<dynamic> chatsData = result['data'];
        List<Map<String, dynamic>> formattedChats = [];

        for (var chat in chatsData) {
          final List participants = chat['participants'] as List;
          final otherParticipant = participants.firstWhere(
            (p) => p['user_id'] != _currentUserId,
            orElse: () => participants[0],
          );
          final otherUserId = otherParticipant['user_id'];

          // Resolve profile
          String userName = 'Doctor';
          String? avatarUrl;

          final profileResult = await ApiService.getUserProfile(
            userId: otherUserId,
          );
          if (profileResult['success'] == true) {
            userName = profileResult['data']['full_name'] ?? 'Doctor';
            avatarUrl = profileResult['data']['avatar_url'];
          }

          final lastMessageList = chat['messages'] as List?;
          final lastMessage =
              (lastMessageList != null && lastMessageList.isNotEmpty)
              ? lastMessageList[0]
              : null;

          formattedChats.add({
            '_id': chat['id'].toString(),
            'participants': [
              {
                'role': 'doctor',
                '_id': otherUserId,
                'fullName': userName,
                'avatar': {'url': avatarUrl},
              },
            ],
            'lastMessage': {
              'content': lastMessage?['content'] ?? '',
              'createdAt': lastMessage?['created_at'] ?? chat['updated_at'],
            },
            'unreadCount': 0,
            'updatedAt': chat['updated_at'],
          });
        }

        if (mounted) {
          setState(() {
            _chats = formattedChats;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading chats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Multi-select Delete Helper
  void _toggleSelection(String convId) {
    setState(() {
      if (_selectedConversationIds.contains(convId)) {
        _selectedConversationIds.remove(convId);
        if (_selectedConversationIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversationIds.add(convId);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedConversationIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversationIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteChats),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteConversationsConfirm(_selectedConversationIds.length),
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
        final idsToDelete = _selectedConversationIds.toList();
        for (var id in idsToDelete) {
          await ApiService.deleteConversation(id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.conversationsDeleted),
            ),
          );
          _cancelSelection();
          _loadChats(); // Reload list
        }
      } catch (e) {
        debugPrint('❌ Failed to delete conversations: $e');
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

  void _goBackToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PatientMainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToHome();
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 246),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: _cancelSelection,
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _goBackToHome,
                ),
          title: Text(
            _isSelectionMode
                ? "${_selectedConversationIds.length} selected"
                : AppLocalizations.of(context)!.messagesLabel,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _deleteSelectedConversations,
                  ),
                  const SizedBox(width: 10),
                ]
              : null,
        ),
        body: RefreshIndicator(
          onRefresh: _loadChats,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
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
                        AppLocalizations.of(context)!.noConversationsYet,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadChats,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retryLabel),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    return _buildChatItem(_chats[index]);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final participants = chat['participants'] as List? ?? [];

    // ✅ Robust search for doctor participant to avoid TypeError
    Map<String, dynamic>? doctor;
    for (var p in participants) {
      if (p is Map && p['role'] == 'doctor') {
        doctor = Map<String, dynamic>.from(p);
        break;
      }
    }

    if (doctor == null) {
      return const SizedBox.shrink();
    }

    final String doctorName = doctor['fullName']?.toString() ?? 'Doctor';
    final String? doctorAvatar = doctor['avatar']?['url']?.toString();
    final String doctorId = doctor['_id']?.toString() ?? '';

    final lastMessage = chat['lastMessage'];
    final String messageText = lastMessage != null
        ? (lastMessage['content']?.toString() ??
              AppLocalizations.of(context)!.startConversation)
        : AppLocalizations.of(context)!.startConversation;

    // ✅ Get unread count
    final int unreadCount = chat['unreadCount'] ?? 0;

    final DateTime? updatedAt = chat['updatedAt'] != null
        ? DateTime.tryParse(chat['updatedAt'].toString())
        : null;
    final String timeText = updatedAt != null ? _formatTime(updatedAt) : '';

    final String convId = chat['_id']?.toString() ?? '';
    final bool isSelected = _selectedConversationIds.contains(convId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleSelection(convId)
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: chat['_id'].toString(),
                      doctorName: doctorName,
                      doctorAvatar: doctorAvatar,
                      doctorId: doctorId,
                    ),
                  ),
                ).then((_) {
                  _loadChats();
                });
              },
        onLongPress: () => _toggleSelection(convId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.blue.shade300)
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    doctorAvatar != null &&
                        doctorAvatar.isNotEmpty &&
                        doctorAvatar != 'file:///' &&
                        (doctorAvatar.startsWith('http://') ||
                            doctorAvatar.startsWith('https://'))
                    ? Image.network(
                        doctorAvatar,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              "assets/images/doctor1.png",
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        "assets/images/doctor1.png",
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Dr.',
                            style: TextStyle(
                              color: Color(0xFF1E61D4),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ✅ Added unread count display
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messageText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? const Color(0xFF1B2C49)
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // ✅ Unread badge
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
    } else {
      return AppLocalizations.of(context)!.justNow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
