import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/constants.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load SharedPreferences for offline capabilities
  final prefs = await SharedPreferences.getInstance();

  // Global UI Error Boundary to prevent raw crash screen leaks in production
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red[900],
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 54),
              const SizedBox(height: 16),
              const Text(
                'तपाईंको सुरक्षामा समस्या आयो (An unexpected rendering issue occurred)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Safely initialize Firebase core services
  await FirebaseService.initialize();

  // Initialize Supabase with graceful fallback for development setup
  try {
    if (AppConstants.supabaseUrl != 'https://your-project.supabase.co' &&
        AppConstants.supabaseAnonKey != 'your-anon-key' &&
        !AppConstants.supabaseUrl.contains('your-project')) {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );
    } else {
      debugPrint('WARNING: Supabase placeholder credentials active. Please define target SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
  } catch (e) {
    debugPrint('ERROR: Failed to initialize Supabase: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const SurakshaNepalApp(),
    ),
  );
}

class SurakshaNepalApp extends ConsumerStatefulWidget {
  const SurakshaNepalApp({super.key});

  @override
  ConsumerState<SurakshaNepalApp> createState() => _SurakshaNepalAppState();
}

class _SurakshaNepalAppState extends ConsumerState<SurakshaNepalApp> {
  @override
  void initState() {
    super.initState();
    // Bootstrap Firebase FCM messaging event handlers
    ref.read(firebaseServiceProvider).setupNotificationListeners();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
