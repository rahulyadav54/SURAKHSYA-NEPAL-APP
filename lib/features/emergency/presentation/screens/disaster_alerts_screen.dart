import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../controllers/emergency_controller.dart';

class DisasterAlertsScreen extends ConsumerStatefulWidget {
  const DisasterAlertsScreen({super.key});

  @override
  ConsumerState<DisasterAlertsScreen> createState() => _DisasterAlertsScreenState();
}

class _DisasterAlertsScreenState extends ConsumerState<DisasterAlertsScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'alert_eq',
      'title': 'Magnitude 6.2 Earthquake',
      'severity': 'CRITICAL',
      'location': 'Pokhara Epicenter',
      'desc': 'Epicenter located near Pokhara. Seek open space immediately. Aftershocks expected.',
      'lat': 28.2096,
      'lng': 83.9856,
      'time': 'Just now',
      'color': Colors.red.shade800,
    },
    {
      'id': 'alert_flood',
      'title': 'Flash Flood Warning',
      'severity': 'WARNING',
      'location': 'Narayani River Basin',
      'desc': 'Water levels rising rapidly in Narayani river basin. Evacuate low-lying areas immediately.',
      'lat': 27.6833,
      'lng': 84.4333,
      'time': '2 hrs ago',
      'color': Colors.orange.shade800,
    },
    {
      'id': 'alert_landslide',
      'title': 'High Risk of Landslides',
      'severity': 'ADVISORY',
      'location': 'Mugling-Pokhara Highway',
      'desc': 'Heavy rainfall continues. High landslide risk. Avoid unnecessary travel on mountainous routes.',
      'lat': 27.8500,
      'lng': 84.6000,
      'time': '4 hrs ago',
      'color': Colors.blue.shade800,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDisasterMarkers();
  }

  Future<void> _loadDisasterMarkers() async {
    setState(() => _isLoading = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final userPos = await locationService.getCurrentLocation();

      _markers.clear();
      // User marker
      _markers.add(
        Marker(
          markerId: const MarkerId('user_pos'),
          position: LatLng(userPos.latitude, userPos.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );

      // Disaster markers
      for (final a in _alerts) {
        double hue = BitmapDescriptor.hueRed;
        if (a['severity'] == 'WARNING') {
          hue = BitmapDescriptor.hueOrange;
        } else if (a['severity'] == 'ADVISORY') {
          hue = BitmapDescriptor.hueBlue;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(a['id'] as String),
            position: LatLng(a['lat'] as double, a['lng'] as double),
            infoWindow: InfoWindow(title: a['title'] as String, snippet: a['location'] as String),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading disaster markers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report Emergency Incident',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _reportOption(Icons.medical_services_rounded, 'Ambulance', Colors.red, () {
                    Navigator.pop(context);
                    context.push('/ambulance-request');
                  }),
                  _reportOption(Icons.local_fire_department_rounded, 'Fire', Colors.orange, () {
                    Navigator.pop(context);
                    context.push('/fire-report');
                  }),
                  _reportOption(Icons.local_police_rounded, 'Police', Colors.blue, () {
                    Navigator.pop(context);
                    context.push('/police-report');
                  }),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _reportOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Live Disaster Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          'Live Disaster Map',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Map card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(27.7172, 85.3240),
                                zoom: 7.2,
                              ),
                              markers: _markers,
                              onMapCreated: (controller) => _mapController = controller,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Alerts Feed Section
                        Text(
                          'Active Alerts',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 12),

                        ..._alerts.map((a) {
                          final severityColor = a['color'] as Color;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: severityColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          a['severity'] as String,
                                          style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        a['time'] as String,
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    a['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a['desc'] as String,
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        a['location'] as String,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.outline),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (_mapController != null) {
                                            _mapController!.animateCamera(
                                              CameraUpdate.newLatLngZoom(
                                                LatLng(a['lat'] as double, a['lng'] as double),
                                                12.0,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('View Epicenter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Float Persistent Action Button at the bottom
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _showReportSheet,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFBD0022),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.campaign_rounded, size: 22),
                        label: const Text(
                          'Report Incident',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),
                  ),
                ],
              ),
            ),
    );
  }
}
