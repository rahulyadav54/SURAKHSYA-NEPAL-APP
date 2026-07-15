import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Dark Theme Emergency Red Glow)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A080A), // Deep Red
                  Color(0xFF121212), // Black
                ],
              ),
            ),
          ),
          
          // Central Branding Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Pulse Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.12),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15), duration: 1.5.seconds, curve: Curves.easeInOut),
                    
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.security_rounded,
                              color: Colors.red,
                              size: 60,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
                
                const SizedBox(height: 36),
                
                // Animated App Name
                Text(
                  'सुरक्षा नेपाल',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 10),
                
                // Animated Subtext
                Text(
                  'Unified AI Emergency Response Platform',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                )
                .animate()
                .fadeIn(delay: 750.ms, duration: 600.ms),
              ],
            ),
          ),
          
          // Bottom loading Indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading system elements...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 1.2.seconds, duration: 500.ms),
        ],
      ),
    );
  }
}
