import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/app_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prepare non-blocking desktop FFI / platform hooks early
  AppInitializer.instance.ensureEarlyBindings();

  // Kick off background initialization immediately in parallel without blocking UI rendering
  AppInitializer.instance.initialize();

  // Launch the application tree immediately so the logo animation renders on frame 1
  runApp(
    const ProviderScope(
      child: HomePantryApp(),
    ),
  );
}
