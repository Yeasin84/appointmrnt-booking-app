import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';

class SearchSuggestionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final Function(Map<String, dynamic>) onSuggestionTap;

  const SearchSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  l10n.suggestions,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: suggestions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, indent: 60, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              final type = suggestion['type'];
              final text = suggestion['text'] ?? '';
              final subtext = suggestion['subtext'] ?? '';

              IconData icon;
              Color iconColor;
              Color bgColor;

              switch (type) {
                case 'doctor':
                  icon = Icons.person;
                  iconColor = const Color(0xFF1664CD);
                  bgColor = const Color(0xFF1664CD).withValues(alpha: 0.1);
                  break;
                case 'category':
                  icon = Icons.medical_services;
                  iconColor = const Color(0xFFFF9800);
                  bgColor = const Color(0xFFFF9800).withValues(alpha: 0.1);
                  break;
                case 'post':
                  icon = Icons.article;
                  iconColor = const Color(0xFF4CAF50);
                  bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.1);
                  break;
                default:
                  icon = Icons.search;
                  iconColor = Colors.grey;
                  bgColor = Colors.grey.withValues(alpha: 0.1);
              }

              return InkWell(
                onTap: () => onSuggestionTap(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B2C49),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtext.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtext,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
