import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/screens/doctor/messages/doctor_messages_list_screen.dart';

class DoctorInfoBottomSheet extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorInfoBottomSheet({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String doctorName = doctor['fullName'] ?? 'Doctor';
    final String? doctorImage = doctor['avatar']?['url'];
    final String doctorId = doctor['_id'] ?? '';
    final String specialty = doctor['specialty'] ?? 'General Physician';
    final String bio = doctor['bio'] ?? l10n.noBioAvailable;
    final int experienceYears = doctor['experienceYears'] ?? 0;
    final List degrees = doctor['degrees'] ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 50,
              backgroundImage: doctorImage != null
                  ? NetworkImage(doctorImage)
                  : const AssetImage('assets/images/doctor.png')
                        as ImageProvider,
            ),
            const SizedBox(height: 16),

            Text(
              doctorName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Specialty
            Text(
              specialty,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),

            if (experienceYears > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1664CD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.yearsExperience(experienceYears),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1664CD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            if (bio != l10n.noBioAvailable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bio,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),

            if (degrees.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: degrees.map<Widget>((degree) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1664CD).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      degree['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1664CD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorMessagesListScreen(initialDoctorId: doctorId),
                    ),
                  );
                },
                icon: const Icon(Icons.message_outlined),
                label: Text(
                  l10n.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664CD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
