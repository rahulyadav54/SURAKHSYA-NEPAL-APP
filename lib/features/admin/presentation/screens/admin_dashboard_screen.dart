import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Overview', 'icon': Icons.dashboard_rounded},
    {'title': 'Emergency Reports', 'icon': Icons.emergency_rounded},
    {'title': 'Users List', 'icon': Icons.people_rounded},
    {'title': 'Hospitals Info', 'icon': Icons.local_hospital_rounded},
    {'title': 'Responders Control', 'icon': Icons.local_shipping_rounded},
    {'title': 'AI Analytics', 'icon': Icons.analytics_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suraksha Nepal - Admin Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.go('/home');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            NavigationRail(
              selectedIndex: _selectedTab,
              onDestinationSelected: (idx) {
                setState(() {
                  _selectedTab = idx;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: _tabs.map((tab) {
                return NavigationRailDestination(
                  icon: Icon(tab['icon'] as IconData),
                  label: Text(tab['title'] as String),
                );
              }).toList(),
            )
          else
            const SizedBox.shrink(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildSelectedTabContent(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isLargeScreen
          ? BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: (idx) {
                setState(() {
                  _selectedTab = idx;
                });
              },
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.colorScheme.outline,
              items: _tabs.map((tab) {
                return BottomNavigationBarItem(
                  icon: Icon(tab['icon'] as IconData),
                  label: tab['title'] as String,
                );
              }).toList(),
            )
          : null,
    );
  }

  Widget _buildSelectedTabContent(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(context);
      case 1:
        return _buildEmergencyTab(context);
      case 2:
        return _buildUsersTab(context);
      case 3:
        return _buildHospitalsTab(context);
      case 4:
        return _buildRespondersTab(context);
      case 5:
        return _buildAnalyticsTab(context);
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final emergenciesAsync = ref.watch(adminEmergenciesProvider);
    final usersAsync = ref.watch(adminProfilesProvider);
    final hospitalsAsync = ref.watch(adminHospitalsProvider);
    final respondersAsync = ref.watch(adminAmbulancesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Command Center Statistics',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 1000 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                context,
                title: 'Active SOS Alerts',
                value: emergenciesAsync.when(data: (list) => '${list.where((e) => e.status != 'RESOLVED').length}', loading: () => '...', error: (_, __) => 'Error'),
                icon: Icons.notifications_active_rounded,
                color: Colors.red,
              ),
              _buildStatCard(
                context,
                title: 'Total Citizens',
                value: usersAsync.when(data: (list) => '${list.length}', loading: () => '...', error: (_, __) => 'Error'),
                icon: Icons.people_rounded,
                color: Colors.blue,
              ),
              _buildStatCard(
                context,
                title: 'Beds Available',
                value: hospitalsAsync.when(data: (list) => '${list.fold(0, (sum, h) => sum + h.emergencyBedsAvailable)}', loading: () => '...', error: (_, __) => 'Error'),
                icon: Icons.bed_rounded,
                color: Colors.green,
              ),
              _buildStatCard(
                context,
                title: 'Ambulances Duty',
                value: respondersAsync.when(data: (list) => '${list.length}', loading: () => '...', error: (_, __) => 'Error'),
                icon: Icons.local_shipping_rounded,
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTab(BuildContext context) {
    final theme = Theme.of(context);
    final emergenciesAsync = ref.watch(adminEmergenciesProvider);
    final controller = ref.read(adminControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Active SOS Incidents',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: emergenciesAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('No active incidents reported.'));
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final ev = list[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('SOS Event - ${ev.status}'),
                      subtitle: Text('Location: (${ev.latitude}, ${ev.longitude})'),
                      trailing: DropdownButton<String>(
                        value: ev.status,
                        items: ['PENDING', 'ACTIVE', 'RESOLVED'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            controller.updateEmergencyStatus(ev.id, newStatus);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SurakshaLoading(size: 40),
            error: (err, _) => SurakshaErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(adminEmergenciesProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(adminProfilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Registered Users',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: usersAsync.when(
            data: (list) {
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final user = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.fullName),
                      subtitle: Text('Phone: ${user.phone} | Blood Group: ${user.bloodGroup}'),
                    ),
                  );
                },
              );
            },
            loading: () => const SurakshaLoading(size: 40),
            error: (err, _) => SurakshaErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(adminProfilesProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalsTab(BuildContext context) {
    final theme = Theme.of(context);
    final hospitalsAsync = ref.watch(adminHospitalsProvider);
    final controller = ref.read(adminControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hospitals Capacity',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: hospitalsAsync.when(
            data: (list) {
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final h = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(h.name),
                      subtitle: Text('${h.emergencyBedsAvailable} beds available of ${h.emergencyBedsTotal} total'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: h.emergencyBedsAvailable > 0
                                ? () => controller.updateHospitalBeds(h.id, h.emergencyBedsAvailable - 1)
                                : null,
                          ),
                          Text('${h.emergencyBedsAvailable}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: h.emergencyBedsAvailable < h.emergencyBedsTotal
                                ? () => controller.updateHospitalBeds(h.id, h.emergencyBedsAvailable + 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SurakshaLoading(size: 40),
            error: (err, _) => SurakshaErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(adminHospitalsProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildRespondersTab(BuildContext context) {
    final theme = Theme.of(context);
    final respondersAsync = ref.watch(adminAmbulancesProvider);
    final controller = ref.read(adminControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Emergency Responders Status',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: respondersAsync.when(
            data: (list) {
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final a = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(a.driverName),
                      subtitle: Text('Plate: ${a.licensePlate} | Phone: ${a.phone}'),
                      trailing: DropdownButton<String>(
                        value: a.status,
                        items: ['AVAILABLE', 'BUSY', 'OFFLINE'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            controller.updateAmbulanceStatus(a.id, newStatus);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SurakshaLoading(size: 40),
            error: (err, _) => SurakshaErrorWidget(message: err.toString(), onRetry: () => ref.invalidate(adminAmbulancesProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    final theme = Theme.of(context);
    final predictionAsync = ref.watch(adminAnalyticsPredictionProvider);

    final LatLng ktmCenter = const LatLng(27.7172, 85.3240);
    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('high_density_1'),
        center: const LatLng(27.7052, 85.3150),
        radius: 600,
        fillColor: Colors.red.withValues(alpha: 0.35),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ),
      Circle(
        circleId: const CircleId('high_density_2'),
        center: const LatLng(27.7290, 85.3205),
        radius: 400,
        fillColor: Colors.orange.withValues(alpha: 0.35),
        strokeColor: Colors.orange,
        strokeWidth: 2,
      ),
      Circle(
        circleId: const CircleId('high_density_3'),
        center: const LatLng(27.6830, 85.3190),
        radius: 500,
        fillColor: Colors.red.withValues(alpha: 0.30),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ),
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AI Incident Analytics & Predictions',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Text(
            'Incident Density Heatmap (सघनता नक्शा)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: ktmCenter,
                  zoom: 12.5,
                ),
                circles: circles,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),

          const SizedBox(height: 28),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Emergency Trends',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    const FlSpot(0, 5),
                                    const FlSpot(1, 8),
                                    const FlSpot(2, 4),
                                    const FlSpot(3, 12),
                                    const FlSpot(4, 7),
                                    const FlSpot(5, 15),
                                  ],
                                  isCurved: true,
                                  color: theme.colorScheme.primary,
                                  barWidth: 4,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incidents Category Ratio',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 12, color: Colors.blue, width: 14)]),
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: Colors.red, width: 14)]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5, color: Colors.orange, width: 14)]),
                                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.teal, width: 14)]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Gemini Safety Predictions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  predictionAsync.when(
                    data: (forecast) => Text(
                      forecast,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                    error: (err, _) => Text(
                      'AI prediction currently unavailable: ${err.toString()}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.summarize_rounded, size: 28, color: theme.colorScheme.outline),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Monthly Summary Report',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compile response ratios, bed occupancy cycles, and incidents logs.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Compiling Report details for export...')),
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export PDF'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
