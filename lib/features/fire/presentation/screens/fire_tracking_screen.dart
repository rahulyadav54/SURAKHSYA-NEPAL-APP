import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';

class FireTrackingScreen extends ConsumerStatefulWidget {
  final String reportId;

  const FireTrackingScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<FireTrackingScreen> createState() => _FireTrackingScreenState();
}

class _FireTrackingScreenState extends ConsumerState<FireTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(emergencyRequestStreamProvider(widget.reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Dispatch Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: requestAsync.when(
        data: (request) {
          final targetLat = request['latitude'] as double;
          final targetLng = request['longitude'] as double;
          final targetLatLng = LatLng(targetLat, targetLng);

          final responder = request['responders'] as Map<String, dynamic>?;
          final profile = responder?['profiles'] as Map<String, dynamic>?;
          final vehicle = responder?['vehicles'] as Map<String, dynamic>?;

          LatLng? responderLatLng;
          double distanceKm = 0.0;
          int etaMinutes = 10;

          if (responder != null) {
            final double? respLat = responder['current_latitude'] as double?;
            final double? respLng = responder['current_longitude'] as double?;
            if (respLat != null && respLng != null) {
              responderLatLng = LatLng(respLat, respLng);
              
              final distanceMeters = Geolocator.distanceBetween(
                respLat, respLng, targetLat, targetLng
              );
              distanceKm = distanceMeters / 1000.0;
              etaMinutes = (distanceKm * 2.0 + 2.0).ceil();
            }
          }

          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('pickup'),
              position: targetLatLng,
              infoWindow: const InfoWindow(title: 'Fire Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };

          final Set<Polyline> polylines = {};

          if (responderLatLng != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('fire_truck'),
                position: responderLatLng,
                infoWindow: InfoWindow(
                  title: '${profile?['full_name'] ?? 'Fire Brigade Unit'}',
                  snippet: '${vehicle?['vehicle_type'] ?? 'Fire Tender'} (${vehicle?['vehicle_number'] ?? 'N/A'})',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
            );

            polylines.add(
              Polyline(
                polylineId: const PolylineId('fire_route'),
                points: [responderLatLng, targetLatLng],
                color: Colors.orange.shade800,
                width: 6,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );

            if (_mapController != null) {
              final bounds = LatLngBounds(
                southwest: LatLng(
                  targetLat < responderLatLng.latitude ? targetLat : responderLatLng.latitude,
                  targetLng < responderLatLng.longitude ? targetLng : responderLatLng.longitude,
                ),
                northeast: LatLng(
                  targetLat > responderLatLng.latitude ? targetLat : responderLatLng.latitude,
                  targetLng > responderLatLng.longitude ? targetLng : responderLatLng.longitude,
                ),
              );
              _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: targetLatLng,
                  zoom: 14.5,
                ),
                markers: markers,
                polylines: polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildStatusCard(context, request, distanceKm, etaMinutes),
              ),
            ],
          );
        },
        loading: () => const SurakshaLoading(size: 60),
        error: (err, stack) => SurakshaErrorWidget(
          message: 'Failed to retrieve updates: $err',
          onRetry: () => ref.invalidate(emergencyRequestStreamProvider(widget.reportId)),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    Map<String, dynamic> request,
    double distanceKm,
    int etaMinutes,
  ) {
    final theme = Theme.of(context);
    final status = request['status'] as String? ?? 'REQUESTED';
    final responder = request['responders'] as Map<String, dynamic>?;

    int currentStep = 0;
    if (status == 'ACCEPTED' || status == 'DISPATCHING') {
      currentStep = 1;
    } else if (status == 'EN_ROUTE' || status == 'ARRIVED') {
      currentStep = 2;
    } else if (status == 'COMPLETED') {
      currentStep = 3;
    }

    final steps = [
      {'title': 'Reported', 'subtitle': 'Logged'},
      {'title': 'Dispatched', 'subtitle': 'En route'},
      {'title': 'Active', 'subtitle': 'Responding'},
      {'title': 'Resolved', 'subtitle': 'Extinguished'},
    ];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIRE ENGINE DISPATCH PROGRESS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status == 'ARRIVED'
                          ? 'Fire Truck arrived on site'
                          : (responder != null ? 'Arriving in $etaMinutes mins' : 'Awaiting responder match...'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Severity: ${request['severity'] ?? 'HIGH'}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stepper Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length, (index) {
                final isPassed = index <= currentStep;
                final isCurrent = index == currentStep;
                final color = isPassed 
                    ? (status == 'COMPLETED' ? Colors.green : theme.colorScheme.primary) 
                    : theme.colorScheme.outlineVariant;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isPassed ? color : theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: isPassed
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index]['title']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isPassed ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[index]['subtitle']!,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
            
            const Divider(height: 32),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_rounded, size: 18, color: theme.colorScheme.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${request['description'] ?? 'No description provided.'}',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
