import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'appointment_shared_widgets.dart';

class PendingAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final AppointmentProvider provider;
  final Function(AppointmentModel) onShowDetails;
  final Function(String, AppointmentProvider) onAccept;
  final Function(String, AppointmentProvider) onCancel;

  const PendingAppointmentCard({
    super.key,
    required this.appointment,
    required this.provider,
    required this.onShowDetails,
    required this.onAccept,
    required this.onCancel,
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
                          l10n.pending,
                          const Color(0xFFFFF7E6),
                          const Color(0xFFFAAD14),
                        ),
                      ],
                    ),
                    if (appointment.bookedFor != null &&
                        appointment.bookedFor!.type == 'dependent') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
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
                              size: 13,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.forDependent(
                                appointment.bookedFor!.bookingLabel,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                smallIconText(
                  Icons.calendar_today_outlined,
                  appointment.formattedDate,
                ),
                smallIconText(Icons.access_time, appointment.appointmentTime),
                smallIconText(
                  appointment.appointmentType?.toLowerCase() == "video"
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  appointment.appointmentType?.toLowerCase() == "video"
                      ? l10n.videoCall
                      : l10n.physical,
                ),
              ],
            ),
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
              const SizedBox(width: 15),
              Expanded(
                child: actionBtn(
                  l10n.accept,
                  const Color(0xFFC6F2D6),
                  const Color(0xFF27AE60),
                  () => onAccept(appointment.id, provider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
