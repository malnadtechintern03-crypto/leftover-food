import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root application widget
class FoodSaveApp extends ConsumerWidget {
  const FoodSaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider).valueOrNull;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings?.themeMode ?? ThemeMode.system,
      routerConfig: router,
    );
  }
}
