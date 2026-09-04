import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/analytics/presentation/screens/grocery_analytics_screen.dart';
import '../../features/food_inventory/presentation/providers/food_inventory_providers.dart';
import '../../features/food_inventory/presentation/screens/add_edit_food_screen.dart';
import '../../features/food_inventory/presentation/screens/barcode_scanner_screen.dart';
import '../../features/food_inventory/presentation/screens/food_detail_screen.dart';
import '../../features/settings/presentation/screens/notifications_center_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shopping_list/presentation/screens/shopping_list_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../presentation/main_navigation_scaffold.dart';
import 'route_names.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const MainNavigationScaffold(),
      ),
      GoRoute(
        path: RoutePaths.addFood,
        name: RouteNames.addFood,
        builder: (context, state) => const AddEditFoodScreen(),
      ),
      GoRoute(
        path: RoutePaths.editFood,
        name: RouteNames.editFood,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FutureBuilder(
            future: ref.read(getFoodItemByIdUseCaseProvider).call(id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return AddEditFoodScreen(initialItem: snapshot.data);
            },
          );
        },
      ),
      GoRoute(
        path: RoutePaths.foodDetail,
        name: RouteNames.foodDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FoodDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsCenterScreen(),
      ),
      GoRoute(
        path: RoutePaths.calendar,
        name: RouteNames.calendar,
        builder: (context, state) => const MainNavigationScaffold(initialIndex: 2),
      ),
      GoRoute(
        path: RoutePaths.shoppingList,
        name: RouteNames.shoppingList,
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: RoutePaths.analytics,
        name: RouteNames.analytics,
        builder: (context, state) => const GroceryAnalyticsScreen(),
      ),
      GoRoute(
        path: RoutePaths.recipes,
        name: RouteNames.recipes,
        builder: (context, state) => const MainNavigationScaffold(initialIndex: 3),
      ),
      GoRoute(
        path: RoutePaths.barcodeScanner,
        name: RouteNames.barcodeScanner,
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
    ],
  );
});
