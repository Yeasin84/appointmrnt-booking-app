import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/screens/doctor/profile/doctor_profile_screen.dart';
import 'package:aroggyapath/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/screens/auth/sign_in_screen.dart';
import 'package:aroggyapath/models/post_model.dart';
import 'package:aroggyapath/providers/user_provider.dart';
import 'package:aroggyapath/utils/colors.dart';
import 'dart:async';

import 'widgets/doctor_home_header.dart';
// import 'widgets/doctor_home_search.dart';
import 'widgets/search_suggestions_section.dart';
import 'widgets/create_post_box.dart';
import 'widgets/doctor_info_bottom_sheet.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  List<PostModel> _posts = [];
  List<PostModel> _searchResults = [];
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore &&
        !_isSearching) {
      _loadMorePosts();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchSuggestions.clear();
        _searchResults.clear();
        _currentSearchQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearchLoading = true;
      _currentSearchQuery = query;
    });

    try {
      final result = await ApiService.get(
        '/api/v1/posts/search?q=${Uri.encodeComponent(query)}',
        requiresAuth: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final posts = result['data']?['posts'] ?? [];
        final suggestions = result['data']?['suggestions'] ?? [];

        setState(() {
          _searchResults = posts
              .map<PostModel>((p) => PostModel.fromJson(p))
              .toList();
          _searchSuggestions = List<Map<String, dynamic>>.from(suggestions);
          _isSearchLoading = false;
        });
      } else {
        setState(() {
          _searchResults.clear();
          _searchSuggestions.clear();
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      if (!mounted) return;
      setState(() {
        _isSearchLoading = false;
        _searchResults.clear();
        _searchSuggestions.clear();
      });

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.searchFailed(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initializeScreen() async {
    if (!ApiService.isLoggedIn) {
      _handleTokenMissing();
      return;
    }
    await _loadUserData();
    await _loadPosts();
  }

  void _handleTokenMissing() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = false;
      _errorMessage = l10n.sessionExpiredMessageDoc;
    });

    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.sessionExpiredTitle),
          content: Text(l10n.sessionExpiredMessageDoc),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SignInScreen(userType: 'doctor'),
                  ),
                  (route) => false,
                );
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadUserData() async {
    try {
      await legacy_provider.Provider.of<UserProvider>(
        context,
        listen: false,
      ).fetchUserProfile();
    } catch (e) {
      debugPrint('⚠️ Error loading user data: $e');
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getAllPosts(
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final List<dynamic> postsData = result['data'] ?? [];

        setState(() {
          if (_currentPage == 1) {
            _posts = postsData
                .map<PostModel>(
                  (p) => PostModel.fromJson(Map<String, dynamic>.from(p)),
                )
                .toList();
          } else {
            _posts.addAll(
              postsData
                  .map<PostModel>(
                    (p) => PostModel.fromJson(Map<String, dynamic>.from(p)),
                  )
                  .toList(),
            );
          }

          _hasMore = postsData.length == 20;
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (result['requiresLogin'] == true) {
        _handleTokenMissing();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? l10n.failedLoadPosts;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.connectionError;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    _currentPage++;

    try {
      final result = await ApiService.getAllPosts(
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final List<dynamic> postsData = result['data'] ?? [];

        setState(() {
          _posts.addAll(
            postsData
                .map<PostModel>(
                  (p) => PostModel.fromJson(Map<String, dynamic>.from(p)),
                )
                .toList(),
          );
          _hasMore = postsData.length == 20;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _currentPage--; // Revert page on failure
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentPage--;
      });
    }
  }

  Future<void> _refreshData() async {
    await legacy_provider.Provider.of<UserProvider>(
      context,
      listen: false,
    ).fetchUserProfile();
    _currentPage = 1;
    await _loadPosts();
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.pushNamed(context, '/doctor/create-post');

    if (result == true) {
      if (!mounted) return;
      await _refreshData();
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
    ).then((_) {
      if (!mounted) return;
      legacy_provider.Provider.of<UserProvider>(
        context,
        listen: false,
      ).fetchUserProfile();
    });
  }

  void _showDoctorInfo(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorInfoBottomSheet(doctor: doctor),
    );
  }

  void _onSuggestionTap(Map<String, dynamic> suggestion) {
    final type = suggestion['type'];
    final data = suggestion['data'];

    FocusScope.of(context).unfocus();

    if (type == 'doctor') {
      _showDoctorInfo(data);
    } else if (type == 'category') {
      final specialtyName = data['speciality_name'];
      _searchController.text = specialtyName;
      _performSearch(specialtyName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: DoctorHomeHeader(onProfileTap: _navigateToProfile),
            ),

            if (_isSearching &&
                _searchSuggestions.isNotEmpty &&
                _searchController.text.isNotEmpty)
              SliverToBoxAdapter(
                child: SearchSuggestionsSection(
                  suggestions: _searchSuggestions,
                  onSuggestionTap: _onSuggestionTap,
                ),
              ),

            // Always show CreatePostBox if not searching
            if (!_isSearching)
              SliverToBoxAdapter(
                child: CreatePostBox(
                  onNavigateToCreatePost: _navigateToCreatePost,
                ),
              ),

            _buildSliverContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverContent() {
    final l10n = AppLocalizations.of(context)!;

    if (_isSearching) {
      if (_isSearchLoading && _searchController.text.isNotEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildLoadingState(l10n.searching),
        );
      }

      if (_searchController.text.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildSearchEmptyState(
            icon: Icons.search,
            title: l10n.searchAnything,
            subtitle: l10n.findEverything,
          ),
        );
      }

      if (_searchResults.isEmpty && !_isSearchLoading) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildSearchEmptyState(
            icon: Icons.search_off,
            title: l10n.noResultsFound,
            subtitle: l10n.tryDifferentKeywords,
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.article, size: 20, color: Color(0xFF1664CD)),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.posts} (${_searchResults.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2C49),
                    ),
                  ),
                ],
              ),
            );
          }
          return PostCard(
            post: _searchResults[index - 1],
            onPostUpdated: () {
              _performSearch(_currentSearchQuery);
            },
            onAuthorTap: (authorData) {
              _showDoctorInfo(authorData);
            },
          );
        }, childCount: _searchResults.length + 1),
      );
    }

    if (_isLoading && _posts.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(l10n),
      );
    }

    if (_posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildNoPostsState(l10n),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == _posts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return PostCard(
          post: _posts[index],
          onPostUpdated: _refreshData,
          onAuthorTap: (authorData) {
            _showDoctorInfo(authorData);
          },
        );
      }, childCount: _posts.length + (_hasMore ? 1 : 0)),
    );
  }

  Widget _buildLoadingState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1664CD).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: const Color(0xFF1664CD)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2C49),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1664CD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPostsState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.post_add, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.noPostsYet,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
