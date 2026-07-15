class AppConstants {
  const AppConstants._();

  static const String appName = 'Suraksha Nepal';
  static const String appVersion = '1.0.0';

  // Supabase Configurations
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://szxitrlzvcknqdlxphux.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6eGl0cmx6dmNrbnFkbHhwaHV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwOTc3MjEsImV4cCI6MjA5OTY3MzcyMX0.6ew8Cg9ju2NecPIEHUGwSWfYT_LkSREJT6bgmzZEcts',
  );

  // Gemini AI configurations
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
