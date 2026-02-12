import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/screens/patient/messages/patient_chat_screen.dart';
import 'package:aroggyapath/screens/patient/navigation/patient_main_navigation.dart';
import 'package:aroggyapath/services/api_service.dart';

import 'dart:async';
import 'package:aroggyapath/utils/colors.dart';

class PatientMessagesListScreen extends StatefulWidget {
  const PatientMessagesListScreen({super.key});

  @override
  State<PatientMessagesListScreen> createState() =>
      _PatientMessagesListScreenState();
}

class _PatientMessagesListScreenState extends State<PatientMessagesListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _currentUserId; // ✅ Restored
  final Set<String> _selectedConversationIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _currentUserId = ApiService.supabase.auth.currentUser?.id; // ✅ Init
    _loadCurrentUserId();
    _loadChats();
    _setupSupabaseListener();
  }

  StreamSubscription? _chatsSubscription;

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }

  // ✅ Setup Supabase listener for real-time updates
  void _setupSupabaseListener() {
    final supabase = ApiService.supabase;
    _chatsSubscription = supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .handleError((error) {
          debugPrint('❌ Stream error: $error');
        })
        .listen((List<Map<String, dynamic>> data) {
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
    if (!quiet) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await ApiService.getConversations();
      if (res['success'] == true && mounted) {
        final List chats = res['data'];
        final List<Map<String, dynamic>> formattedChats = [];

        // 1. Collect all participant IDs
        final Set<String> participantIds = {};
        for (var chat in chats) {
          final parts = chat['participants'];
          if (parts is List) {
            for (var p in parts) {
              if (p is String) participantIds.add(p);
            }
          }
        }

        // 2. Fetch profiles for all participants
        final Map<String, dynamic> profilesMap = {};
        if (participantIds.isNotEmpty) {
          final profilesRes = await ApiService.supabase
              .from('profiles')
              .select('id, full_name, avatar_url, role')
              .filter('id', 'in', '(${participantIds.join(',')})');

          for (var p in profilesRes) {
            profilesMap[p['id']] = p;
          }
        }

        for (var chat in chats) {
          final participants = chat['participants'] as List?;
          if (participants == null || participants.isEmpty) continue;

          // Find other participant ID
          String? otherUserId;
          for (var p in participants) {
            if (p is String && p != _currentUserId) {
              otherUserId = p;
              break;
            }
          }

          if (otherUserId == null) continue;

          final profile = profilesMap[otherUserId];
          final userName = profile?['full_name'] ?? 'Unknown User';
          final avatarUrl = profile?['avatar_url'];

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
        backgroundColor: AppColors.getBackground(context),
        appBar: AppBar(
          backgroundColor: AppColors.getSurface(context),
          elevation: 0,
          toolbarHeight: 80,
          leading: _isSelectionMode
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.getTextPrimary(context),
                  ),
                  onPressed: _cancelSelection,
                )
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.getTextPrimary(context),
                  ),
                  onPressed: _goBackToHome,
                ),
          title: Text(
            _isSelectionMode
                ? "${_selectedConversationIds.length} selected"
                : AppLocalizations.of(context)!.messagesLabel,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
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
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.getSurface(context),
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
}
