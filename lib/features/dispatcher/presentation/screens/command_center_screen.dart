import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monitor_heart_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('SURAKSHYA COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {},
            tooltip: 'Refresh Active Feeds',
          ),
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
                    break;
                  case UserRole.hospital:
                    context.go('/hospital-dashboard');
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
              const PopupMenuItem(value: UserRole.dispatcher, child: Text('Dispatcher Command Center (Active)')),
              const PopupMenuItem(value: UserRole.hospital, child: Text('Hospital Dashboard')),
              const PopupMenuItem(value: UserRole.admin, child: Text('Admin Portal')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Left panel: Active Emergencies
                  SizedBox(width: 320, child: _buildEmergenciesPanel(context)),
                  const VerticalDivider(width: 1),
                  // Middle: Live Map View
                  Expanded(child: _buildMapCenterPanel(context)),
                  const VerticalDivider(width: 1),
                  // Right panel: Resources Status
                  SizedBox(width: 280, child: _buildResourcesPanel(context)),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildResourcesPanel(context),
                    const SizedBox(height: 16),
                    SizedBox(height: 300, child: _buildMapCenterPanel(context)),
                    const SizedBox(height: 16),
                    _buildEmergenciesPanel(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmergenciesPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVE EMERGENCIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _buildEmergencyCard(
                  id: '#SN-10293',
                  type: 'Medical Emergency',
                  location: 'Lakeside, Pokhara',
                  severity: 'CRITICAL',
                  color: Colors.red,
                  time: '2 min ago',
                ),
                const SizedBox(height: 8),
                _buildEmergencyCard(
                  id: '#SN-10294',
                  type: 'House Fire Alert',
                  location: 'Koteshwor, Kathmandu',
                  severity: 'HIGH',
                  color: Colors.orange,
                  time: '5 min ago',
                ),
                const SizedBox(height: 8),
                _buildEmergencyCard(
                  id: '#SN-10295',
                  type: 'Traffic Accident',
                  location: 'Patan Durbar, Lalitpur',
                  severity: 'MEDIUM',
                  color: Colors.amber.shade800,
                  time: '12 min ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard({required String id, required String type, required String location, required String severity, required Color color, required String time}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(severity, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(location, style: const TextStyle(fontSize: 12, color: Colors.black70)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('DISPATCH', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCenterPanel(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Container(
            color: Colors.blueGrey.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 64, color: Colors.blueGrey),
                  SizedBox(height: 8),
                  Text('LIVE DISPATCH MAP FEED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  Text('Realtime PostGIS Responder Tracking', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESOURCES SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildResourceTile(icon: Icons.airport_shuttle_rounded, label: 'Ambulances Active', count: '18 / 22', color: Colors.red),
          _buildResourceTile(icon: Icons.local_police_rounded, label: 'Police Units Active', count: '24 / 30', color: Colors.blue),
          _buildResourceTile(icon: Icons.local_fire_department_rounded, label: 'Fire Units Active', count: '8 / 10', color: Colors.orange),
          _buildResourceTile(icon: Icons.local_hospital_rounded, label: 'Hospitals Connected', count: '12 / 12', color: Colors.teal),
        ],
      ),
    );
  }

  Widget _buildResourceTile({required IconData icon, required String label, required String count, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
