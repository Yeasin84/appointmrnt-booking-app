import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'package:aroggyapath/utils/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aroggyapath/widgets/full_screen_image_viewer.dart';

class AppointmentDetailsSheet extends StatelessWidget {
  final AppointmentModel appointment;
  final ScrollController scrollController;

  const AppointmentDetailsSheet({
    super.key,
    required this.appointment,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF1664CD)),
                const SizedBox(width: 10),
                Text(
                  l10n.appointmentDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Patient Info
                _detailSection(
                  icon: Icons.person,
                  title: l10n.patientInformation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (appointment.bookedFor != null &&
                          appointment.bookedFor!.type == 'dependent')
                        Text(
                          l10n.bookedFor(appointment.bookedFor!.bookingLabel),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Symptoms Section
                _detailSection(
                  icon: Icons.medical_information_outlined,
                  title: l10n.symptoms,
                  child: Text(
                    appointment.symptoms != null &&
                            appointment.symptoms!.isNotEmpty
                        ? appointment.symptoms!
                        : l10n.noSymptoms,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          appointment.symptoms != null &&
                              appointment.symptoms!.isNotEmpty
                          ? Colors.black87
                          : Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Medical Documents Section
                _detailSection(
                  icon: Icons.attachment,
                  title: l10n.medicalDocuments,
                  child:
                      appointment.medicalDocuments != null &&
                          appointment.medicalDocuments!.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.docsUploaded(
                                appointment.medicalDocuments!.length,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...appointment.medicalDocuments!.map((doc) {
                              String displayName = doc.split('/').last;
                              if (displayName.contains('{public_id:')) {
                                final match = RegExp(
                                  r'([^/]+)\.(jpg|jpeg|png|pdf|gif)',
                                  caseSensitive: false,
                                ).firstMatch(doc);
                                if (match != null) {
                                  displayName = match.group(0)!;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1664CD,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: Color(0xFF1664CD),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Color(0xFF1664CD),
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _viewDocument(context, doc),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        )
                      : Text(
                          l10n.noDocsUploaded,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Payment Screenshot (if video call)
                _detailSection(
                  icon: Icons.payment,
                  title: l10n.paymentScreenshot,
                  child:
                      appointment.paymentScreenshot != null &&
                          appointment.paymentScreenshot!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _viewDocument(
                            context,
                            appointment.paymentScreenshot!,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F7FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF1664CD,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFF1664CD),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.viewPaymentScreenshot,
                                    style: const TextStyle(
                                      color: Color(0xFF1664CD),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.visibility,
                                  color: Color(0xFF1664CD),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Text(
                          l10n.noPaymentScreenshot,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1664CD)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1664CD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _viewDocument(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      String cleanUrl = url.trim();

      if (cleanUrl.contains('https://res.cloudinary.com')) {
        final cloudinaryMatch = RegExp(
          r'https://res\.cloudinary\.com[^\s,}]+',
        ).firstMatch(cleanUrl);
        if (cloudinaryMatch != null) {
          cleanUrl = cloudinaryMatch.group(0)!;
        }
      } else if (cleanUrl.contains('{public_id:')) {
        final match = RegExp(r'\{public_id:\s*([^}]+)\}').firstMatch(cleanUrl);
        if (match != null) {
          String publicId = match.group(1)!.trim();
          cleanUrl = '${ApiConfig.baseUrl}/uploads/$publicId';
        }
      } else if (!cleanUrl.startsWith('http')) {
        if (cleanUrl.startsWith('/')) {
          cleanUrl = '${ApiConfig.baseUrl}$cleanUrl';
        } else {
          cleanUrl = '${ApiConfig.baseUrl}/$cleanUrl';
        }
      }

      cleanUrl = Uri.decodeFull(cleanUrl);

      final isImage =
          cleanUrl.toLowerCase().endsWith('.jpg') ||
          cleanUrl.toLowerCase().endsWith('.jpeg') ||
          cleanUrl.toLowerCase().endsWith('.png') ||
          cleanUrl.toLowerCase().endsWith('.gif');

      Navigator.pop(context); // Close loading dialog

      if (isImage) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(imageUrls: [cleanUrl]),
          ),
        );
      } else {
        final uri = Uri.parse(cleanUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Document URL'),
            content: SelectableText(cleanUrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorOpeningDoc(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
