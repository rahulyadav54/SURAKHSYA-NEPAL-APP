import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/emergency_controller.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;

  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _responders = [];

  @override
  void initState() {
    super.initState();
    _loadLocationAndResponders();
  }

  Future<void> _loadLocationAndResponders() async {
    setState(() => _isLoading = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      
      final double lat = position.latitude;
      final double lng = position.longitude;

      // Create mock responder coordinates relative to user location
      _responders = [
        {
          'id': 'resp_police',
          'name': 'Metropolitan Police Patrol 4',
          'type': 'Police',
          'icon': Icons.local_police_rounded,
          'color': Colors.blue.shade700,
          'lat': lat - 0.0035,
          'lng': lng + 0.0051,
          'status': 'ACTIVE',
        },
        {
          'id': 'resp_amb',
          'name': 'Bir Hospital Ambulance Service',
          'type': 'Ambulance',
          'icon': Icons.local_hospital_rounded,
          'color': Colors.red.shade700,
          'lat': lat + 0.0042,
          'lng': lng - 0.0028,
          'status': 'ON WAY',
        },
        {
          'id': 'resp_fire',
          'name': 'Kathmandu Fire Station Unit 12',
          'type': 'Fire',
          'icon': Icons.fire_truck_rounded,
          'color': Colors.orange.shade700,
          'lat': lat + 0.0021,
          'lng': lng + 0.0038,
          'status': 'STANDBY',
        },
      ];

      // Build Marker Set
      _markers.clear();
      
      // User Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('user_loc'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Your Location', snippet: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );

      // Responders Markers
      for (final resp in _responders) {
        double hue = BitmapDescriptor.hueRed;
        if (resp['type'] == 'Police') {
          hue = BitmapDescriptor.hueBlue;
        } else if (resp['type'] == 'Fire') {
          hue = BitmapDescriptor.hueOrange;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(resp['id'] as String),
            position: LatLng(resp['lat'] as double, resp['lng'] as double),
            infoWindow: InfoWindow(
              title: resp['name'] as String,
              snippet: '${resp['type']} - Status: ${resp['status']}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          ),
        );
      }

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Animate Map Camera
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.5),
        );
      }
    } catch (e) {
      debugPrint('Error loading live map: $e');
      setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dispatch Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Real Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 27.7172,
                      _currentPosition?.longitude ?? 85.3240,
                    ),
                    zoom: 14.5,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Overlay sliding responder cards
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _responders.length,
                      itemBuilder: (context, index) {
                        final resp = _responders[index];
                        final color = resp['color'] as Color;
                        final icon = resp['icon'] as IconData;
                        
                        double distance = 0.0;
                        if (_currentPosition != null) {
                          distance = _calculateDistance(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            resp['lat'] as double,
                            resp['lng'] as double,
                          );
                        }

                        return Container(
                          width: size.width * 0.8,
                          margin: const EdgeInsets.only(right: 16),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              onTap: () {
                                if (_mapController != null) {
                                  _mapController!.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(resp['lat'] as double, resp['lng'] as double),
                                      16.0,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: color, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            resp['name'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.directions_run_rounded, size: 14, color: theme.colorScheme.outline),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${distance.toStringAsFixed(2)} km away',
                                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  resp['status'] as String,
                                                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                ),
              ],
            ),
    );
  }
}
