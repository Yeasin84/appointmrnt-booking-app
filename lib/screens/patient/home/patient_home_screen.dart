import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:aroggyapath/providers/doctor_provider.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'package:aroggyapath/providers/user_provider.dart';
import 'package:aroggyapath/services/location_service.dart';
import 'package:aroggyapath/services/directions_service.dart';
import 'package:aroggyapath/utils/marker_factory.dart';
import 'widgets/home_header.dart';
import 'widgets/home_map_section.dart';
import 'widgets/home_upcoming_appointment.dart';
import 'widgets/home_nearby_doctors.dart';
import 'package:aroggyapath/utils/colors.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final LocationService _locationService = LocationService();
  final MarkerFactory _markerFactory = MarkerFactory();
  final DirectionsService _directionsService = DirectionsService();
  final fm.MapController _mapController = fm.MapController();

  LatLng _currentPosition = const LatLng(23.8103, 90.4125);
  bool _isLoadingLocation = true;
  List<fm.Marker> _markers = [];
  List<fm.Polyline> _polylines = [];
  List<fm.Polyline> _directionPolylines = [];
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    try {
      await legacy_provider.Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).fetchAppointments();
      await _getCurrentLocation();

      if (mounted) {
        double? lat = _currentPosition.latitude != 0
            ? _currentPosition.latitude
            : null;
        double? lng = _currentPosition.longitude != 0
            ? _currentPosition.longitude
            : null;
        await legacy_provider.Provider.of<DoctorProvider>(
          context,
          listen: false,
        ).fetchNearbyDoctors(lat: lat, lng: lng);
      }
    } catch (e) {
      debugPrint('Error initializing screen: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // ✅ Update Provider with location so "See All" screen can use it for distance
        context.read<DoctorProvider>().updateLocation(_currentPosition);

        if (_isMapReady) _mapController.move(_currentPosition, 14);
        _addDoctorMarkers();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _addDoctorMarkers() async {
    try {
      final doctors = context.read<DoctorProvider>().nearbyDoctors;
      List<fm.Marker> markers = [
        _markerFactory.createUserMarker(_currentPosition),
      ];
      List<fm.Polyline> polylines = [];

      for (var doctor in doctors) {
        if (doctor.latitude != null && doctor.longitude != null) {
          final doctorLoc = LatLng(doctor.latitude!, doctor.longitude!);
          double distance = _locationService.calculateDistanceInKm(
            _currentPosition,
            doctorLoc,
          );

          markers.add(
            await _markerFactory.createCustomDoctorMarker(
              doctor: doctor,
              distanceKm: distance,
              onTap: () => _showDoctorRoute(doctor.id, doctorLoc, distance),
            ),
          );

          polylines.add(
            fm.Polyline(
              points: [_currentPosition, doctorLoc],
              color: _getRouteColor(distance).withValues(alpha: 0.5),
              strokeWidth: 4,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = markers;
          _polylines = polylines;
        });
      }
    } catch (e) {
      debugPrint('❌ Error adding doctor markers: $e');
    }
  }

  Color _getRouteColor(double distanceKm) {
    if (distanceKm <= 5) return AppColors.success;
    if (distanceKm <= 10) return AppColors.primary;
    if (distanceKm <= 15) return AppColors.warning;
    return AppColors.error;
  }

  void _showDoctorRoute(
    String doctorId,
    LatLng doctorLocation,
    double distance,
  ) async {
    final directions = await _directionsService.getDirections(
      origin: _currentPosition,
      destination: doctorLocation,
    );
    if (directions != null && mounted) {
      setState(() {
        _directionPolylines = [
          fm.Polyline(
            points: directions['polylinePoints'],
            color: AppColors.primary,
            strokeWidth: 6,
          ),
        ];
      });
      _mapController.fitCamera(
        fm.CameraFit.bounds(
          bounds: fm.LatLngBounds(_currentPosition, doctorLocation),
          padding: const EdgeInsets.all(100),
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      legacy_provider.Provider.of<DoctorProvider>(
        context,
        listen: false,
      ).fetchNearbyDoctors(),
      legacy_provider.Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).fetchAppointments(),
    ]);
    await _addDoctorMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = legacy_provider.Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(userProvider: userProvider),
                HomeMapSection(
                  isLoadingLocation: _isLoadingLocation,
                  currentPosition: _currentPosition,
                  markers: _markers,
                  polylines: _polylines,
                  directionPolylines: _directionPolylines,
                  mapController: _mapController,
                  onMapReady: () {
                    setState(() => _isMapReady = true);
                    _mapController.move(_currentPosition, 14);
                  },
                  onLocationChanged: (newLocation) {
                    setState(() {
                      _currentPosition = newLocation;
                      _directionPolylines.clear();
                    });
                    _addDoctorMarkers();
                    // Refetch doctors from API for new location
                    legacy_provider.Provider.of<DoctorProvider>(
                      context,
                      listen: false,
                    ).fetchNearbyDoctors(
                      lat: newLocation.latitude,
                      lng: newLocation.longitude,
                    );
                  },
                  onLocateMe: _getCurrentLocation,
                ),
                const SizedBox(height: 25),
                const HomeUpcomingAppointment(),
                HomeNearbyDoctors(
                  currentPosition: _currentPosition,
                  locationService: _locationService,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
