import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/fire_controller.dart';
import '../../domain/entities/fire_report.dart';

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
  Timer? _simulationTimer;
  double _simulationProgress = 0.0;

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    if (_simulationTimer != null) return;
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _simulationProgress += 0.05; // 20 steps to reach destination
        if (_simulationProgress >= 1.0) {
          _simulationProgress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  List<LatLng> _generateOptimizedRoutePoints(LatLng start, LatLng end) {
    final list = <LatLng>[];
    list.add(start);
    final dLat = end.latitude - start.latitude;
    final dLon = end.longitude - start.longitude;
    list.add(LatLng(start.latitude + dLat * 0.20, start.longitude + dLon * 0.35));
    list.add(LatLng(start.latitude + dLat * 0.55, start.longitude + dLon * 0.60));
    list.add(LatLng(start.latitude + dLat * 0.85, start.longitude + dLon * 0.40));
    list.add(end);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(activeFireStreamProvider(widget.reportId));

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
      body: reportAsync.when(
        data: (report) {
          final targetLatLng = LatLng(report.latitude, report.longitude);
          
          // Fixed mock starting position for fire engine (approx 1.2 km offset)
          final double startLat = report.latitude + 0.009;
          final double startLng = report.longitude - 0.008;

          // Compute interpolated dynamic vehicle coordinates
          final currentLat = startLat + (report.latitude - startLat) * _simulationProgress;
          final currentLng = startLng + (report.longitude - startLng) * _simulationProgress;
          final fireTruckLatLng = LatLng(currentLat, currentLng);

          // Start active route simulation
          _startSimulation();

          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('pickup'),
              position: targetLatLng,
              infoWindow: const InfoWindow(title: 'Fire Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
            Marker(
              markerId: const MarkerId('fire_truck'),
              position: fireTruckLatLng,
              infoWindow: const InfoWindow(title: 'Fire Engine Unit - BA 1 PA 7777', snippet: 'Responding Crew: Station A'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
          };

          final routePoints = _generateOptimizedRoutePoints(fireTruckLatLng, targetLatLng);
          final Set<Polyline> polylines = {
            Polyline(
              polylineId: const PolylineId('fire_route'),
              points: routePoints,
              color: Colors.orange.shade800,
              width: 6,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };

          if (_mapController != null) {
            final bounds = LatLngBounds(
              southwest: LatLng(
                targetLatLng.latitude < fireTruckLatLng.latitude ? targetLatLng.latitude : fireTruckLatLng.latitude,
                targetLatLng.longitude < fireTruckLatLng.longitude ? targetLatLng.longitude : fireTruckLatLng.longitude,
              ),
              northeast: LatLng(
                targetLatLng.latitude > fireTruckLatLng.latitude ? targetLatLng.latitude : fireTruckLatLng.latitude,
                targetLatLng.longitude > fireTruckLatLng.longitude ? targetLatLng.longitude : fireTruckLatLng.longitude,
              ),
            );
            _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
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
                child: _buildStatusCard(context, report),
              ),
            ],
          );
        },
        loading: () => const SurakshaLoading(size: 60),
        error: (err, stack) => SurakshaErrorWidget(
          message: 'Failed to retrieve updates: ${err.toString()}',
          onRetry: () => ref.invalidate(activeFireStreamProvider(widget.reportId)),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, FireReport report) {
    final theme = Theme.of(context);
    final status = report.status;

    int currentStep = 0;
    if (status == 'DISPATCHED') {
      currentStep = 1;
    } else if (status == 'ACTIVE') {
      currentStep = 2;
    } else if (status == 'RESOLVED') {
      currentStep = 3;
    }

    final steps = [
      {'title': 'Reported', 'subtitle': 'Logged'},
      {'title': 'Dispatched', 'subtitle': 'En route'},
      {'title': 'Active', 'subtitle': 'Fighting'},
      {'title': 'Resolved', 'subtitle': 'Extinguished'},
    ];

    final etaMin = (10 * (1.0 - _simulationProgress)).toStringAsFixed(0);

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
                      _simulationProgress < 1.0 ? 'Fire Truck arriving in $etaMin mins' : 'Fire Truck arrived on site',
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
                    'Severity: ${report.aiPredictedSeverity}',
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
                    ? (status == 'RESOLVED' ? Colors.green : theme.colorScheme.primary) 
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
                    report.description.isNotEmpty ? report.description : 'No description provided.',
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
