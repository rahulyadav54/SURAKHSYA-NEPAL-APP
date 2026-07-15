import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/profile_creation_screen.dart';
import '../../features/emergency/presentation/screens/emergency_history_screen.dart';
import '../../features/emergency/presentation/screens/home_shell.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/ambulance/presentation/screens/ambulance_request_screen.dart';
import '../../features/ambulance/presentation/screens/ambulance_tracking_screen.dart';
import '../../features/fire/presentation/screens/fire_report_screen.dart';
import '../../features/fire/presentation/screens/fire_tracking_screen.dart';
import '../../features/police/presentation/screens/police_report_screen.dart';
import '../../features/police/presentation/screens/police_tracking_screen.dart';
import '../../features/hospital/domain/entities/hospital.dart';
import '../../features/hospital/presentation/screens/hospital_list_screen.dart';
import '../../features/hospital/presentation/screens/hospital_details_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp-verify',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpVerificationScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/create-profile',
      builder: (context, state) => const ProfileCreationScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeShell(),
    ),
    GoRoute(
      path: '/emergency-history',
      builder: (context, state) => const EmergencyHistoryScreen(),
    ),
    GoRoute(
      path: '/ambulance-request',
      builder: (context, state) => const AmbulanceRequestScreen(),
    ),
    GoRoute(
      path: '/ambulance-tracking',
      builder: (context, state) {
        final requestId = state.extra as String? ?? '';
        return AmbulanceTrackingScreen(requestId: requestId);
      },
    ),
    GoRoute(
      path: '/fire-report',
      builder: (context, state) => const FireReportScreen(),
    ),
    GoRoute(
      path: '/fire-tracking',
      builder: (context, state) {
        final reportId = state.extra as String? ?? '';
        return FireTrackingScreen(reportId: reportId);
      },
    ),
    GoRoute(
      path: '/police-report',
      builder: (context, state) => const PoliceReportScreen(),
    ),
    GoRoute(
      path: '/police-tracking',
      builder: (context, state) {
        final reportId = state.extra as String? ?? '';
        return PoliceTrackingScreen(reportId: reportId);
      },
    ),
    GoRoute(
      path: '/hospital-list',
      builder: (context, state) => const HospitalListScreen(),
    ),
    GoRoute(
      path: '/hospital-details',
      builder: (context, state) {
        final hospital = state.extra as Hospital;
        return HospitalDetailsScreen(hospital: hospital);
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
