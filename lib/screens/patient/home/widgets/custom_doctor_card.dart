import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/models/doctor_model.dart';
import 'package:aroggyapath/screens/patient/doctor/doctor_detail_screen.dart';
import 'package:aroggyapath/screens/patient/doctor/book_appointment_screen.dart';
import 'package:aroggyapath/widgets/custom_image.dart';
import 'package:aroggyapath/utils/colors.dart';

class CustomDoctorCard extends StatelessWidget {
  final Doctor doctor;
  final String distanceText;

  const CustomDoctorCard({
    super.key,
    required this.doctor,
    required this.distanceText,
  });

  bool _isDoctorAvailable() {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return false;
    }

    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  String _getVisitingHours(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return l10n.noScheduleSet;
    }

    List<String> activeDays = [];
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        String dayShort = schedule.day.length >= 3
            ? schedule.day.substring(0, 3)
            : schedule.day;
        activeDays.add(dayShort);
      }
    }

    if (activeDays.isEmpty) {
      return l10n.noScheduleSet;
    }

    if (activeDays.length == 1) {
      return activeDays[0];
    } else if (activeDays.length <= 3) {
      return activeDays.join(', ');
    } else {
      return '${activeDays.first}-${activeDays.last}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isAvailable = _isDoctorAvailable();
    final bool hasVideoCall = doctor.isVideoCallAvailable;
    final String visitingHours = _getVisitingHours(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.getTextPrimary(context).withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primarySoft, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomImage(
                    imageUrl: doctor.image,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    placeholderAsset: 'assets/images/doctor_booking.png',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            doctor.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isAvailable ? l10n.available : l10n.noSchedule,
                            style: TextStyle(
                              color: isAvailable
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (hasVideoCall)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.videoConsultation,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          size: 14,
                          color: AppColors.textPlaceholder,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            visitingHours,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFFFB300),
                        ),
                        Text(
                          ' ${doctor.rating.toStringAsFixed(1)} ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.textPlaceholder,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distanceText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookAppointmentScreen(doctor: doctor),
                          ),
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: AppColors.textPlaceholder
                        .withValues(alpha: 0.12),
                  ),
                  child: Text(
                    isAvailable ? l10n.bookNow : l10n.notAvailable,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(doctor: doctor),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.info_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
