import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/repositories/responder_repository.dart';

class ResponderPendingScreen extends ConsumerStatefulWidget {
  const ResponderPendingScreen({super.key});

  @override
  ConsumerState<ResponderPendingScreen> createState() => _ResponderPendingScreenState();
}

class _ResponderPendingScreenState extends ConsumerState<ResponderPendingScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final repository = ref.read(responderRepositoryProvider);
      final statusMap = await repository.getResponderStatus(authState.profile.id);
      
      if (statusMap != null) {
        final verificationStatus = statusMap['verification_status'] as String?;
        if (verificationStatus == 'APPROVED' && mounted) {
          // Sync profile role and redirect to dashboard
          await ref.read(authControllerProvider.notifier).switchRole(UserRole.responder);
          context.go('/responder');
          return;
        } else if (verificationStatus == 'REJECTED' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your application was rejected. Please contact the administrator.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your application is still under review (समीक्षा अन्तर्गत).')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Animated style icon indicator
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade50,
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.orange,
                    size: 54,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'सत्यापन बाँकी छ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verification In Progress',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.orange),
              ),

              const SizedBox(height: 16),

              const Text(
                'Your credentials and emergency vehicle registration details have been submitted. The Command Center is currently verifying your profile to grant dispatch capabilities.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),

              const Spacer(),

              // Check Status Button
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Check Verification Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // Switch to Citizen View option
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/home');
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Switch to Citizen Dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // Sign Out option
              TextButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
