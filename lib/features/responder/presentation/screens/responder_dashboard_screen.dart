import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../controllers/responder_controller.dart';

class ResponderDashboardScreen extends ConsumerStatefulWidget {
  const ResponderDashboardScreen({super.key});

  @override
  ConsumerState<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends ConsumerState<ResponderDashboardScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 30;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(String dispatchId) {
    _countdownTimer?.cancel();
    _secondsRemaining = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _countdownTimer?.cancel();
        // Auto-reject on timeout
        ref.read(responderControllerProvider.notifier).rejectDispatch(dispatchId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final responderState = ref.watch(responderControllerProvider);
    final userProfile = authState is Authenticated ? authState.profile : null;

    final serviceName = userProfile?.serviceType?.label ?? 'Ambulance Response';
    final isOnline = responderState.availabilityStatus == 'AVAILABLE';
    final statusText = responderState.availabilityStatus;

    // Start timer if dispatch arrives
    final activeDispatch = responderState.activeDispatch;
    if (activeDispatch != null && (_countdownTimer == null || !_countdownTimer!.isActive)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCountdown(activeDispatch['id'] as String);
      });
    } else if (activeDispatch == null && _countdownTimer != null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }

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
        child: responderState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status availability card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isOnline ? Colors.green.shade50 : (statusText == 'EN_ROUTE' ? Colors.orange.shade50 : Colors.grey.shade100),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline ? Colors.green : (statusText == 'EN_ROUTE' ? Colors.orange : Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusText == 'EN_ROUTE' ? 'RESPONDING TO DISPATCH' : (isOnline ? 'AVAILABLE FOR DISPATCH' : 'OFFLINE / BUSY'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isOnline ? Colors.green.shade900 : (statusText == 'EN_ROUTE' ? Colors.orange.shade900 : Colors.grey.shade800),
                                    ),
                                  ),
                                  Text(
                                    statusText == 'EN_ROUTE'
                                        ? 'Navigate to emergency location'
                                        : (isOnline ? 'Receiving emergency requests' : 'Tap switch to go online'),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            if (statusText != 'EN_ROUTE')
                              Switch.adaptive(
                                value: isOnline,
                                activeColor: Colors.green,
                                onChanged: (val) {
                                  ref.read(responderControllerProvider.notifier).toggleAvailability(val);
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
                            value: statusText == 'EN_ROUTE' ? '1' : '0',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dispatch Alert Card Section
                    if (activeDispatch != null) ...[
                      Text(
                        'Incoming Emergency Request (प्रतिक्रिया आवश्यक)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                                    child: Text(
                                      '${activeDispatch['emergency_requests']?['severity'] ?? 'CRITICAL'}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$_secondsRemaining s left',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${activeDispatch['emergency_requests']?['emergency_type'] ?? 'Emergency Request'}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${activeDispatch['emergency_requests']?['address'] ?? 'Active Location'} (${activeDispatch['distance_km'] ?? '0.0'} km away)',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _countdownTimer?.cancel();
                                        ref.read(responderControllerProvider.notifier).rejectDispatch(activeDispatch['id'] as String);
                                      },
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
                                      onPressed: () {
                                        _countdownTimer?.cancel();
                                        ref.read(responderControllerProvider.notifier).acceptDispatch(
                                              activeDispatch['id'] as String,
                                              activeDispatch['emergency_requests']['id'] as String,
                                            );
                                      },
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
                    ] else ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'No active dispatch incoming currently.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
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

