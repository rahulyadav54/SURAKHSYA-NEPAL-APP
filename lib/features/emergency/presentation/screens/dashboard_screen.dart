import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // List of emergency services
    final services = [
      {'name': 'Ambulance', 'icon': Icons.local_hospital_rounded, 'color': Colors.red},
      {'name': 'Police', 'icon': Icons.local_police_rounded, 'color': Colors.blue},
      {'name': 'Fire Brigade', 'icon': Icons.fire_truck_rounded, 'color': Colors.orange},
      {'name': 'Disaster Response', 'icon': Icons.warning_amber_rounded, 'color': Colors.amber},
      {'name': 'Blood Bank', 'icon': Icons.bloodtype_rounded, 'color': Colors.redAccent},
      {'name': 'Hospital', 'icon': Icons.business_rounded, 'color': Colors.teal},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SURAKSHA NEPAL',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kathmandu, Nepal',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('View Map'),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 28),
              
              // Pulsating SOS Trigger Button
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple rings
                        ...List.generate(2, (index) {
                          return Container(
                            width: 180 + (index * 40),
                            height: 180 + (index * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.error.withValues(alpha: 0.15),
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.3, 1.3),
                            duration: 1.8.seconds,
                            curve: Curves.easeOut,
                          )
                          .fadeOut(duration: 1.8.seconds);
                        }),
                        
                        // Main Core SOS Button
                        GestureDetector(
                          onLongPress: () {
                            // SOS trigger sequence
                          },
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.error,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SOS',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Long press to trigger emergency response',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),

              const SizedBox(height: 32),

              // Categories Grid Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Response Services',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Grid of Services
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (service['color'] as Color).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              service['icon'] as IconData,
                              color: service['color'] as Color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service['name'] as String,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              
              const SizedBox(height: 24),
              
              // AI Assistant Card
              Card(
                elevation: 0,
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Rescue Guide',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Instant first-aid guidelines & disaster instructions.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.tertiary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
