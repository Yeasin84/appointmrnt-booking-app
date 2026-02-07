import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'appointment_shared_widgets.dart';

class CompletedAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const CompletedAppointmentCard({super.key, required this.appointment});

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
      child: Row(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.patientName ?? 'Patient',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    statusBadge(
                      l10n.completed,
                      const Color(0xFFF6FFED),
                      const Color(0xFF52C41A),
                    ),
                  ],
                ),
                if (appointment.bookedFor != null &&
                    appointment.bookedFor!.type == 'dependent') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 11,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'For: ${appointment.bookedFor!.bookingLabel}',
                          style: const TextStyle(
                            fontSize: 9,
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
                  spacing: 10,
                  runSpacing: 5,
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
    );
  }
}
