import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ChatDateSeparator extends StatelessWidget {
  final String? timestamp;

  const ChatDateSeparator({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    if (timestamp == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    try {
      final date = DateTime.parse(timestamp!).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(date.year, date.month, date.day);

      String text;
      if (msgDate == today) {
        text = l10n.todayLabel;
      } else if (msgDate == yesterday) {
        text = l10n.yesterday;
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 5,
                ),
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
}
