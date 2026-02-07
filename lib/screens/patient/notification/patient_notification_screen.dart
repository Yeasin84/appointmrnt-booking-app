import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroggyapath/providers/notification_provider.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'package:aroggyapath/models/notification_model.dart';
import '../../patient/home/upcoming_appointment_card.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationAsync = ref.watch(notificationListProvider);
    final apptProvider = legacy_provider.Provider.of<AppointmentProvider>(
      context,
    );

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.notificationTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2C49),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B2C49),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2C49)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF1664CD)),
            tooltip: l10n.markAllAsRead,
            onPressed: () {
              ref.read(notificationListProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationAsync.when(
        data: (notifications) {
          final unread = notifications.where((n) => !n.isRead).toList();
          final read = notifications.where((n) => n.isRead).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                apptProvider.fetchAppointments(),
                ref.refresh(notificationListProvider.future),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                // Upcoming Appointment Section
                _buildUpcomingSection(apptProvider),

                // New Section
                if (unread.isNotEmpty) ...[
                  _buildSectionTitle(l10n.newNotifications),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildDismissibleCard(unread[index]),
                        childCount: unread.length,
                      ),
                    ),
                  ),
                ],

                // Earlier Section
                if (read.isNotEmpty) ...[
                  _buildSectionTitle(l10n.earlierNotifications),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildDismissibleCard(read[index]),
                        childCount: read.length,
                      ),
                    ),
                  ),
                ],

                // Empty State
                if (notifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else if (unread.isEmpty && read.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  ),

                // Extra space at bottom
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2C49),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(AppointmentProvider aptProvider) {
    final upcoming = aptProvider.upcomingAppointments;
    if (upcoming.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.upcomingAppointment,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
            ),
            const SizedBox(height: 15),
            UpcomingAppointmentCard(appointment: upcoming.first),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noNotifications,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref
            .read(notificationListProvider.notifier)
            .deleteNotification(notification.id);
      },
      child: _buildNotificationCard(notification),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isRead = notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF8FAFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isRead
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            ref
                .read(notificationListProvider.notifier)
                .markAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isRead ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: const Color(0xFF1B2C49),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1664CD),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isRead
                              ? Colors.grey.shade600
                              : Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('confirmed') || t.contains('accepted')) {
      return Icons.event_available;
    }
    if (t.contains('reminder')) return Icons.alarm;
    if (t.contains('message')) return Icons.chat_bubble_outline;
    if (t.contains('cancel')) return Icons.event_busy;
    return Icons.notifications_none;
  }

  Color _getNotificationColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('confirmed') || t.contains('accepted')) return Colors.green;
    if (t.contains('reminder')) return Colors.orange;
    if (t.contains('message')) return Colors.blue;
    if (t.contains('cancel')) return Colors.amber;
    return Colors.grey;
  }
}
