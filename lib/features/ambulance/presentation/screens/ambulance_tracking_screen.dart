import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/ambulance_controller.dart';
import '../../domain/entities/ambulance_request.dart';

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

  /// Mocks a street-aligned optimized route polyline using intermediate nodes
  List<LatLng> _generateOptimizedRoutePoints(LatLng start, LatLng end) {
    final list = <LatLng>[];
    list.add(start);

    final dLat = end.latitude - start.latitude;
    final dLon = end.longitude - start.longitude;

    // Add intermediate nodes to simulate street turns
    list.add(LatLng(start.latitude + dLat * 0.25, start.longitude + dLon * 0.15));
    list.add(LatLng(start.latitude + dLat * 0.50, start.longitude + dLon * 0.70));
    list.add(LatLng(start.latitude + dLat * 0.75, start.longitude + dLon * 0.40));

    list.add(end);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestAsync = ref.watch(activeRequestStreamProvider(widget.requestId));

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
          final latLng = LatLng(request.pickupLatitude, request.pickupLongitude);
          
          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('pickup'),
              position: latLng,
              infoWindow: const InfoWindow(title: 'Your Location (तपाईंको स्थान)'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };

          final Set<Polyline> polylines = {};
          LatLng? ambulanceLatLng;

          if (request.ambulance != null) {
            ambulanceLatLng = LatLng(request.ambulance!.latitude, request.ambulance!.longitude);
            
            // Generate optimized route
            final routePoints = _generateOptimizedRoutePoints(ambulanceLatLng, latLng);

            // Add ambulance marker
            markers.add(
              Marker(
                markerId: const MarkerId('ambulance'),
                position: ambulanceLatLng,
                infoWindow: InfoWindow(
                  title: 'Ambulance: ${request.ambulance!.driverName}',
                  snippet: request.ambulance!.licensePlate,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );

            // Add optimized Polyline route overlay
            polylines.add(
              Polyline(
                polylineId: const PolylineId('optimized_route'),
                points: routePoints,
                color: theme.colorScheme.primary,
                width: 6,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );

            if (_mapController != null) {
              final bounds = LatLngBounds(
                southwest: LatLng(
                  latLng.latitude < ambulanceLatLng.latitude ? latLng.latitude : ambulanceLatLng.latitude,
                  latLng.longitude < ambulanceLatLng.longitude ? latLng.longitude : ambulanceLatLng.longitude,
                ),
                northeast: LatLng(
                  latLng.latitude > ambulanceLatLng.latitude ? latLng.latitude : ambulanceLatLng.latitude,
                  latLng.longitude > ambulanceLatLng.longitude ? latLng.longitude : ambulanceLatLng.longitude,
                ),
              );
              _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: latLng,
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

              if (request.status == 'PENDING')
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
                ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildTrackingDetailsCard(context, request),
              ),
            ],
          );
        },
        loading: () => const SurakshaLoading(size: 60),
        error: (err, stack) => SurakshaErrorWidget(
          message: 'Failed to retrieve live updates: ${err.toString()}',
          onRetry: () => ref.invalidate(activeRequestStreamProvider(widget.requestId)),
        ),
      ),
    );
  }

  Widget _buildTrackingDetailsCard(BuildContext context, AmbulanceRequest request) {
    final theme = Theme.of(context);
    final status = request.status;
    final hasAmbulance = request.ambulance != null;

    Color statusColor = Colors.orange;
    String statusTitleNp = 'सम्पर्क स्थापित गरिदै... (Connecting...)';
    String statusDesc = 'Dispatch center is matching you with nearby ambulance units.';

    if (status == 'ASSIGNED') {
      statusColor = theme.colorScheme.primary;
      statusTitleNp = 'एम्बुलेन्स प्रस्थान गर्यो (Ambulance Dispatched)';
      statusDesc = 'Ambulance is heading towards your current coordinates.';
    } else if (status == 'PICKED_UP') {
      statusColor = Colors.purple;
      statusTitleNp = 'बिरामी पिकअप गरियो (Patient Picked Up)';
      statusDesc = 'In transit to assigned emergency hospital center.';
    } else if (status == 'COMPLETED') {
      statusColor = Colors.green;
      statusTitleNp = 'उपचार केन्द्र पुग्यो (Completed)';
      statusDesc = 'Arrived at the emergency medical facility.';
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
                        statusTitleNp,
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

            // Live ETA or Hospital Details
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
                      request.etaMinutes != null ? '${request.etaMinutes} mins' : '-- mins',
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
                      'ASSIGNED HOSPITAL',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.hospitalName ?? 'Assigning hospital...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (hasAmbulance) ...[
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      request.ambulance!.driverName.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.ambulance!.driverName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.ambulance!.licensePlate,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dialing ${request.ambulance!.phone}')),
                      );
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
