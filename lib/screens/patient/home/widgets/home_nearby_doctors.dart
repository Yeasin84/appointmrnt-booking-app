import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/providers/doctor_provider.dart';
import 'package:aroggyapath/screens/patient/home/see_all_doctors_screen.dart';
import 'package:aroggyapath/services/location_service.dart';
import 'package:aroggyapath/models/doctor_model.dart';
import 'custom_doctor_card.dart';
import 'package:aroggyapath/utils/colors.dart';

class HomeNearbyDoctors extends StatelessWidget {
  final LatLng currentPosition;
  final LocationService locationService;

  const HomeNearbyDoctors({
    super.key,
    required this.currentPosition,
    required this.locationService,
  });

  String _calculateDistance(BuildContext context, Doctor doctor) {
    final l10n = AppLocalizations.of(context)!;
    if (doctor.latitude != null && doctor.longitude != null) {
      try {
        final latLngDoctor = LatLng(doctor.latitude!, doctor.longitude!);
        double distanceKm = locationService.calculateDistanceInKm(
          currentPosition,
          latLngDoctor,
        );

        if (distanceKm < 1) {
          return '${(distanceKm * 1000).round()} m';
        } else {
          return '${distanceKm.toStringAsFixed(1)} km';
        }
      } catch (e) {
        return l10n.notAvailable;
      }
    }
    return doctor.distance;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.nearbyDoctors,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SeeAllDoctorsScreen(),
                  ),
                ),
                child: Text(
                  l10n.seeAll,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<DoctorProvider>(
          builder: (context, doctorProvider, child) {
            if (doctorProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (doctorProvider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error: ${doctorProvider.error}',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              );
            }

            final nearbyDoctors = List<Doctor>.from(
              doctorProvider.nearbyDoctors,
            );

            if (nearbyDoctors.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(l10n.noDoctorsFound),
                ),
              );
            }

            // Sort by distance
            nearbyDoctors.sort((a, b) {
              if (a.latitude == null || a.longitude == null) return 1;
              if (b.latitude == null || b.longitude == null) return -1;

              final distA = locationService.calculateDistanceInKm(
                currentPosition,
                LatLng(a.latitude!, a.longitude!),
              );
              final distB = locationService.calculateDistanceInKm(
                currentPosition,
                LatLng(b.latitude!, b.longitude!),
              );

              return distA.compareTo(distB);
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nearbyDoctors.length,
              itemBuilder: (context, index) {
                final doctor = nearbyDoctors[index];
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: CustomDoctorCard(
                    doctor: doctor,
                    distanceText: _calculateDistance(context, doctor),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
