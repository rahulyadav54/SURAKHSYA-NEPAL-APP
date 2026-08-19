import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache_service.dart';

class DemoModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'suraksha_demo_mode_active';

  DemoModeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggle(bool val) async {
    await _prefs.setBool(_key, val);
    state = val;
  }
}

final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return DemoModeNotifier(prefs);
});
