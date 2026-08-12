import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/emergency_controller.dart';

class ActivityLogItem {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'ambulance', 'fire', 'police', 'sos', 'ai_chat'
  final String status; // 'RESOLVED', 'ACTIVE', 'CANCELLED', 'PENDING'
  final DateTime createdAt;
  final String description;

  ActivityLogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.description,
  });
}

final activityLogProvider = FutureProvider.autoDispose<List<ActivityLogItem>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid ?? 'anonymous';

  List<ActivityLogItem> items = [];

  // Mock static entries matching mockups
  items.add(ActivityLogItem(
    id: 'mock_consult',
    title: 'First Aid Consultation',
    subtitle: 'Chat regarding burn treatment instructions.',
    type: 'ai_chat',
    status: 'ACTIVE',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    description: 'User initiated an AI chat consultation requesting guidance on immediate first aid steps for a second-degree burn on the hand.',
  ));

  items.add(ActivityLogItem(
    id: 'mock_fire',
    title: 'Fire Incident Report',
    subtitle: 'False alarm reported near Thamel district.',
    type: 'fire',
    status: 'CANCELLED',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    description: 'Fire dispatch reported a false alarm at the specified coordinate. Incident resolved with no injuries or property damage.',
  ));

  items.add(ActivityLogItem(
    id: 'mock_sus',
    title: 'Suspicious Activity',
    subtitle: 'Report filed for suspicious vehicle. Patrol dispatched.',
    type: 'police',
    status: 'RESOLVED',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    description: 'Citizens reported a suspicious vehicle idling near the residential boundary. Police patrol dispatched to investigate, vehicle cleared from site.',
  ));

  try {
    // 1. Fetch emergencies (SOS alerts)
    final sosSnap = await firestore.collection('emergencies')
        .where('user_id', isEqualTo: userId)
        .get();
    for (final doc in sosSnap.docs) {
      final data = doc.data();
      items.add(ActivityLogItem(
        id: doc.id,
        title: 'Emergency SOS Broadcast',
        subtitle: 'Lat: ${data['latitude']}, Long: ${data['longitude']}',
        type: 'sos',
        status: data['status'] ?? 'PENDING',
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        description: 'User triggered an SOS alert broadcasting active GPS coordinates to all nearest dispatch hubs and emergency contacts.',
      ));
    }

    // 2. Fetch ambulance requests
    final ambSnap = await firestore.collection('ambulance_requests')
        .where('user_id', isEqualTo: userId)
        .get();
    for (final doc in ambSnap.docs) {
      final data = doc.data();
      items.add(ActivityLogItem(
        id: doc.id,
        title: 'Ambulance Request',
        subtitle: 'Severity: ${data['patient_status'] ?? 'STABLE'}',
        type: 'ambulance',
        status: (data['status'] ?? 'pending').toUpperCase(),
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        description: 'An ambulance request was filed. Current dispatch state: ${data['status']}. Coordinates: Lat: ${data['pickup_latitude']}, Long: ${data['pickup_longitude']}.',
      ));
    }

    // 3. Fetch fire reports
    final fireSnap = await firestore.collection('fire_reports')
        .where('user_id', isEqualTo: userId)
        .get();
    for (final doc in fireSnap.docs) {
      final data = doc.data();
      items.add(ActivityLogItem(
        id: doc.id,
        title: 'Fire Incident Report',
        subtitle: 'AI Severity: ${data['ai_severity'] ?? 'MEDIUM'}',
        type: 'fire',
        status: (data['status'] ?? 'pending').toUpperCase(),
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        description: 'Incident Description: ${data['description'] ?? ''}. AI predicted severity level: ${data['ai_severity']}.',
      ));
    }

    // 4. Fetch police reports
    final policeSnap = await firestore.collection('police_reports')
        .where('user_id', isEqualTo: userId)
        .get();
    for (final doc in policeSnap.docs) {
      final data = doc.data();
      items.add(ActivityLogItem(
        id: doc.id,
        title: 'Suspicious Activity',
        subtitle: 'Category: ${data['category'] ?? 'Other'}',
        type: 'police',
        status: (data['status'] ?? 'pending').toUpperCase(),
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        description: 'Incident Details: ${data['description'] ?? ''}. Category classified: ${data['category']}.',
      ));
    }
  } catch (e) {
    debugPrint('Firestore fetch error in activity log: $e');
  }

  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

class EmergencyHistoryScreen extends ConsumerStatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  ConsumerState<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends ConsumerState<EmergencyHistoryScreen> {
  int _activeFilterIndex = 0; // 0: All, 1: Emergencies, 2: AI Chats

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(activityLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Activity Log'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activityLogProvider);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Log',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review your past emergencies, reports, and AI interactions.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    _filterChip(0, 'All Activity'),
                    const SizedBox(width: 8),
                    _filterChip(1, 'Emergencies'),
                    const SizedBox(width: 8),
                    _filterChip(2, 'AI Chats'),
                  ],
                ),
              ),

              // Activity Feed List
              Expanded(
                child: historyAsync.when(
                  data: (items) {
                    final filteredItems = items.where((item) {
                      if (_activeFilterIndex == 1) {
                        return item.type != 'ai_chat';
                      } else if (_activeFilterIndex == 2) {
                        return item.type == 'ai_chat';
                      }
                      return true;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.colorScheme.outline),
                                const SizedBox(height: 12),
                                const Text('No activities found in this filter.'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildActivityCard(context, item, index);
                      },
                    );
                  },
                  loading: () => const Center(child: SurakshaLoading()),
                  error: (err, stack) => SurakshaErrorWidget(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(activityLogProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _activeFilterIndex == index;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _activeFilterIndex = index;
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

  Widget _buildActivityCard(BuildContext context, ActivityLogItem item, int index) {
    final theme = Theme.of(context);
    
    // Setup type configuration
    IconData iconData = Icons.emergency_rounded;
    Color typeColor = Colors.red.shade700;
    if (item.type == 'ambulance') {
      iconData = Icons.local_hospital_rounded;
      typeColor = Colors.red.shade600;
    } else if (item.type == 'fire') {
      iconData = Icons.local_fire_department_rounded;
      typeColor = Colors.orange.shade700;
    } else if (item.type == 'police') {
      iconData = Icons.local_police_rounded;
      typeColor = Colors.blue.shade700;
    } else if (item.type == 'ai_chat') {
      iconData = Icons.smart_toy_rounded;
      typeColor = Colors.teal.shade700;
    }

    final isResolved = item.status == 'RESOLVED' || item.status == 'SUCCESS';
    final isCancelled = item.status == 'CANCELLED';
    final statusColor = isCancelled 
        ? Colors.grey.shade600 
        : (isResolved ? Colors.green : Colors.red.shade700);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Icon, Title, Status)
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
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Subtitle Description
            Text(
              item.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            
            const SizedBox(height: 16),
            
            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.type == 'ai_chat') ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(homeTabIndexProvider.notifier).state = 2; // Switch to Assistant tab
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Resume Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () {
                      _showDetailsDialog(context, item);
                    },
                    child: Text(isCancelled ? 'Details' : 'View Summary'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  void _showDetailsDialog(BuildContext context, ActivityLogItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Status', item.status),
                _detailRow('Date & Time', _formatDateTime(item.createdAt)),
                _detailRow('Quick Info', item.subtitle),
                const SizedBox(height: 12),
                const Text('Full Log Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(item.description, style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final year = dt.year;
    final month = months[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $year • $hour:$min';
  }
}
