import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../controllers/admin_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../ambulance/domain/entities/ambulance.dart';

class AdminEmergencyItem {
  final String id;
  final String userId;
  final String type; // 'sos', 'ambulance', 'fire', 'police'
  final String status;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String details;
  final String severity; // e.g. HIGH, CRITICAL

  AdminEmergencyItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.details,
    required this.severity,
  });
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;
  int _emergencyFilterIndex = 0; // 0: All, 1: SOS, 2: Ambulance, 3: Fire, 4: Police

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
    final ambulanceReqsAsync = ref.watch(adminAmbulanceReqsProvider);
    final fireReportsAsync = ref.watch(adminFireReportsProvider);
    final policeReportsAsync = ref.watch(adminPoliceReportsProvider);
    final profilesAsync = ref.watch(adminProfilesProvider);
    final ambulancesAsync = ref.watch(adminAmbulancesProvider);
    final controller = ref.read(adminControllerProvider);

    // If any is loading, return loading spinner
    if (emergenciesAsync.isLoading ||
        ambulanceReqsAsync.isLoading ||
        fireReportsAsync.isLoading ||
        policeReportsAsync.isLoading ||
        profilesAsync.isLoading ||
        ambulancesAsync.isLoading) {
      return const Center(child: SurakshaLoading(size: 40));
    }

    final emergencies = emergenciesAsync.value ?? [];
    final ambulanceRequests = ambulanceReqsAsync.value ?? [];
    final fireReports = fireReportsAsync.value ?? [];
    final policeReports = policeReportsAsync.value ?? [];
    final profiles = profilesAsync.value ?? [];
    final ambulances = ambulancesAsync.value ?? [];

    List<AdminEmergencyItem> allItems = [];

    // Map SOS emergencies
    for (final e in emergencies) {
      allItems.add(AdminEmergencyItem(
        id: e.id,
        userId: e.userId,
        type: 'sos',
        status: e.status,
        latitude: e.latitude,
        longitude: e.longitude,
        createdAt: e.createdAt,
        details: 'SOS Alert triggered from device coordinates.',
        severity: 'CRITICAL',
      ));
    }

    // Map Ambulance requests
    for (final a in ambulanceRequests) {
      allItems.add(AdminEmergencyItem(
        id: a.id,
        userId: a.userId,
        type: 'ambulance',
        status: a.status.toUpperCase(),
        latitude: a.pickupLatitude,
        longitude: a.pickupLongitude,
        createdAt: a.createdAt,
        details: 'Patient Status: ${a.patientStatus}',
        severity: a.patientStatus,
      ));
    }

    // Map Fire reports
    for (final f in fireReports) {
      allItems.add(AdminEmergencyItem(
        id: f.id,
        userId: f.userId,
        type: 'fire',
        status: f.status.toUpperCase(),
        latitude: f.latitude,
        longitude: f.longitude,
        createdAt: f.createdAt,
        details: f.description,
        severity: f.aiPredictedSeverity,
      ));
    }

    // Map Police reports
    for (final p in policeReports) {
      allItems.add(AdminEmergencyItem(
        id: p.id,
        userId: p.userId,
        type: 'police',
        status: p.status.toUpperCase(),
        latitude: p.latitude,
        longitude: p.longitude,
        createdAt: p.createdAt,
        details: 'Category: ${p.category}. Description: ${p.description}',
        severity: 'MEDIUM',
      ));
    }

    // Sort descending by date
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Filter based on selected category index
    final filteredItems = allItems.where((item) {
      if (_emergencyFilterIndex == 1) return item.type == 'sos';
      if (_emergencyFilterIndex == 2) return item.type == 'ambulance';
      if (_emergencyFilterIndex == 3) return item.type == 'fire';
      if (_emergencyFilterIndex == 4) return item.type == 'police';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency Dispatch & Controller Console',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(adminEmergenciesProvider);
                ref.invalidate(adminAmbulanceReqsProvider);
                ref.invalidate(adminFireReportsProvider);
                ref.invalidate(adminPoliceReportsProvider);
                ref.invalidate(adminProfilesProvider);
                ref.invalidate(adminAmbulancesProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(0, 'All Requests (${allItems.length})'),
              const SizedBox(width: 8),
              _filterChip(1, 'SOS Alerts (${allItems.where((i) => i.type == 'sos').length})'),
              const SizedBox(width: 8),
              _filterChip(2, 'Ambulance Requests (${allItems.where((i) => i.type == 'ambulance').length})'),
              const SizedBox(width: 8),
              _filterChip(3, 'Fire Reports (${allItems.where((i) => i.type == 'fire').length})'),
              const SizedBox(width: 8),
              _filterChip(4, 'Police Incident Reports (${allItems.where((i) => i.type == 'police').length})'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: filteredItems.isEmpty
              ? const Center(child: Text('No active incidents reported under this filter.'))
              : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    
                    // Retrieve citizen profile matching userId
                    UserProfile? citizen;
                    for (final p in profiles) {
                      if (p.id == item.userId) {
                        citizen = p;
                        break;
                      }
                    }

                    return _buildEmergencyIncidentCard(context, item, citizen, ambulances, controller);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmergencyIncidentCard(
    BuildContext context,
    AdminEmergencyItem item,
    UserProfile? citizen,
    List<Ambulance> ambulances,
    AdminController controller,
  ) {
    final theme = Theme.of(context);
    
    // Type styling configuration
    IconData iconData = Icons.emergency_rounded;
    Color typeColor = Colors.red;
    String typeLabel = 'SOS ALERT';
    if (item.type == 'ambulance') {
      iconData = Icons.local_hospital_rounded;
      typeColor = Colors.red.shade600;
      typeLabel = 'AMBULANCE REQUEST';
    } else if (item.type == 'fire') {
      iconData = Icons.local_fire_department_rounded;
      typeColor = Colors.orange.shade700;
      typeLabel = 'FIRE REPORT';
    } else if (item.type == 'police') {
      iconData = Icons.local_police_rounded;
      typeColor = Colors.blue.shade700;
      typeLabel = 'POLICE REPORT';
    }

    final isResolved = item.status == 'RESOLVED' || item.status == 'SUCCESS';
    final isCancelled = item.status == 'CANCELLED';
    final statusColor = isCancelled 
        ? Colors.grey 
        : (isResolved ? Colors.green : Colors.red.shade700);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Type Indicator and Status Dropdown
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: typeColor, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                    color: statusColor.withValues(alpha: 0.05),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ['PENDING', 'ACTIVE', 'RESOLVED', 'CANCELLED'].contains(item.status) ? item.status : 'PENDING',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      items: ['PENDING', 'ACTIVE', 'RESOLVED', 'CANCELLED'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          _updateStatus(controller, item, newStatus);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Citizen Profile Info
            Text(
              'CITIZEN PROFILE DETAILS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (citizen != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citizen.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(citizen.phone, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (citizen.bloodGroup.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop_rounded, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            citizen.bloodGroup,
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (citizen.allergies.isNotEmpty || citizen.medicalNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200, width: 0.5),
                  ),
                  child: Text(
                    'Allergies/Meds: ${citizen.allergies.isNotEmpty ? citizen.allergies : "None"} | Notes: ${citizen.medicalNotes.isNotEmpty ? citizen.medicalNotes : "None"}',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Guest Citizen (Profile Details Not Populated)',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),

            // Incident Details
            Text(
              'INCIDENT DETAILS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'GPS: (${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.details,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
            const Divider(height: 24),

            // Responder Dispatch Assignment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: item.status == 'RESOLVED' || item.status == 'CANCELLED'
                      ? Text(
                          'Incident Closed',
                          style: TextStyle(color: theme.colorScheme.outline, fontStyle: FontStyle.italic, fontSize: 12),
                        )
                      : Row(
                          children: [
                            const Text(
                              'Dispatched Unit: ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    hint: const Text('Assign Responder', style: TextStyle(fontSize: 11)),
                                    isExpanded: true,
                                    items: ambulances.map((amb) {
                                      return DropdownMenuItem(
                                        value: amb.id,
                                        child: Text(
                                          '${amb.driverName} (${amb.licensePlate})',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (ambId) {
                                      if (ambId != null) {
                                        final targetAmb = ambulances.firstWhere((a) => a.id == ambId);
                                        _dispatchResponder(context, controller, item, targetAmb);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _emergencyFilterIndex == index;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _emergencyFilterIndex = index;
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
    );
  }

  void _updateStatus(AdminController controller, AdminEmergencyItem item, String status) {
    if (item.type == 'sos') {
      controller.updateEmergencyStatus(item.id, status);
    } else if (item.type == 'ambulance') {
      controller.updateAmbulanceRequestStatus(item.id, status.toLowerCase());
    } else if (item.type == 'fire') {
      controller.updateFireReportStatus(item.id, status.toLowerCase());
    } else if (item.type == 'police') {
      controller.updatePoliceReportStatus(item.id, status.toLowerCase());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Incident status updated to $status.')),
    );
  }

  void _dispatchResponder(BuildContext context, AdminController controller, AdminEmergencyItem item, Ambulance amb) {
    _updateStatus(controller, item, 'ACTIVE');
    controller.updateAmbulanceStatus(amb.id, 'BUSY');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dispatched responder ${amb.driverName} (${amb.licensePlate}) successfully!'),
        backgroundColor: Colors.green.shade700,
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
