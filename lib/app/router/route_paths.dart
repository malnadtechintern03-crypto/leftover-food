/// URL path constants for GoRouter
class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String addFood = '/food/add';
  static const String editFood = '/food/edit/:id';
  static const String foodDetail = '/food/:id';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String calendar = '/calendar';
  static const String shoppingList = '/shopping-list';
  static const String analytics = '/analytics';
  static const String recipes = '/recipes';
  static const String barcodeScanner = '/barcode-scanner';

  static String foodDetailPath(String id) => '/food/$id';
  static String editFoodPath(String id) => '/food/edit/$id';
}
