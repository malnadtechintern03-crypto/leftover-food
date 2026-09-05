import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodsave/app/theme/color_palette.dart';
import 'package:foodsave/core/constants/app_constants.dart';
import 'package:foodsave/features/splash/presentation/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SplashScreen has minimum 2-3 seconds default display duration', (WidgetTester tester) async {
    const splash = SplashScreen();
    expect(splash.minDisplayDuration.inMilliseconds, greaterThanOrEqualTo(2000));
    expect(splash.minDisplayDuration.inMilliseconds, lessThanOrEqualTo(3000));
  });

  testWidgets('SplashScreen renders animated brand logo, app title and theme background', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            minDisplayDuration: Duration(milliseconds: 50),
          ),
        ),
      ),
    );

    // Verify brand logo image is rendered
    expect(find.byType(Image), findsOneWidget);

    // Verify app brand name and tagline are present
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);

    // Verify background is clean theme-adaptive background, not pitch black
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, ColorPalette.lightBg);

    await tester.pump(const Duration(milliseconds: 600));
  });
}
