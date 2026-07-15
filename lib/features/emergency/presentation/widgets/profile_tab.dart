import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    String name = 'User';
    String email = 'user@surakshanepal.com';
    String phone = '+977 9800000000';
    String bloodGroup = 'O+';
    String allergies = 'Penicillin';
    String notes = 'Asthma patient';
    String contact1 = '9801234567';
    String contact2 = '9841234567';

    if (authState is Authenticated) {
      final p = authState.profile;
      name = p.fullName;
      email = p.email.isNotEmpty ? p.email : 'No email added';
      phone = p.phone.isNotEmpty ? p.phone : 'No phone added';
      bloodGroup = p.bloodGroup;
      allergies = p.allergies.isNotEmpty ? p.allergies : 'None';
      notes = p.medicalNotes.isNotEmpty ? p.medicalNotes : 'None';
      contact1 = p.emergencyContact1;
      contact2 = p.emergencyContact2.isNotEmpty ? p.emergencyContact2 : 'None';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE DETAILS'),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar & Basic Info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 32),

              // Medical Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_information_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'स्वास्थ्य विवरण (Medical Summary)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildProfileInfoRow(context, 'रक्त समूह (Blood Group)', bloodGroup, isHighlighted: true),
                      _buildProfileInfoRow(context, 'एलर्जी (Allergies)', allergies),
                      _buildProfileInfoRow(context, 'चिकित्सा टिपोट (Medical Notes)', notes),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

              const SizedBox(height: 20),

              // Contacts Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.contact_phone_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'आपतकालीन सम्पर्क (Emergency Contacts)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildProfileInfoRow(context, 'प्राथमिक सम्पर्क (Primary Contact)', contact1),
                      _buildProfileInfoRow(context, 'द्वितियक सम्पर्क (Secondary Contact)', contact2),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

              // Emergency History Log
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Emergency SOS Log'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  context.push('/emergency-history');
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 12),

              // Admin Portal Link
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Dashboard Portal'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  context.push('/admin');
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ).animate().fadeIn(delay: 420.ms, duration: 500.ms),

              const SizedBox(height: 12),

              // Theme Configuration Toggle
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Theme Mode'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (val) {
                    // Toggles system theme
                  },
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(BuildContext context, String label, String value, {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w500,
              color: isHighlighted ? theme.colorScheme.error : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
