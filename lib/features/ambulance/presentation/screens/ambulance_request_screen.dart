import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/ambulance_controller.dart';

class AmbulanceRequestScreen extends ConsumerStatefulWidget {
  const AmbulanceRequestScreen({super.key});

  @override
  ConsumerState<AmbulanceRequestScreen> createState() => _AmbulanceRequestScreenState();
}

class _AmbulanceRequestScreenState extends ConsumerState<AmbulanceRequestScreen> {
  String? _selectedStatus;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'status': 'STABLE',
      'labelNp': 'सामान्य अवस्था (Stable)',
      'desc': 'Patient is conscious, breathing normally, and has stable vitals.',
      'color': Colors.green,
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'status': 'SEMI_CRITICAL',
      'labelNp': 'मध्यम अवस्था (Semi-Critical)',
      'desc': 'Patient needs immediate first aid support but is currently stable.',
      'color': Colors.orange,
      'icon': Icons.info_outline_rounded,
    },
    {
      'status': 'CRITICAL',
      'labelNp': 'गम्भीर अवस्था (Critical)',
      'desc': 'Severe injuries, unconsciousness, heavy bleeding, or breathing failures.',
      'color': Colors.red,
      'icon': Icons.warning_rounded,
    },
  ];

  Future<void> _submitRequest() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया बिरामीको अवस्था छनौट गर्नुहोस् (Please select patient status)')),
      );
      return;
    }

    final requestId = await ref.read(ambulanceControllerProvider.notifier).requestAmbulance(_selectedStatus!);
    
    if (requestId != null && mounted) {
      context.go('/ambulance-tracking', extra: requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nearbyAsync = ref.watch(nearbyAmbulancesProvider);
    final bookingState = ref.watch(ambulanceControllerProvider);

    ref.listen<AmbulanceBookingState>(ambulanceControllerProvider, (previous, next) {
      if (next is BookingError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    if (bookingState is BookingLoading) {
      return const Scaffold(
        body: SurakshaLoading(size: 60),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Dispatcher'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'बिरामीको अवस्था छनौट गर्नुहोस्\nSelect Patient Severity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Status Cards Selector
              ..._statusOptions.map((opt) {
                final isSelected = _selectedStatus == opt['status'];
                final color = opt['color'] as Color;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  color: isSelected 
                      ? color.withValues(alpha: 0.08) 
                      : theme.colorScheme.surface,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatus = opt['status'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(opt['icon'] as IconData, color: color, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['labelNp'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt['desc'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 20),
              
              // Nearby Ambulance stats
              Text(
                'Nearby Responders Info',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              nearbyAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Text(
                      'No available ambulances found nearby. The request will dispatch to the nearest dispatch station.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    );
                  }
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${list.length} ambulances are active and available in your area.',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error searching nearby: $err'),
              ),
              
              const SizedBox(height: 40),
              
              // Confirm Booking Button
              SurakshaButton(
                text: 'DISPATCH AMBULANCE NOW',
                icon: Icons.emergency_share_rounded,
                onPressed: _submitRequest,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
