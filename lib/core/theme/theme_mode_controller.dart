import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'theme_mode';

/// Persists the user's appearance choice (Claro / Oscuro / Sistema).
class ThemeModeStorage {
  ThemeModeStorage._();

  /// Read before `runApp` so the very first frame already uses the saved
  /// mode instead of flashing the system one. Defaults to [ThemeMode.system].
  static Future<ThemeMode> read() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_prefsKey);
      return ThemeMode.values.asNameMap()[name] ?? ThemeMode.system;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static Future<void> write(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

/// Overridden in `main()` with the value loaded by [ThemeModeStorage.read].
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ThemeModeStorage.write(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
