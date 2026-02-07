import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'appointment_shared_widgets.dart';

class ConfirmedAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final AppointmentProvider provider;
  final Function(AppointmentModel) onShowDetails;
  final Function(String, AppointmentProvider) onCancel;
  final Function(AppointmentModel) onStartSession;

  const ConfirmedAppointmentCard({
    super.key,
    required this.appointment,
    required this.provider,
    required this.onShowDetails,
    required this.onCancel,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    appointment.patientImage != null &&
                        appointment.patientImage!.isNotEmpty
                    ? NetworkImage(appointment.patientImage!)
                    : const AssetImage('assets/images/doctor_booking.png')
                          as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (appointment.bookedFor != null &&
                        appointment.bookedFor!.type == 'dependent') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'For: ${appointment.bookedFor!.bookingLabel}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        smallIconText(
                          appointment.appointmentType?.toLowerCase() == "video"
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          appointment.appointmentType?.toLowerCase() == "video"
                              ? l10n.videoCall
                              : l10n.physical,
                        ),
                        smallIconText(
                          Icons.calendar_today_outlined,
                          appointment.formattedDate,
                        ),
                        smallIconText(
                          Icons.access_time,
                          appointment.appointmentTime,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => onShowDetails(appointment),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1664CD).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF1664CD),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'See Details',
                    style: TextStyle(
                      color: Color(0xFF1664CD),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: actionBtn(
                  l10n.cancel,
                  const Color(0xFFD93D57),
                  Colors.white,
                  () => onCancel(appointment.id, provider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: actionBtn(
              l10n.startSession,
              const Color(0xFF0B3267),
              Colors.white,
              () => onStartSession(appointment),
            ),
          ),
        ],
      ),
    );
  }
}
