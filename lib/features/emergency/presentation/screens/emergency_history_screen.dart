import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/emergency_controller.dart';

class EmergencyHistoryScreen extends ConsumerWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(emergencyHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS Log'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(emergencyHistoryProvider);
          },
          child: historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 72,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'कुनै आपतकालीन रेकर्डहरू फेला परेनन्', 
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your triggered emergency alerts will show up here.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final event = history[index];
                  final isPending = event.status == 'PENDING';
                  final isResolved = event.status == 'RESOLVED';

                  final statusColor = isPending
                      ? theme.colorScheme.error
                      : (isResolved ? Colors.green : Colors.orange);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top header (Status, Time)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isResolved ? Icons.check_circle_rounded : Icons.bolt_rounded,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDateTime(event.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Coordinates Row
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GPS Coordinates',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lat: ${event.latitude.toStringAsFixed(5)}, Long: ${event.longitude.toStringAsFixed(5)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Bottom info note
                          Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, size: 14, color: theme.colorScheme.outline),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'This SOS alert was broadcasted to response units in your area.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
                },
              );
            },
            loading: () => const SurakshaLoading(),
            error: (err, stack) => SurakshaErrorWidget(
              message: err.toString(),
              onRetry: () => ref.invalidate(emergencyHistoryProvider),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$min';
  }
}
