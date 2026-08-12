import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the initialized [SupabaseClient] instance.
///
/// Supabase.initialize() must be called in main() before this provider
/// is first accessed.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
