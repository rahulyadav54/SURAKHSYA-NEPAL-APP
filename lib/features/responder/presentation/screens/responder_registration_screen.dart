import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/repositories/responder_repository.dart';

class ResponderRegistrationScreen extends ConsumerStatefulWidget {
  const ResponderRegistrationScreen({super.key});

  @override
  ConsumerState<ResponderRegistrationScreen> createState() => _ResponderRegistrationScreenState();
}

class _ResponderRegistrationScreenState extends ConsumerState<ResponderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();

  ServiceType _selectedServiceType = ServiceType.ambulance;
  bool _isLoading = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _vehicleNumberController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(responderRepositoryProvider);
      await repository.registerResponder(
        firebaseUid: authState.profile.id,
        employeeId: _employeeIdController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        serviceType: _selectedServiceType,
      );

      // Force update of cached profile to reflect updated role
      await ref.read(authControllerProvider.notifier).switchRole(
            UserRole.responder,
            serviceType: _selectedServiceType,
          );

      if (mounted) {
        context.go('/responder-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('रेस्पोन्डर दर्ता (Responder Registration)'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info header card
                Card(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppTheme.primaryColor, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Please fill in your Official ID and vehicle details. Once submitted, your request is reviewed by the command center.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Service Type Dropdown
                DropdownButtonFormField<ServiceType>(
                  value: _selectedServiceType,
                  decoration: InputDecoration(
                    labelText: 'Service Category',
                    prefixIcon: const Icon(Icons.local_shipping_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ServiceType.values.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedServiceType = val;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Employee ID input
                TextFormField(
                  controller: _employeeIdController,
                  decoration: InputDecoration(
                    labelText: 'Official Employee ID / Badge Number',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Official Employee ID is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Vehicle Number
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Vehicle Plate Number',
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                    hintText: 'Ba 1 Jha 1234',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vehicle plate number is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Vehicle Type/Model
                TextFormField(
                  controller: _vehicleTypeController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Model & Specification',
                    prefixIcon: const Icon(Icons.info_outline),
                    hintText: 'Toyota Hiace Ambulance / Fire Engine Truck',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vehicle type is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                SurakshaButton(
                  text: 'Submit Registration Details',
                  isLoading: _isLoading,
                  onPressed: _submitRegistration,
                ),

                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
