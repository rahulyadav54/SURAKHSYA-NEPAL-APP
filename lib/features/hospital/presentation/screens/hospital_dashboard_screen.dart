import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HospitalDashboardScreen extends ConsumerStatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  ConsumerState<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends ConsumerState<HospitalDashboardScreen> {
  bool _erAvailable = true;
  int _availableBeds = 14;
  int _icuBeds = 4;
  String _bloodStatus = 'AVAILABLE';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tribhuvan Teaching Hospital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Hospital Emergency Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
                            label: Text(_erAvailable ? 'AVAILABLE' : 'FULL / BUSY'),
                            selected: _erAvailable,
                            selectedColor: Colors.green.shade100,
                            onSelected: (selected) {
                              setState(() {
                                _erAvailable = selected;
                              });
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
                              const Text('General Beds Available', style: TextStyle(color: Colors.black70, fontSize: 13)),
                              Text('$_availableBeds Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton.outlined(
                                icon: const Icon(Icons.remove),
                                onPressed: _availableBeds > 0 ? () => setState(() => _availableBeds--) : null,
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _availableBeds++),
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
                              const Text('ICU Beds Available', style: TextStyle(color: Colors.black70, fontSize: 13)),
                              Text('$_icuBeds ICU Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton.outlined(
                                icon: const Icon(Icons.remove),
                                onPressed: _icuBeds > 0 ? () => setState(() => _icuBeds--) : null,
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _icuBeds++),
                              ),
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

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.airport_shuttle_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Text('NP-AMB-102', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                            child: const Text('ETA 7 MINS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Patient: Road Traffic Injury', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text('Severity: CRITICAL | Blood Needed: O+ve', style: TextStyle(color: Colors.black70, fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('ACCEPT PATIENT'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                              child: const Text('PREPARE ER', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
