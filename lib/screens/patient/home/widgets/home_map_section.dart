import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:aroggyapath/widgets/osm_map_widget.dart';
import 'package:aroggyapath/screens/patient/home/full_map_screen.dart';
import 'package:aroggyapath/utils/colors.dart';

class HomeMapSection extends StatefulWidget {
  final bool isLoadingLocation;
  final LatLng currentPosition;
  final List<fm.Marker> markers;
  final List<fm.Polyline> polylines;
  final List<fm.Polyline> directionPolylines;
  final fm.MapController mapController;
  final VoidCallback onMapReady;
  final Function(LatLng) onLocationChanged;
  final VoidCallback onLocateMe;

  const HomeMapSection({
    super.key,
    required this.isLoadingLocation,
    required this.currentPosition,
    required this.markers,
    required this.polylines,
    required this.directionPolylines,
    required this.mapController,
    required this.onMapReady,
    required this.onLocationChanged,
    required this.onLocateMe,
  });

  @override
  State<HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<HomeMapSection> {
  bool _isPickerMode = false;

  void _zoomIn() {
    widget.mapController.move(
      widget.mapController.camera.center,
      widget.mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    widget.mapController.move(
      widget.mapController.camera.center,
      widget.mapController.camera.zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            widget.isLoadingLocation
                ? Container(
                    color: AppColors.primarySoft,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : OsmMapWidget(
                    initialCenter: widget.currentPosition,
                    initialZoom: 13,
                    markers: widget.markers,
                    polylines: [
                      ...widget.polylines,
                      ...widget.directionPolylines,
                    ],
                    mapController: widget.mapController,
                    onMapReady: widget.onMapReady,
                  ),

            if (_isPickerMode)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.accent,
                      size: 44,
                    ),
                  ),
                ),
              ),

            // Map Controls (Right Side)
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  _buildControlButton(
                    icon: Icons.add_rounded,
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _buildControlButton(
                    icon: Icons.remove_rounded,
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),

            // Locate Me (Top Left)
            Positioned(
              left: 12,
              top: 12,
              child: _buildControlButton(
                icon: Icons.my_location_rounded,
                onPressed: widget.onLocateMe,
              ),
            ),

            // Bottom Controls
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Row(
                children: [
                  _buildControlButton(
                    icon: _isPickerMode
                        ? Icons.close_rounded
                        : Icons.edit_location_alt_outlined,
                    onPressed: () {
                      setState(() => _isPickerMode = !_isPickerMode);
                    },
                    color: _isPickerMode ? AppColors.error : AppColors.primary,
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  if (_isPickerMode)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final center = widget.mapController.camera.center;
                          widget.onLocationChanged(center);
                          setState(() => _isPickerMode = false);
                        },
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullMapScreen(
                                currentPosition: widget.currentPosition,
                                markers: widget.markers,
                                polylines: widget.polylines,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.fullscreen_rounded,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Full Map',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color iconColor = AppColors.textPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
