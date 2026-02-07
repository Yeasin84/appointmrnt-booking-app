import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = const Color(0xFF0B3267);
    final accentColor = const Color(0xFF1664CD);
    final bgColor = const Color(0xFFF8FAFF);

    final faqs = [
      {'question': l10n.faq1Question, 'answer': l10n.faq1Answer},
      {'question': l10n.faq2Question, 'answer': l10n.faq2Answer},
      {'question': l10n.faq3Question, 'answer': l10n.faq3Answer},
      {'question': l10n.faq4Question, 'answer': l10n.faq4Answer},
      {'question': l10n.faq5Question, 'answer': l10n.faq5Answer},
      {'question': l10n.faq6Question, 'answer': l10n.faq6Answer},
      {'question': l10n.faq7Question, 'answer': l10n.faq7Answer},
      {'question': l10n.faq8Question, 'answer': l10n.faq8Answer},
      {'question': l10n.faq9Question, 'answer': l10n.faq9Answer},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.helpSupport,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.faqTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            ...faqs.map(
              (faq) => _buildFaqItem(
                faq['question']!,
                faq['answer']!,
                accentColor,
                primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              l10n.stillNeedHelp,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: l10n.emailUs,
              subtitle: 'mydoctoralgerie@gmail.com',
              color: accentColor,
              onTap: () =>
                  _launchEmail('mydoctoralgerie@gmail.com', l10n.emailSubject),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: l10n.callUs,
              subtitle: '0558585400',
              color: Colors.green,
              onTap: () => _launchPhone('0558585400'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    String question,
    String answer,
    Color accentColor,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          iconColor: accentColor,
          collapsedIconColor: Colors.grey,
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email, String subject) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject',
    );
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri params = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }
}
