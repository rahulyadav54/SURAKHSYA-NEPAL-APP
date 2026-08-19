# Surakshya Nepal — Task Tracker

## Phase 1 — Database Schema + Supabase Config + RLS
- [x] Add `supabase_flutter: ^2.5.0` to pubspec.yaml
- [x] Create `lib/core/config/supabase_config.dart`
- [x] Create `lib/core/network/supabase_providers.dart`
- [x] Create `database/migrations/001_initial_schema.sql` (8 tables, enums, PostGIS, RLS)
- [x] Update `lib/main.dart` — Supabase.initialize()
- [x] Fix pre-existing `authControllerProvider` import in dashboard_tab.dart
- [x] flutter analyze — 0 errors
- [x] Push to GitHub
- [x] Run SQL migration in Supabase SQL Editor

## Phase 2 — Authentication + Role-Based Routing
- [x] Create UserRole & ServiceType domain entities (`lib/features/auth/domain/entities/user_role.dart`)
- [x] Update `UserProfile` entity & `UserProfileModel` with `role` and `service_type` parsing
- [x] Sync `profiles` table in Supabase (`getUserProfile`, `createUserProfile`, `updateUserProfile`)
- [x] Create Responder Dashboard screen (`lib/features/responder/presentation/screens/responder_dashboard_screen.dart`)
- [x] Create Dispatcher Command Center screen (`lib/features/dispatcher/presentation/screens/command_center_screen.dart`)
- [x] Create Hospital Dashboard screen (`lib/features/hospital/presentation/screens/hospital_dashboard_screen.dart`)
- [x] Configure GoRouter routes (`/home`, `/responder`, `/command-center`, `/hospital-dashboard`, `/admin`)
- [x] Add System Role selector dropdown to Profile Creation onboarding flow
- [x] Add Role Portal links to side drawer menu in Citizen Dashboard
- [x] Verify zero compilation errors with `flutter analyze`
- [x] Push to GitHub (commits `b8043d8` & `90e2eb0`)

## Phase 3 — Responder Registration + Verification
- [x] Create Responder Repository to insert into `responders` and `vehicles` tables in Supabase (`lib/features/responder/data/repositories/responder_repository.dart`)
- [x] Create Responder Registration input screen (`lib/features/responder/presentation/screens/responder_registration_screen.dart`)
- [x] Create Responder Pending Verification screen (`lib/features/responder/presentation/screens/responder_pending_screen.dart`)
- [x] Add `/responder-register` & `/responder-pending` routes to GoRouter
- [x] Build Super Admin approval & verification control cards under Admin Dashboard
- [x] Verify zero errors in `flutter analyze`
- [x] Push to GitHub (commit `2904346`)

## Phase 4 — Responder Dashboard
- [x] Create `ResponderController` state notifier for availability status and dispatches (`lib/features/responder/presentation/controllers/responder_controller.dart`)
- [x] Toggle availability status (AVAILABLE/OFFLINE) synced with Supabase
- [x] Setup Supabase Realtime subscription to receive pending dispatches instantly
- [x] Build Accept / Reject interactive buttons with a 30s countdown auto-reject timer
- [x] Push to GitHub (commit `4335c73`)

## Phase 5 — Emergency Request System
- [x] Upgrade EmergencyRepository interface and EmergencyRepositoryImpl with `createEmergencyRequest` and `uploadEmergencyMedia` signatures
- [x] Connect `AmbulanceRequestScreen`, `FireReportScreen`, and `PoliceReportScreen` with custom media upload support and geolocated Supabase table row submissions
- [x] Append emergency event timeline records instantly upon user requests submissions
- [x] Push to GitHub (commit `8a7a409`)

## Phase 6 — Automatic Dispatch Engine
- [x] Write SQL migration script `database/migrations/002_dispatch_engine.sql` containing `find_nearest_responders`, `dispatch_emergency`, and automatic insert triggers
- [x] Wire dynamic RPC calls in the client app repository `fetchNearbyResponders`
- [x] Push to GitHub (commit `e84aa23`)

## Phase 7 — Accept/Reject Workflow
- [x] Add automatic cascade-dispatching trigger when responder rejects or lets a request expire
- [x] Update emergency status to `NO_RESPONDER` in SQL if all candidate units decline
- [x] Create `sweep_expired_dispatches` routine to catch offline responders and time out requests after 35s
- [x] Push to GitHub (commit `d32de53`)

## Phase 8 — Responder GPS Tracking
- [x] Implement Geolocator GPS position stream listener inside `ResponderController`
- [x] Toggle high-frequency location updates (5m delta) when `EN_ROUTE` to dispatch
- [x] Sync current lat/lng to Supabase `responders` and append history trail to `responder_locations`
- [x] Push to GitHub (commit `c87bb98`)

## Phase 9 — Citizen Live Tracking
- [x] Implement unified real-time tracking provider `emergencyRequestStreamProvider` in `emergency_controller.dart`
- [x] Wire live database coordinates sync to Google Maps markers for Ambulance, Fire, and Police tracking screens
- [x] Calculate dynamic physical distance (km) and estimated minutes arrival (ETA) using Geolocator
- [x] Push to GitHub (commit `495f30f`)

## Phase 10 — Command Center (Flutter Web)
- [x] Build `DispatcherController` under `lib/features/dispatcher/presentation/controllers/dispatcher_controller.dart`
- [x] Bind real-time list feeds, PostGIS responder locations, and connected hospitals summary
- [x] Implement dynamic manual dispatcher overrides sorting available crews by geolocator distance
- [x] Push to GitHub (commit `784980c`)

## Phase 11 — Hospital Dashboard
- [x] Write SQL migration script `database/migrations/004_hospital_route.sql` linking `emergency_requests` to `hospitals`
- [x] Create `HospitalController` in `lib/features/hospital/presentation/controllers/hospital_controller.dart`
- [x] Bind ER availability toggles, General Bed counters, ICU Bed counters, and Blood Bank status dropdown to Supabase updates
- [x] Connect real-time incoming ambulance patient transfers and enable patient admissions or ER preparations
- [x] Push to GitHub (commit `469824c`)

## Phase 12 — Police + Fire Brigade Workflows
- [x] Update `EmergencyRepository` to accept fire-specific parameters (`fireType`, `buildingType`, `explosionRisk`, `gasElectricalRisk`) and police-specific parameter (`peopleAffected`)
- [x] Integrate Fire Classification dropdowns and Hazard switchers in `FireReportScreen`
- [x] Integrate People Involved counter in `PoliceReportScreen`
- [x] Push to GitHub (commit `0550a3a`)

## Phase 13 — Push Notifications
- [x] Write SQL migration script `database/migrations/005_push_notifications.sql` to add notification hooks and automatic triggers on dispatch assignments and status changes
- [x] Create `NotificationController` in `lib/features/emergency/presentation/controllers/notification_controller.dart` to request app permissions, upload FCM tokens, and listen to real-time events
- [x] Bind custom SnackBars to display notifications to active users in the foreground
- [x] Push to GitHub (commit `6321c29`)

## Phase 14 — Emergency Timeline + Analytics
- [x] Implement real-time `emergencyEventsStreamProvider` listening to `emergency_events` table modifications
- [x] Add interactive expandable history timeline bottom sheet to citizen tracking screens
- [x] Create `adminChartStatsProvider` calculating incident types distribution (SOS, Ambulance, Fire, Police) from database
- [x] Connect Admin Dashboard LineChart and BarChart visualization to real-time database stats
- [x] Push to GitHub (commit `06c4fb4`)

## Phase 15 — Testing + Security + Error Handling
- [x] Conduct Row Level Security (RLS) policies audit on all database tables (profiles, responders, emergency_requests, dispatch_requests, responder_locations, hospitals)
- [x] Implement SharedPreferences-backed Demo Mode provider (`demoModeProvider`) to isolate test runs from live production operations
- [x] Prepend `[DEMO]` tags to test alerts and customize Dispatcher Command Center to filter or highlight demo events on coordinates maps
- [x] Implement central Global Error Boundary wrapper rendering custom diagnostics screens for runtime exceptions
- [x] Push to GitHub (commit `ab859be`)
