import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/dispatcher_controller.dart';

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final emergenciesAsync = ref.watch(activeEmergenciesStreamProvider);
    final respondersAsync = ref.watch(activeRespondersStreamProvider);
    final resourcesSummaryAsync = ref.watch(resourcesSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monitor_heart_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('SURAKSHYA COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(activeEmergenciesStreamProvider);
              ref.invalidate(activeRespondersStreamProvider);
              ref.invalidate(resourcesSummaryProvider);
            },
            tooltip: 'Refresh Active Feeds',
          ),
          PopupMenuButton<UserRole>(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Portal View',
            onSelected: (role) async {
              await ref.read(authControllerProvider.notifier).switchRole(role);
              if (mounted) {
                switch (role) {
                  case UserRole.citizen:
                    context.go('/home');
                    break;
                  case UserRole.responder:
                    context.go('/responder');
                    break;
                  case UserRole.dispatcher:
                    break;
                  case UserRole.hospital:
                    context.go('/hospital-dashboard');
                    break;
                  case UserRole.admin:
                    context.go('/admin');
                    break;
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: UserRole.citizen, child: Text('Citizen Portal')),
              const PopupMenuItem(value: UserRole.responder, child: Text('Responder Portal')),
              const PopupMenuItem(value: UserRole.dispatcher, child: Text('Dispatcher Command Center (Active)')),
              const PopupMenuItem(value: UserRole.hospital, child: Text('Hospital Dashboard')),
              const PopupMenuItem(value: UserRole.admin, child: Text('Admin Portal')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Left panel: Active Emergencies
                  SizedBox(
                    width: 340,
                    child: emergenciesAsync.when(
                      data: (list) => _buildEmergenciesPanel(context, list, respondersAsync.value ?? []),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading feeds: $err')),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Middle: Live Map View
                  Expanded(
                    child: _buildMapCenterPanel(
                      context,
                      emergenciesAsync.value ?? [],
                      respondersAsync.value ?? [],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Right panel: Resources Status
                  SizedBox(
                    width: 280,
                    child: resourcesSummaryAsync.when(
                      data: (summary) => _buildResourcesPanel(context, summary),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading status: $err')),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    resourcesSummaryAsync.when(
                      data: (summary) => _buildResourcesPanel(context, summary),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: _buildMapCenterPanel(
                        context,
                        emergenciesAsync.value ?? [],
                        respondersAsync.value ?? [],
                      ),
                    ),
                    const SizedBox(height: 16),
                    emergenciesAsync.when(
                      data: (list) => _buildEmergenciesPanel(context, list, respondersAsync.value ?? []),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmergenciesPanel(
    BuildContext context,
    List<Map<String, dynamic>> emergencies,
    List<Map<String, dynamic>> responders,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LIVE EMERGENCIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${emergencies.length} Active',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: emergencies.isEmpty
                ? const Center(
                    child: Text(
                      'No active emergency calls',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: emergencies.length,
                    itemBuilder: (context, index) {
                      final req = emergencies[index];
                      final id = req['id'] as String;
                      final type = req['emergency_type'] as String? ?? 'Emergency Incident';
                      final address = req['address'] as String? ?? 'Coordinates: ${req['latitude']}, ${req['longitude']}';
                      final severity = req['severity'] as String? ?? 'HIGH';
                      final status = req['status'] as String? ?? 'REQUESTED';

                      Color sevColor = Colors.orange;
                      if (severity.toUpperCase() == 'CRITICAL') {
                        sevColor = Colors.red;
                      } else if (severity.toUpperCase() == 'LOW') {
                        sevColor = Colors.green;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${id.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sevColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        severity,
                                        style: TextStyle(color: sevColor, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Status: $status',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                    ),
                                    if (status == 'REQUESTED' || status == 'NO_RESPONDER' || status == 'DISPATCHING')
                                      ElevatedButton(
                                        onPressed: () => _showDispatchDialog(context, req, responders),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('DISPATCH', style: TextStyle(fontSize: 11)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDispatchDialog(
    BuildContext context,
    Map<String, dynamic> emergency,
    List<Map<String, dynamic>> responders,
  ) {
    final theme = Theme.of(context);
    final double emergencyLat = emergency['latitude'] as double;
    final double emergencyLng = emergency['longitude'] as double;

    // Filter for available responders
    final available = responders.where((r) => r['availability_status'] == 'AVAILABLE').toList();

    // Sort by physical distance to emergency
    available.sort((a, b) {
      final aLat = a['current_latitude'] as double? ?? 0.0;
      final aLng = a['current_longitude'] as double? ?? 0.0;
      final bLat = b['current_latitude'] as double? ?? 0.0;
      final bLng = b['current_longitude'] as double? ?? 0.0;

      final distA = Geolocator.distanceBetween(emergencyLat, emergencyLng, aLat, aLng);
      final distB = Geolocator.distanceBetween(emergencyLat, emergencyLng, bLat, bLng);
      return distA.compareTo(distB);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dispatch Responder to #${emergency['id'].toString().substring(0, 8).toUpperCase()}'),
        content: available.isEmpty
            ? const Text('No available/online units found in vicinity.')
            : SizedBox(
                width: 450,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final r = available[index];
                    final profile = r['profiles'] as Map<String, dynamic>?;
                    final vehicle = r['vehicles'] as Map<String, dynamic>?;

                    final rLat = r['current_latitude'] as double? ?? 0.0;
                    final rLng = r['current_longitude'] as double? ?? 0.0;
                    final distanceM = Geolocator.distanceBetween(emergencyLat, emergencyLng, rLat, rLng);
                    final distanceKm = distanceM / 1000.0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          vehicle?['vehicle_type']?.toString().toLowerCase().contains('ambulance') == true
                              ? Icons.local_hospital
                              : Icons.local_police,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(profile?['full_name'] ?? 'Emergency Crew'),
                      subtitle: Text('${vehicle?['vehicle_type'] ?? 'Vehicle'} (${vehicle?['vehicle_number'] ?? 'N/A'})\n${distanceKm.toStringAsFixed(1)} km away'),
                      trailing: ElevatedButton(
                        child: const Text('DISPATCH'),
                        onPressed: () async {
                          Navigator.pop(context);
                          final success = await ref
                              .read(dispatcherControllerProvider.notifier)
                              .manuallyDispatch(emergency['id'] as String, r['id'] as String);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Manual dispatch request triggered successfully!'
                                    : 'Dispatch request failed. Try again.'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCenterPanel(
    BuildContext context,
    List<Map<String, dynamic>> emergencies,
    List<Map<String, dynamic>> responders,
  ) {
    final Set<Marker> markers = {};

    // 1. Add emergency requests markers (Red)
    for (var req in emergencies) {
      final double? lat = req['latitude'] as double?;
      final double? lng = req['longitude'] as double?;
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('emergency_${req['id']}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: '${req['emergency_type'] ?? 'Incident'}',
              snippet: 'Severity: ${req['severity']} | Status: ${req['status']}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    // 2. Add responder coordinates (Adaptive markers)
    for (var resp in responders) {
      final double? lat = resp['current_latitude'] as double?;
      final double? lng = resp['current_longitude'] as double?;
      if (lat != null && lng != null) {
        final vehicle = resp['vehicles'] as Map<String, dynamic>?;
        final type = vehicle?['vehicle_type'] as String? ?? '';

        double hue = BitmapDescriptor.hueGreen;
        if (type.toLowerCase().contains('ambulance')) {
          hue = BitmapDescriptor.hueCyan;
        } else if (type.toLowerCase().contains('police') || type.toLowerCase().contains('patrol')) {
          hue = BitmapDescriptor.hueBlue;
        } else if (type.toLowerCase().contains('fire')) {
          hue = BitmapDescriptor.hueOrange;
        }

        final profile = resp['profiles'] as Map<String, dynamic>?;
        markers.add(
          Marker(
            markerId: MarkerId('responder_${resp['id']}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: '${profile?['full_name'] ?? 'Unit'} (${resp['availability_status']})',
              snippet: '$type | ${vehicle?['vehicle_number'] ?? ''}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          ),
        );
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(27.7172, 85.3240), // Default center Kathmandu
          zoom: 12.5,
        ),
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  Widget _buildResourcesPanel(BuildContext context, Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESOURCES SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildResourceTile(
            icon: Icons.airport_shuttle_rounded,
            label: 'Ambulances Online',
            count: summary['ambulances'] as String? ?? '0 / 0',
            color: Colors.red,
          ),
          _buildResourceTile(
            icon: Icons.local_police_rounded,
            label: 'Police Units Online',
            count: summary['police'] as String? ?? '0 / 0',
            color: Colors.blue,
          ),
          _buildResourceTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Fire Units Online',
            count: summary['fire'] as String? ?? '0 / 0',
            color: Colors.orange,
          ),
          _buildResourceTile(
            icon: Icons.local_hospital_rounded,
            label: 'Hospitals Connected',
            count: summary['hospitals'] as String? ?? '0 connected',
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTile({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

