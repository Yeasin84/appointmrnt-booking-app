import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'package:aroggyapath/screens/patient/home/upcoming_appointment_card.dart';
import 'package:aroggyapath/utils/colors.dart';

class HomeUpcomingAppointment extends StatelessWidget {
  const HomeUpcomingAppointment({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AppointmentProvider>(
      builder: (context, aptProvider, child) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final upcoming =
            aptProvider.upcomingAppointments.where((a) {
                final appointmentDay = DateTime(
                  a.appointmentDate.year,
                  a.appointmentDate.month,
                  a.appointmentDate.day,
                );
                return appointmentDay.isAtSameMomentAs(today) ||
                    appointmentDay.isAfter(today);
              }).toList()
              ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        if (upcoming.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.upcomingAppointment,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 15),
              UpcomingAppointmentCard(appointment: upcoming.first),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }
}
