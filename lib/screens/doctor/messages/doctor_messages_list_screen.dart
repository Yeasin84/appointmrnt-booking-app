import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/screens/doctor/messages/doctor_chat_screen.dart';
import 'package:aroggyapath/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/services/api_service.dart';

import 'package:intl/intl.dart';
import 'dart:async';

class DoctorMessagesListScreen extends StatefulWidget {
  final String? initialDoctorId;

  const DoctorMessagesListScreen({super.key, this.initialDoctorId});

  @override
  State<DoctorMessagesListScreen> createState() =>
      _DoctorMessagesListScreenState();
}

class _DoctorMessagesListScreenState extends State<DoctorMessagesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allChats = [];
  bool isLoading = true;
  String? currentUserId;
  final Set<String> _selectedConversationIds = {}; // ✅ For multi-select delete
  bool _isSelectionMode = false; // ✅ Selection mode toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUserId();
    _loadChats();
    _setupSupabaseListener(); // ✅ Listen to Supabase messages

    if (widget.initialDoctorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createChatWithDoctor(widget.initialDoctorId!);
      });
    }
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

  Future<void> _loadChats({bool quiet = false}) async {
    if (!quiet) setState(() => isLoading = true);

    try {
      final result = await ApiService.getConversations();

      if (result['success'] == true) {
        final List<dynamic> chatsData = result['data'];
        List<Map<String, dynamic>> formattedChats = [];

        for (var chat in chatsData) {
          final List participants = chat['participants'] as List;
          final otherParticipant = participants.firstWhere(
            (p) => p['user_id'] != currentUserId,
            orElse: () => participants[0],
          );
          final otherUserId = otherParticipant['user_id'];

          // Resolve profile
          String userName = 'User';
          String? avatarUrl;
          String role = 'patient';

          final profileResult = await ApiService.getUserProfile(
            userId: otherUserId,
          );
          if (profileResult['success'] == true) {
            userName = profileResult['data']['full_name'] ?? 'User';
            avatarUrl = profileResult['data']['avatar_url'];
            role = profileResult['data']['role'] ?? 'patient';
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
                'role': role,
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
            allChats = formattedChats;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      if (mounted) setState(() => isLoading = false);
    }
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

  Future<void> _loadCurrentUserId() async {
    try {
      final result = await ApiService.getUserProfile();
      if (result['success'] == true) {
        setState(() {
          currentUserId = result['data']['id']?.toString();
        });
        _loadChats();
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  Future<void> _createChatWithDoctor(String doctorId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await ApiService.createOrGetChat(userId: doctorId);
      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final chatData = result['data'];
        final chatId = chatData['_id']?.toString();

        if (chatId != null) {
          final participants = chatData['participants'] as List;
          final otherUser = participants.firstWhere(
            (p) => p['_id'] != currentUserId,
            orElse: () => participants[0],
          );

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorChatDetailScreen(
                chatId: chatId,
                userName:
                    otherUser['fullName'] ??
                    AppLocalizations.of(context)!.doctorLabel,
                userAvatar: otherUser['avatar']?['url'],
                userRole: otherUser['role'] ?? 'doctor',
                otherUserId: otherUser['_id'],
              ),
            ),
          ).then((_) => _loadChats());

          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToDelete(e.toString()),
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get uniqueChats {
    return allChats;
  }

  List<Map<String, dynamic>> get doctorChats {
    return uniqueChats.where((chat) {
      final participants = chat['participants'] as List? ?? [];
      return participants.any(
        (p) => p['_id'] != currentUserId && p['role'] == 'doctor',
      );
    }).toList();
  }

  List<Map<String, dynamic>> get patientChats {
    return uniqueChats.where((chat) {
      final participants = chat['participants'] as List? ?? [];
      return participants.any(
        (p) => p['_id'] != currentUserId && p['role'] == 'patient',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorMainNavigation(),
                    ),
                    (route) => false,
                  );
                },
              ),
        title: Text(
          _isSelectionMode
              ? "${_selectedConversationIds.length} selected"
              : AppLocalizations.of(context)!.messagesLabel,
          style: const TextStyle(
            color: Color(0xFF1B2C49),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1664CD),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1664CD),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.allLabel),
            Tab(text: AppLocalizations.of(context)!.doctorsLabel),
            Tab(text: AppLocalizations.of(context)!.patientsLabel),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(uniqueChats),
                _buildChatList(doctorChats),
                _buildChatList(patientChats),
              ],
            ),
    );
  }

  Widget _buildChatList(List<Map<String, dynamic>> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMessagesYet,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return _buildChatCard(chats[index]);
        },
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final participants = chat['participants'] as List? ?? [];
    // ✅ Robust search for other participant to avoid TypeError
    Map<String, dynamic>? otherUser;
    for (var p in participants) {
      if (p is Map && p['_id'] != currentUserId) {
        otherUser = Map<String, dynamic>.from(p);
        break;
      }
    }

    if (otherUser == null && participants.isNotEmpty) {
      otherUser = Map<String, dynamic>.from(participants[0]);
    }

    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    final String userName =
        otherUser['fullName'] ?? AppLocalizations.of(context)!.unknown;
    final String? userAvatar = otherUser['avatar']?['url'];
    final String userRole = otherUser['role'] ?? 'user';
    final String lastMessageText =
        chat['lastMessage']?['content'] ??
        AppLocalizations.of(context)!.noMessagesYet;
    final int unreadCount = chat['unreadCount'] ?? 0;

    final String? lastMessageTime = chat['lastMessage']?['createdAt'];
    final String timeText = lastMessageTime != null
        ? _formatTime(DateTime.parse(lastMessageTime))
        : '';

    final String convId = chat['_id']?.toString() ?? '';
    final bool isSelected = _selectedConversationIds.contains(convId);

    return InkWell(
      onTap: _isSelectionMode
          ? () => _toggleSelection(convId)
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorChatDetailScreen(
                    chatId: chat['_id'],
                    userName: userName,
                    userAvatar: userAvatar,
                    userRole: userRole,
                    otherUserId: otherUser!['_id'],
                  ),
                ),
              ).then((_) => _loadChats());
            },
      onLongPress: () => _toggleSelection(convId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blue.shade300)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  userAvatar != null &&
                      userAvatar.isNotEmpty &&
                      userAvatar != 'file:///' &&
                      (userAvatar.startsWith('http://') ||
                          userAvatar.startsWith('https://'))
                  ? NetworkImage(userAvatar)
                  : const AssetImage('assets/images/doctor.png')
                        as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2C49),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageText,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? const Color(0xFF1B2C49)
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1664CD),
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
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
