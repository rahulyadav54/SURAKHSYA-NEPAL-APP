import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';

class AmbulanceTrackingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const AmbulanceTrackingScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<AmbulanceTrackingScreen> createState() => _AmbulanceTrackingScreenState();
}

class _AmbulanceTrackingScreenState extends ConsumerState<AmbulanceTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestAsync = ref.watch(emergencyRequestStreamProvider(widget.requestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Rescue Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: requestAsync.when(
        data: (request) {
          final citizenLat = request['latitude'] as double;
          final citizenLng = request['longitude'] as double;
          final citizenLatLng = LatLng(citizenLat, citizenLng);

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
              
              // Calculate real physical distance in kilometers
              final distanceMeters = Geolocator.distanceBetween(
                respLat, respLng, citizenLat, citizenLng
              );
              distanceKm = distanceMeters / 1000.0;
              
              // Estimate arrival time (approx 2 minutes per km + 2 minutes base buffers)
              etaMinutes = (distanceKm * 2.0 + 2.0).ceil();
            }
          }

          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('citizen'),
              position: citizenLatLng,
              infoWindow: const InfoWindow(title: 'My Position', snippet: 'Awaiting assistance here'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };

          final Set<Polyline> polylines = {};

          if (responderLatLng != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('responder'),
                position: responderLatLng,
                infoWindow: InfoWindow(
                  title: '${profile?['full_name'] ?? 'Responder Ambulance'}',
                  snippet: '${vehicle?['vehicle_type'] ?? 'Ambulance'} (${vehicle?['vehicle_number'] ?? 'N/A'})',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );

            // Connect citizen and responder with active route
            polylines.add(
              Polyline(
                polylineId: const PolylineId('active_dispatch_route'),
                points: [responderLatLng, citizenLatLng],
                color: theme.colorScheme.primary,
                width: 6,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );

            // Re-adjust camera bounds dynamically to include both citizen and responder
            if (_mapController != null) {
              final bounds = LatLngBounds(
                southwest: LatLng(
                  citizenLat < responderLatLng.latitude ? citizenLat : responderLatLng.latitude,
                  citizenLng < responderLatLng.longitude ? citizenLng : responderLatLng.longitude,
                ),
                northeast: LatLng(
                  citizenLat > responderLatLng.latitude ? citizenLat : responderLatLng.latitude,
                  citizenLng > responderLatLng.longitude ? citizenLng : responderLatLng.longitude,
                ),
              );
              _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: citizenLatLng,
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
                child: _buildTrackingCard(context, request, distanceKm, etaMinutes),
              ),
            ],
          );
        },
        loading: () => const SurakshaLoading(size: 60),
        error: (err, stack) => SurakshaErrorWidget(
          message: 'Failed to connect live GPS tracker: $err',
          onRetry: () => ref.invalidate(emergencyRequestStreamProvider(widget.requestId)),
        ),
      ),
    );
  }

  Widget _buildTrackingCard(
    BuildContext context,
    Map<String, dynamic> request,
    double distanceKm,
    int etaMinutes,
  ) {
    final theme = Theme.of(context);
    final status = request['status'] as String? ?? 'REQUESTED';
    final responder = request['responders'] as Map<String, dynamic>?;
    final profile = responder?['profiles'] as Map<String, dynamic>?;
    final vehicle = responder?['vehicles'] as Map<String, dynamic>?;

    Color statusColor = Colors.orange;
    String statusTitle = 'Finding Nearest Ambulance...';
    String statusDesc = 'Dispatch centers are matching your distress alert with emergency units.';

    if (status == 'ACCEPTED' || status == 'DISPATCHING') {
      statusColor = Colors.blue;
      statusTitle = 'Rescue Unit Assigned';
      statusDesc = 'An ambulance responder has accepted and is preparing to depart.';
    } else if (status == 'EN_ROUTE') {
      statusColor = theme.colorScheme.primary;
      statusTitle = 'Ambulance En Route';
      statusDesc = 'Ambulance is navigating actively towards your current location.';
    } else if (status == 'ARRIVED') {
      statusColor = Colors.green;
      statusTitle = 'Ambulance Arrived (आइपुग्यो)';
      statusDesc = 'The rescue team has arrived at your location. Look out for them!';
    } else if (status == 'COMPLETED') {
      statusColor = Colors.teal;
      statusTitle = 'Mission Completed';
      statusDesc = 'Successfully reached the emergency hospital center.';
    }

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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == 'COMPLETED' ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDesc,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED ARRIVAL',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status == 'ARRIVED'
                          ? 'Arrived'
                          : (responder != null ? '$etaMinutes mins' : 'Calculating...'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'DISTANCE',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      responder != null ? '${distanceKm.toStringAsFixed(1)} km away' : 'Matching...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (responder != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (profile?['full_name'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?['full_name'] as String? ?? 'Guest Driver',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle?['vehicle_number'] ?? 'N/A'} - ${vehicle?['vehicle_type'] ?? 'Emergency Unit'}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () {
                      final phone = profile?['phone'];
                      if (phone != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dialing responder: $phone')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
