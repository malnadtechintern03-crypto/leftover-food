import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/app_initializer.dart';
import 'features/settings/presentation/providers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prepare non-blocking desktop FFI / platform hooks early
  AppInitializer.instance.ensureEarlyBindings();

  // Kick off background initialization immediately so database & background tasks prepare in parallel
  AppInitializer.instance.initialize();

  // Pre-load SharedPreferences before runApp so saved theme is restored on the very first frame
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(
      const Duration(milliseconds: 200),
    );
    AppInitializer.instance.setSharedPreferences(prefs);
  } catch (e) {
    debugPrint('SharedPreferences early init note: $e');
  }

  // Launch the application tree immediately with restored preferences
  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FoodSaveApp(),
    ),
  );
}
