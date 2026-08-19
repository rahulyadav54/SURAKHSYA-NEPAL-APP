import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/police_controller.dart';

import '../../../auth/domain/entities/user_role.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';

class PoliceReportScreen extends ConsumerStatefulWidget {
  const PoliceReportScreen({super.key});

  @override
  ConsumerState<PoliceReportScreen> createState() => _PoliceReportScreenState();
}

class _PoliceReportScreenState extends ConsumerState<PoliceReportScreen> {
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedCategory;
  XFile? _evidenceFile;
  int _peopleAffected = 1;

  final List<Map<String, dynamic>> _categories = [
    {'status': 'Theft', 'labelNp': 'Theft / Robbery', 'icon': Icons.lock_open_rounded, 'color': Colors.red},
    {'status': 'Assault', 'labelNp': 'Assault / Violence', 'icon': Icons.gavel_rounded, 'color': Colors.orange},
    {'status': 'Harassment', 'labelNp': 'Harassment / Abuse', 'icon': Icons.front_hand_rounded, 'color': Colors.blue},
    {'status': 'Accident', 'labelNp': 'Traffic Accident', 'icon': Icons.car_crash_rounded, 'color': Colors.teal},
    {'status': 'Other', 'labelNp': 'Other Incident Type', 'icon': Icons.emergency_rounded, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidence() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        setState(() {
          _evidenceFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error capturing evidence: $e');
    }
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select incident category')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the incident')),
      );
      return;
    }

    final reportId = await ref.read(emergencyControllerProvider.notifier).submitCustomEmergency(
      serviceType: ServiceType.police,
      emergencyType: _selectedCategory!,
      severity: 'HIGH',
      description: _descriptionController.text.trim(),
      address: '',
      localPhotoPath: _evidenceFile?.path,
      peopleAffected: _peopleAffected,
    );

    if (reportId != null && mounted) {
      context.go('/police-tracking', extra: reportId);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submissionState = ref.watch(policeControllerProvider);

    ref.listen<PoliceReportSubmissionState>(policeControllerProvider, (previous, next) {
      if (next is PoliceReportError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    if (submissionState is PoliceReportLoading) {
      return const Scaffold(
        body: SurakshaLoading(size: 60),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Police Dispatcher'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Incident Type',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              ..._categories.map((cat) {
                final isSelected = _selectedCategory == cat['status'];
                final color = cat['color'] as Color;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  color: isSelected ? color.withValues(alpha: 0.08) : theme.colorScheme.surface,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['status'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(cat['icon'] as IconData, color: color, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              cat['labelNp'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 24),

              Text(
                'Incident Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what happened, suspect description, any weapons, number of people involved...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Number of People Involved:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove),
                        onPressed: _peopleAffected > 1 ? () => setState(() => _peopleAffected--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('$_peopleAffected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _peopleAffected++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Upload Evidence File',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _captureEvidence,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: Text(_evidenceFile != null ? 'Evidence Attached' : 'Capture Photo / Video Evidence'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              if (_evidenceFile != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_evidenceFile!.path),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              
              const SizedBox(height: 40),

              SurakshaButton(
                text: 'DISPATCH EMERGENCY REPORT',
                icon: Icons.security_rounded,
                onPressed: _submitReport,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
