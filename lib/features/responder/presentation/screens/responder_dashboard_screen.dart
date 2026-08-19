import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

class ResponderDashboardScreen extends ConsumerStatefulWidget {
  const ResponderDashboardScreen({super.key});

  @override
  ConsumerState<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends ConsumerState<ResponderDashboardScreen> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final userProfile = authState is Authenticated ? authState.profile : null;

    final serviceName = userProfile?.serviceType?.label ?? 'Ambulance Service';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Suraksha Responder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(serviceName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
                  case UserRole.dispatcher:
                    context.go('/command-center');
                    break;
                  case UserRole.hospital:
                    context.go('/hospital-dashboard');
                    break;
                  case UserRole.admin:
                    context.go('/admin');
                    break;
                  case UserRole.responder:
                    break;
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: UserRole.citizen, child: Text('Citizen Portal')),
              const PopupMenuItem(value: UserRole.responder, child: Text('Responder Portal (Active)')),
              const PopupMenuItem(value: UserRole.dispatcher, child: Text('Dispatcher Command Center')),
              const PopupMenuItem(value: UserRole.hospital, child: Text('Hospital Dashboard')),
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
              // Availability Toggle Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: _isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAvailable ? 'AVAILABLE FOR DISPATCH' : 'OFFLINE / BUSY',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _isAvailable ? Colors.green.shade900 : Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              _isAvailable ? 'Receiving emergency requests' : 'Tap switch to go online',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isAvailable,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            _isAvailable = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Today's",
                      value: '8',
                      icon: Icons.assignment_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Completed',
                      value: '6',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Active',
                      value: '1',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Incoming Request Demo Card
              Text(
                'Incoming Emergency Request',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CRITICAL MEDICAL',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Text(
                            'ETA: 5 mins',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black80),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Road Accident & Medical Emergency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 18),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Lakeside Chowk, Pokhara (2.1 km away)',
                              style: TextStyle(color: Colors.black70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.close_rounded, color: Colors.red),
                              label: const Text('REJECT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.check_rounded, color: Colors.white),
                              label: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
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

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
