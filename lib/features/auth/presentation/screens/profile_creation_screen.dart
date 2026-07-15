import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();
  final _contact1Controller = TextEditingController();
  final _contact2Controller = TextEditingController();
  
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).createUserProfile(
      fullName: _nameController.text.trim(),
      bloodGroup: _selectedBloodGroup ?? 'Unknown',
      allergies: _allergiesController.text.trim(),
      medicalNotes: _notesController.text.trim(),
      emergencyContact1: _contact1Controller.text.trim(),
      emergencyContact2: _contact2Controller.text.trim(),
    );
    
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('सम्पर्क र स्वास्थ्य प्रोफाइल (Profile Setup)'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header notice card
                Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_rounded, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Please provide accurate medical and contact details. This is used by response teams in an emergency.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Form Section Title
                Text(
                  'Personal Info',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Full Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Medical Info Title
                Text(
                  'Medical Information',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Blood Group Dropdown Selector
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _bloodGroups.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBloodGroup = val;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your blood group';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Allergies Input
                TextFormField(
                  controller: _allergiesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Allergies (Optional)',
                    prefixIcon: const Icon(Icons.warning_amber_rounded),
                    hintText: 'e.g., Penicillin, Peanuts, None',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Medical Notes Input
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Special Medical Notes (Optional)',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    hintText: 'e.g., Asthma patient, Diabetes, Heart condition',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Emergency Contact Section Title
                Text(
                  'Emergency Contacts',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Primary Contact Input
                TextFormField(
                  controller: _contact1Controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Primary Emergency Contact (Phone)',
                    prefixIcon: const Icon(Icons.contact_phone_outlined),
                    hintText: '98XXXXXXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Primary emergency contact is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Secondary Contact Input (Optional)
                TextFormField(
                  controller: _contact2Controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Secondary Emergency Contact (Optional)',
                    prefixIcon: const Icon(Icons.contact_phone_outlined),
                    hintText: '98XXXXXXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Action Button
                SurakshaButton(
                  text: 'Save and Continue',
                  isLoading: authState is AuthLoading,
                  onPressed: _submitProfile,
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
