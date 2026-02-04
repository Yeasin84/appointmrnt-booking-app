import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../../../widgets/osm_map_widget.dart';

class FullMapScreen extends StatefulWidget {
  final LatLng currentPosition;
  final List<fm.Marker> markers;
  final List<fm.Polyline> polylines;

  const FullMapScreen({
    super.key,
    required this.currentPosition,
    required this.markers,
    required this.polylines,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final fm.MapController _mapController = fm.MapController();
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen Map
            OsmMapWidget(
              initialCenter: widget.currentPosition,
              initialZoom: 13,
              markers: widget.markers,
              polylines: widget.polylines,
              mapController: _mapController,
              onMapReady: () {
                setState(() => _isMapReady = true);
              },
            ),

            // Close Button (Top Left)
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF0D47A1),
                    size: 24,
                  ),
                ),
              ),
            ),

            // Map Legend (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2C49),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.green, '< 5 km'),
                    _buildLegendItem(Colors.lightGreen, '5-10 km'),
                    _buildLegendItem(Colors.orange, '10-15 km'),
                    _buildLegendItem(Colors.red, '> 15 km'),
                  ],
                ),
              ),
            ),

            // Zoom Controls (Bottom Left)
            Positioned(
              bottom: 80,
              left: 16,
              child: Column(
                children: [
                  // Zoom In
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF0D47A1),
                        size: 28,
                      ),
                      onPressed: () {
                        if (_isMapReady) {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Zoom Out
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: Color(0xFF0D47A1),
                        size: 28,
                      ),
                      onPressed: () {
                        if (_isMapReady) {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Recenter Button (Bottom Right)
            Positioned(
              bottom: 80,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.my_location,
                    color: Color(0xFF0D47A1),
                    size: 28,
                  ),
                  onPressed: () {
                    if (_isMapReady) {
                      _mapController.move(widget.currentPosition, 14);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
