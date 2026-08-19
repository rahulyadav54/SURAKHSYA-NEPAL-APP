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
- [x] Create `UserRole` & `ServiceType` domain entities (`lib/features/auth/domain/entities/user_role.dart`)
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
- [ ] Active dispatch handling & status management
- [ ] Incoming dispatch request card (Accept/Reject with timer)
- [ ] Responder availability states (AVAILABLE, BUSY, EN_ROUTE, OFFLINE)

## Phase 5 — Emergency Request System
- [ ] Emergency confirmation screen (Ambulance/Police/Fire)
- [ ] Photo/video attachment
- [ ] Create emergency_requests row via Supabase
- [ ] Emergency event timeline append

## Phase 6 — Automatic Dispatch Engine
- [ ] Supabase Edge Function: find_nearest_responders
- [ ] Supabase Edge Function: dispatch_emergency
- [ ] Dispatch request creation with distance + ETA ranking

## Phase 7 — Accept/Reject Workflow
- [ ] Responder receives dispatch via Supabase Realtime
- [ ] Accept/Reject with timeout (30s window)
- [ ] Auto-cascade to next responder on reject/expire
- [ ] emergency.status = NO_RESPONDER → notify dispatcher

## Phase 8 — Responder GPS Tracking
- [ ] Location stream (3–5s interval when EN_ROUTE)
- [ ] Low-frequency update when AVAILABLE
- [ ] Stop when OFFLINE
- [ ] Update responders table current_lat/lng + responder_locations history

## Phase 9 — Citizen Live Tracking
- [ ] Live map screen with citizen + responder markers
- [ ] Supabase Realtime subscription to responder_locations
- [ ] ETA countdown
- [ ] ARRIVED state update

## Phase 10 — Command Center (Flutter Web)
- [ ] Three-column layout: Emergencies | Live Map | Resources
- [ ] Realtime emergency list
- [ ] Responder markers on map
- [ ] Manual dispatch override

## Phase 11 — Hospital Dashboard
- [ ] Incoming ambulances list
- [ ] ER / ICU / Beds capacity update
- [ ] Blood availability toggle

## Phase 12 — Police + Fire Brigade Workflows
- [ ] Fire-specific fields (fire type, explosion risk, gas risk)
- [ ] Police-specific fields (crime category, people involved)
- [ ] Reuse dispatch architecture

## Phase 13 — Push Notifications
- [ ] FCM trigger on dispatch_created (responder)
- [ ] FCM trigger on emergency status changes (citizen)
- [ ] FCM trigger on no_responder (dispatcher)

## Phase 14 — Emergency Timeline + Analytics
- [ ] Timeline widget from emergency_events table
- [ ] Analytics dashboard (response times, severity breakdown)

## Phase 15 — Testing + Security + Error Handling
- [ ] Full RLS audit
- [ ] JWT bridge security review
- [ ] Error states for all network operations
- [ ] Demo mode isolated from production
