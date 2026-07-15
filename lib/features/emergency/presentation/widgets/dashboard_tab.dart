import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Retrieve name and blood group from current session profile
    String userName = 'User';
    String bloodGroup = 'O+';
    if (authState is Authenticated) {
      userName = authState.profile.fullName;
      bloodGroup = authState.profile.bloodGroup;
    }

    final categories = [
      {'name': 'Ambulance', 'icon': Icons.local_hospital_rounded, 'color': Colors.red, 'labelNp': 'एम्बुलेन्स'},
      {'name': 'Police', 'icon': Icons.local_police_rounded, 'color': Colors.blue, 'labelNp': 'प्रहरी'},
      {'name': 'Fire Brigade', 'icon': Icons.fire_truck_rounded, 'color': Colors.orange, 'labelNp': 'दमकल'},
      {'name': 'Disaster', 'icon': Icons.warning_amber_rounded, 'color': Colors.amber, 'labelNp': 'विपद् व्यवस्थापन'},
      {'name': 'Blood Bank', 'icon': Icons.bloodtype_rounded, 'color': Colors.redAccent, 'labelNp': 'रक्तदान'},
      {'name': 'Hospitals', 'icon': Icons.business_rounded, 'color': Colors.teal, 'labelNp': 'अस्पतालहरू'},
    ];

    final alerts = [
      {
        'title': 'भारी वर्षा र बाढीको चेतावनी (Koshi Flood Alert)',
        'description': 'Water levels in Koshi River rising rapidly. Residents near riverbanks remain alert.',
        'time': '10 mins ago',
        'severity': 'HIGH',
      },
      {
        'title': 'पहिरोको जोखिम (Syangja Landslide Alert)',
        'description': 'High landslide risk reported in hilly region routes of Syangja. Avoid travel.',
        'time': '1 hr ago',
        'severity': 'MEDIUM',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SURAKSHA NEPAL'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Medical Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'नमस्ते (Hello),',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Medical Indicator Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bloodtype_rounded, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$bloodGroup Blood Group',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),
              
              const SizedBox(height: 28),
              
              // Emergency Help Banner
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Urgent Response?',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Press the SOS button below for 3 seconds to trigger immediate broadcast signals.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
              
              const SizedBox(height: 28),
              
              // Categories Section Title
              Text(
                'Emergency Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Categories Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Semantics(
                    label: '${cat['name']} emergency dispatch button',
                    button: true,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (cat['name'] == 'Ambulance') {
                            context.push('/ambulance-request');
                          } else if (cat['name'] == 'Fire Brigade') {
                            context.push('/fire-report');
                          } else if (cat['name'] == 'Police') {
                            context.push('/police-report');
                          } else if (cat['name'] == 'Hospitals') {
                            context.push('/hospital-list');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${cat['name']} Category UI only')),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (cat['color'] as Color).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat['icon'] as IconData,
                                  color: cat['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat['labelNp'] as String,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                cat['name'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              
              const SizedBox(height: 28),
              
              // Active Alerts Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Emergency Alerts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Alerts List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final isHigh = alert['severity'] == 'HIGH';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isHigh 
                            ? theme.colorScheme.error.withValues(alpha: 0.2) 
                            : theme.colorScheme.tertiary.withValues(alpha: 0.2),
                      ),
                    ),
                    color: isHigh 
                        ? theme.colorScheme.errorContainer.withValues(alpha: 0.05) 
                        : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.05),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        isHigh ? Icons.warning_rounded : Icons.info_outline_rounded,
                        color: isHigh ? theme.colorScheme.error : theme.colorScheme.tertiary,
                        size: 28,
                      ),
                      title: Text(
                        alert['title'] as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            alert['description'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                alert['time'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 450.ms, duration: 600.ms),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
