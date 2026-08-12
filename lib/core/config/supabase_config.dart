/// Supabase project configuration.
///
/// Credentials are read from --dart-define environment variables at compile
/// time.  Default values point to the project's development instance and are
/// safe to keep in version control because they are the PUBLIC anon key only.
/// The service-role key must NEVER appear here or anywhere in the Flutter app.
///
/// To override at build time:
///   flutter run --dart-define=SUPABASE_URL=https://… --dart-define=SUPABASE_ANON_KEY=…
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hlkkxzroycndnrbtopyh.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhsa2t4enJveWNuZG5yYnRvcHloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1MjgxMjIsImV4cCI6MjEwMjEwNDEyMn0'
        '.YdpRKOtmVgODxPJl6Qm-D808zdI3n0ImwpJORQt1GIU',
  );

  // ── Table names (single source of truth) ─────────────────────────────────
  static const String profilesTable         = 'profiles';
  static const String respondersTable       = 'responders';
  static const String vehiclesTable         = 'vehicles';
  static const String emergencyRequestsTable = 'emergency_requests';
  static const String dispatchRequestsTable  = 'dispatch_requests';
  static const String responderLocationsTable = 'responder_locations';
  static const String hospitalsTable         = 'hospitals';
  static const String emergencyEventsTable   = 'emergency_events';
}
