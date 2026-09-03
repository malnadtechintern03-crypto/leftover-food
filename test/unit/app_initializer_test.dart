import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/core/services/app_initializer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppInitializer Tests', () {
    test('ensureEarlyBindings does not throw on test environment', () {
      expect(() => AppInitializer.instance.ensureEarlyBindings(), returnsNormally);
    });

    test('initialize completes successfully in memory environment', () async {
      SharedPreferences.setMockInitialValues({'test_key': 'test_val'});
      
      final initializer = AppInitializer.instance;
      await initializer.initialize();

      expect(initializer.isInitialized, isTrue);
      expect(initializer.sharedPreferences, isNotNull);
    });
  });
}
