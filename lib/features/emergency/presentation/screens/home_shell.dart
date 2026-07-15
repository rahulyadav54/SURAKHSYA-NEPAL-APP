import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/emergency_controller.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/map_tab.dart';
import '../widgets/ai_guide_tab.dart';
import '../widgets/profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardTab(),
    MapTab(),
    AiGuideTab(),
    ProfileTab(),
  ];

  void _showSosConfirmation() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SosCountdownModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSosConfirmation,
        backgroundColor: theme.colorScheme.error,
        shape: const CircleBorder(),
        elevation: 6,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 32,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home_rounded,
                      color: _currentIndex == 0 ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    onPressed: () => setState(() => _currentIndex = 0),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    icon: Icon(
                      Icons.map_rounded,
                      color: _currentIndex == 1 ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    onPressed: () => setState(() => _currentIndex = 1),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.psychology_rounded,
                      color: _currentIndex == 2 ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    onPressed: () => setState(() => _currentIndex = 2),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    icon: Icon(
                      Icons.person_rounded,
                      color: _currentIndex == 3 ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    onPressed: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SosCountdownModal extends ConsumerStatefulWidget {
  const SosCountdownModal({super.key});

  @override
  ConsumerState<SosCountdownModal> createState() => _SosCountdownModalState();
}

class _SosCountdownModalState extends ConsumerState<SosCountdownModal> {
  int _secondsLeft = 3;
  Timer? _timer;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _triggerEmergencyAlert();
      }
    });
  }

  Future<void> _triggerEmergencyAlert() async {
    setState(() {
      _isConnecting = true;
    });

    final success = await ref.read(emergencyControllerProvider.notifier).triggerSosAlert();
    
    if (mounted) {
      Navigator.pop(context); // Close bottom sheet
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ SOS आपतकालीन प्रतिक्रिया सक्रिय भयो! (Emergency Response Triggered!)'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error triggering SOS alert. Check your network connection.'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            _isConnecting ? 'सम्पर्क स्थापित गर्दै...' : 'SOS आपतकाल सक्रिय गर्दै...',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnecting 
                ? 'Securing GPS coordinates and establishing connection with emergency responders...'
                : 'Distress signal will be sent to authorities and emergency contacts in:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          
          if (_isConnecting) ...[
            const Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            ),
          ] else ...[
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.error.withValues(alpha: 0.15),
                    ),
                  )
                  .animate(key: ValueKey(_secondsLeft))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 800.ms, curve: Curves.easeOut)
                  .fadeOut(duration: 800.ms),
                  
                  Text(
                    '$_secondsLeft',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 28),
          
          // Cancel Button
          OutlinedButton(
            onPressed: _isConnecting 
                ? null 
                : () {
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('CANCEL (रद्द गर्नुहोस्)'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
