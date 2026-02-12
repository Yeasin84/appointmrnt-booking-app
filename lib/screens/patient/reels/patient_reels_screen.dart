import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/screens/patient/navigation/patient_main_navigation.dart';
import 'reels_viewer_screen.dart';
import 'widgets/reel_thumbnail.dart';
import 'package:aroggyapath/utils/colors.dart';

class PatientReelsScreen extends StatefulWidget {
  const PatientReelsScreen({super.key});

  @override
  State<PatientReelsScreen> createState() => _PatientReelsScreenState();
}

class _PatientReelsScreenState extends State<PatientReelsScreen> {
  List<Map<String, dynamic>> reelsList = [];
  bool isLoading = true;
  bool hasError = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReels();
    _scrollController.addListener(_onScroll);

    // Auto refresh every 30 seconds with silent update
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadReels();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMore) {
      _loadMoreReels();
    }
  }

  Future<void> _loadReels() async {
    if (reelsList.isEmpty) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      final response = await ApiService.getAllReels(page: 1, limit: 20);
      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList = items
              .map((item) => item as Map<String, dynamic>)
              .toList();
          currentPage = 1;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      if (reelsList.isEmpty) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReels() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.getAllReels(
        page: currentPage + 1,
        limit: 20,
      );
      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList.addAll(
            items.map((item) => item as Map<String, dynamic>).toList(),
          );
          currentPage++;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more reels: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientMainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: Text(
          l10n.reelsLabel,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReels,
        child: isLoading && reelsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? _buildErrorView(l10n)
            : reelsList.isEmpty
            ? Center(child: Text(l10n.noReelsAvailable))
            : _buildReelsGrid(),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.failedLoadReels),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _loadReels, child: Text(l10n.retryLabel)),
        ],
      ),
    );
  }

  Widget _buildReelsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: reelsList.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == reelsList.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return ReelThumbnail(
            reel: reelsList[index],
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReelsViewerScreen(
                    reelsList: reelsList,
                    initialIndex: index,
                  ),
                ),
              );
              if (result == true) _loadReels();
            },
          );
        },
      ),
    );
  }
}
