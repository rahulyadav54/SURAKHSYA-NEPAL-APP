import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../controllers/fire_controller.dart';

class FireReportScreen extends ConsumerStatefulWidget {
  const FireReportScreen({super.key});

  @override
  ConsumerState<FireReportScreen> createState() => _FireReportScreenState();
}

class _FireReportScreenState extends ConsumerState<FireReportScreen> {
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _imageFile;
  XFile? _videoFile;
  bool _isAnalyzing = false;
  String? _predictedSeverity;
  String? _analysisReason;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        setState(() {
          _imageFile = file;
          _predictedSeverity = null;
          _analysisReason = null;
        });
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _picker.pickVideo(source: ImageSource.camera);
      if (file != null) {
        setState(() {
          _videoFile = file;
          _predictedSeverity = null;
          _analysisReason = null;
        });
      }
    } catch (e) {
      debugPrint('Error capturing video: $e');
    }
  }

  Future<void> _runAiAnalysis() async {
    if (_descriptionController.text.trim().isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a description or image to run AI analysis.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final result = await ref.read(fireControllerProvider.notifier).analyzeSeverityWithAi(
      imagePath: _imageFile?.path,
      description: _descriptionController.text,
    );

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _predictedSeverity = result['severity'];
        _analysisReason = result['reason'];
      });
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया घटनाको विवरण प्रविष्ट गर्नुहोस् (Please describe the incident)')),
      );
      return;
    }

    if (_predictedSeverity == null) {
      await _runAiAnalysis();
    }

    final reportId = await ref.read(fireControllerProvider.notifier).submitFireReport(
      imagePath: _imageFile?.path,
      videoPath: _videoFile?.path,
      description: _descriptionController.text,
      aiSeverity: _predictedSeverity ?? 'MEDIUM',
    );

    if (reportId != null && mounted) {
      context.go('/fire-tracking', extra: reportId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submissionState = ref.watch(fireControllerProvider);

    ref.listen<FireReportSubmissionState>(fireControllerProvider, (previous, next) {
      if (next is FireReportError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    if (submissionState is FireReportLoading) {
      return const Scaffold(
        body: SurakshaLoading(size: 60),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Fire Incident'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'घटनाको विवरण (Incident Details)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the fire: scale, location details, potential hazards (e.g. gas leakage, nearby wires)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'मिडिया क्याप्चर (Attach Media Assets)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: Text(_imageFile != null ? 'Photo Attached' : 'Capture Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam_rounded),
                      label: Text(_videoFile != null ? 'Video Attached' : 'Capture Video'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

              if (_imageFile != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_imageFile!.path),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // AI Analyzer Card
              Card(
                elevation: 0,
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 10),
                          Text(
                            'Gemini AI Severity Analyzer',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_isAnalyzing) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                      ] else if (_predictedSeverity != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_predictedSeverity == 'HIGH' 
                                    ? Colors.red 
                                    : (_predictedSeverity == 'MEDIUM' ? Colors.orange : Colors.green))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _predictedSeverity!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _predictedSeverity == 'HIGH' 
                                      ? Colors.red 
                                      : (_predictedSeverity == 'MEDIUM' ? Colors.orange : Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _analysisReason ?? '',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Let AI inspect incident files and logs to predict gravity status before dispatching fire services.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _runAiAnalysis,
                          child: const Text('RUN AI INTENSITY ANALYSIS'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 36),

              SurakshaButton(
                text: 'TRANSMIT REPORT TO DISPATCH',
                icon: Icons.send_rounded,
                onPressed: _submitReport,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
