import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/app/theme/app_theme.dart';
import 'package:foodsave/core/services/barcode_lookup_service.dart';
import 'package:foodsave/core/utils/food_image_helper.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_category.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_item.dart';
import 'package:foodsave/features/food_inventory/domain/entities/food_unit.dart';
import 'package:foodsave/features/food_inventory/domain/entities/storage_location.dart';
import 'package:foodsave/features/food_inventory/presentation/providers/food_detail_controller.dart';
import 'package:foodsave/features/food_inventory/presentation/screens/food_detail_screen.dart';
import 'package:foodsave/features/settings/presentation/providers/settings_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFoodDetailController extends StateNotifier<AsyncValue<FoodItem?>>
    implements FoodDetailController {
  MockFoodDetailController(FoodItem item) : super(AsyncValue.data(item));

  @override
  String get id => state.value?.id ?? '';

  @override
  Future<void> consume(double quantity) async {}

  @override
  Future<void> delete() async {}

  @override
  Future<void> extendExpiry(DateTime newExpiryDate) async {}

  @override
  Future<void> loadItem() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Food Image Consistency Tests', () {
    test('FoodImageHelper maps Maggi to noodles instead of cookies', () {
      final maggiUrl = FoodImageHelper.getEffectiveImageUrl(
        'Maggi',
        FoodCategory.snacksAndPackaged,
      );
      final noodlesUrl = FoodImageHelper.getEffectiveImageUrl(
        'noodles',
        FoodCategory.snacksAndPackaged,
      );
      final cookiesUrl = FoodImageHelper.getEffectiveImageUrl(
        'cookies',
        FoodCategory.snacksAndPackaged,
      );

      // Maggi should resolve to noodles photo, not cookies
      expect(maggiUrl, equals(noodlesUrl));
      expect(maggiUrl, isNot(equals(cookiesUrl)));
    });

    test('FoodImageHelper getEffectiveItemImagePath prioritizes network imagePath', () {
      const customUrl = 'https://images.openfoodfacts.org/images/products/maggi.jpg';
      final itemWithUrl = FoodItem(
        id: 'maggi-1',
        name: 'Maggi',
        category: FoodCategory.snacksAndPackaged,
        purchaseDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 120)),
        remainingQuantity: 1,
        unit: FoodUnit.pieces,
        storageLocation: StorageLocation.pantry,
        barcode: '8901058000269',
        imagePath: customUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final effectivePath = FoodImageHelper.getEffectiveItemImagePath(itemWithUrl);
      expect(effectivePath, equals(customUrl));
    });

    test('offlineBarcodeCatalog contains Maggi barcode 8901058000269 with noodles photo', () {
      final match = offlineBarcodeCatalog.firstWhere(
        (p) => p.barcode == '8901058000269',
        orElse: () => const BarcodeProduct(
          barcode: '',
          name: '',
          category: FoodCategory.other,
          defaultQuantity: 1,
          unit: FoodUnit.pieces,
          storageLocation: StorageLocation.pantry,
        ),
      );

      expect(match.barcode, equals('8901058000269'));
      expect(match.name, contains('Maggi'));
      expect(match.category, equals(FoodCategory.snacksAndPackaged));
      expect(match.effectiveImageUrl, contains('1612927601601')); // Unsplash noodles photo
    });

    testWidgets('FoodDetailScreen renders network image matching home page item.imagePath', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const itemImageUrl = 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80';
      final maggiItem = FoodItem(
        id: 'maggi-detail-test',
        name: 'Maggi',
        category: FoodCategory.snacksAndPackaged,
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        expiryDate: DateTime.now().add(const Duration(days: 119)),
        remainingQuantity: 1,
        unit: FoodUnit.pieces,
        storageLocation: StorageLocation.pantry,
        barcode: '8901058000269',
        imagePath: itemImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            foodDetailControllerProvider('maggi-detail-test')
                .overrideWith((ref) => MockFoodDetailController(maggiItem)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FoodDetailScreen(id: 'maggi-detail-test'),
          ),
        ),
      );

      await tester.pump();

      // Ensure FoodDetailScreen loaded
      expect(find.byType(FoodDetailScreen), findsOneWidget);
      expect(find.text('Maggi'), findsAtLeast(1));
      expect(find.text('8901058000269'), findsOneWidget);

      // Verify that Image.network is rendered with the exact item.imagePath
      final imageNetworkFinder = find.byWidgetPredicate((widget) {
        if (widget is Image) {
          final provider = widget.image;
          if (provider is NetworkImage) {
            return provider.url == itemImageUrl;
          } else if (provider is ResizeImage) {
            final inner = provider.imageProvider;
            if (inner is NetworkImage) {
              return inner.url == itemImageUrl;
            }
          }
        }
        return false;
      });

      expect(imageNetworkFinder, findsWidgets);
      expect(find.text('Tap to Zoom'), findsWidgets);
    });
  });
}
