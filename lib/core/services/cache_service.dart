import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/data/models/user_profile_model.dart';

class CacheService {
  final SharedPreferences _prefs;
  static const String _profileKey = 'cached_user_profile';

  CacheService(this._prefs);

  /// Caches the user profile JSON locally
  Future<void> cacheProfile(UserProfile profile) async {
    final model = UserProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      bloodGroup: profile.bloodGroup,
      allergies: profile.allergies,
      medicalNotes: profile.medicalNotes,
      emergencyContact1: profile.emergencyContact1,
      emergencyContact2: profile.emergencyContact2,
    );
    await _prefs.setString(_profileKey, jsonEncode(model.toJson()));
  }

  /// Retrieves the cached profile if present, returns null if missing
  UserProfile? getCachedProfile() {
    final str = _prefs.getString(_profileKey);
    if (str == null) return null;
    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      return UserProfileModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _prefs.remove(_profileKey);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main entrypoint');
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return CacheService(prefs);
});
