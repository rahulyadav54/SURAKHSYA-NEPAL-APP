import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/hospital_controller.dart';

class HospitalDashboardScreen extends ConsumerStatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  ConsumerState<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends ConsumerState<HospitalDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hospitalState = ref.watch(hospitalControllerProvider);
    final hospital = hospitalState.hospital;

    if (hospitalState.isLoading) {
      return const Scaffold(
        body: Center(child: SurakshaLoading(size: 60)),
      );
    }

    final String name = hospital?['name'] as String? ?? 'Tribhuvan Teaching Hospital';
    final bool erAvailable = hospital?['emergency_available'] as bool? ?? true;
    final int availableBeds = hospital?['available_beds'] as int? ?? 10;
    final int icuBeds = hospital?['icu_beds'] as int? ?? 2;
    final String bloodStatus = hospital?['blood_available'] as String? ?? 'AVAILABLE';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Hospital Emergency Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
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
                    context.go('/command-center');
                    break;
                  case UserRole.hospital:
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
              const PopupMenuItem(value: UserRole.dispatcher, child: Text('Dispatcher Command Center')),
              const PopupMenuItem(value: UserRole.hospital, child: Text('Hospital Dashboard (Active)')),
              const PopupMenuItem(value: UserRole.admin, child: Text('Admin Portal')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emergency Room Capacity Controls Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hospital Capacity & Live Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Emergency Room Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                          ChoiceChip(
                            label: Text(erAvailable ? 'AVAILABLE' : 'FULL / BUSY'),
                            selected: erAvailable,
                            selectedColor: Colors.green.shade100,
                            onSelected: (selected) {
                              ref.read(hospitalControllerProvider.notifier).updateCapacity(
                                erAvailable: selected,
                              );
                            },
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
                              const Text('General Beds Available', style: TextStyle(color: Colors.black87, fontSize: 13)),
                              Text('$availableBeds Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton.outlined(
                                icon: const Icon(Icons.remove),
                                onPressed: availableBeds > 0
                                    ? () => ref.read(hospitalControllerProvider.notifier).updateCapacity(
                                          availableBeds: availableBeds - 1,
                                        )
                                    : null,
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.add),
                                onPressed: () => ref.read(hospitalControllerProvider.notifier).updateCapacity(
                                      availableBeds: availableBeds + 1,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ICU Beds Available', style: TextStyle(color: Colors.black87, fontSize: 13)),
                              Text('$icuBeds ICU Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton.outlined(
                                icon: const Icon(Icons.remove),
                                onPressed: icuBeds > 0
                                    ? () => ref.read(hospitalControllerProvider.notifier).updateCapacity(
                                          icuBeds: icuBeds - 1,
                                        )
                                    : null,
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.add),
                                onPressed: () => ref.read(hospitalControllerProvider.notifier).updateCapacity(
                                      icuBeds: icuBeds + 1,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Blood Bank Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<String>(
                            value: bloodStatus,
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(hospitalControllerProvider.notifier).updateCapacity(
                                  bloodAvailable: val,
                                );
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'AVAILABLE', child: Text('AVAILABLE (प्रशस्त छ)')),
                              DropdownMenuItem(value: 'LOW', child: Text('LOW STATUS (न्यून छ)')),
                              DropdownMenuItem(value: 'UNAVAILABLE', child: Text('UNAVAILABLE (सकिएको छ)')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Incoming Ambulance Patient Card
              Text(
                'Incoming Ambulance En-Route',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              hospitalState.incomingAmbulances.isEmpty
                  ? Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No active incoming emergency patient transfers',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: hospitalState.incomingAmbulances.map((req) {
                        final id = req['id'] as String;
                        final responders = req['responders'] as Map<String, dynamic>?;
                        final profile = responders?['profiles'] as Map<String, dynamic>?;
                        final vehicle = responders?['vehicles'] as Map<String, dynamic>?;
                        final description = req['description'] as String? ?? 'Emergency Incident';
                        final severity = req['severity'] as String? ?? 'HIGH';
                        final status = req['status'] as String? ?? 'ACCEPTED';

                        Color borderColors = Colors.orange.shade300;
                        if (severity.toUpperCase() == 'CRITICAL') {
                          borderColors = Colors.red.shade400;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColors, width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.airport_shuttle_rounded, color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text(
                                            vehicle?['vehicle_number'] as String? ?? 'AMBULANCE',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                                        child: Text(
                                          status == 'ARRIVED' ? 'ARRIVED ON SITE' : 'EN ROUTE',
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Patient Case: $description',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Severity: $severity | Dispatch Driver: ${profile?['full_name'] ?? 'Responder'}',
                                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (status != 'ARRIVED')
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              ref.read(hospitalControllerProvider.notifier).updateEmergencyStatus(
                                                id,
                                                'ARRIVED',
                                              );
                                            },
                                            child: const Text('PREPARE ER'),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            ref.read(hospitalControllerProvider.notifier).updateEmergencyStatus(
                                              id,
                                              'COMPLETED',
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                          child: const Text('ADMIT PATIENT', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
