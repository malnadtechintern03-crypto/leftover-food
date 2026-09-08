import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/color_palette.dart';
import '../constants/app_constants.dart';

/// Helper utility for handling Google Play Store rating and privacy policy presentation
class AppReviewHelper {
  AppReviewHelper._();

  static const String playStorePackage = 'com.homepantry.app';
  static const String playStoreMarketUri = 'market://details?id=$playStorePackage';
  static const String playStoreWebUrl = 'https://play.google.com/store/apps/details?id=$playStorePackage';
  static const String privacyPolicyUrl = 'http://localhost/leftover/admin/privacy-policy.php';

  /// Launches Google Play Store for rating the app with safe fallback
  static Future<void> openRateApp(BuildContext context) async {
    final marketUri = Uri.parse(playStoreMarketUri);
    final webUri = Uri.parse(playStoreWebUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Fall through to web URL
    }

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Fall through to feedback dialog
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
              SizedBox(width: 8),
              Text('Rate Home Pantry', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Enjoying Home Pantry? Google Play Store services are not reachable on this device or emulator. Thank you for your support and for reducing food waste! 🌿',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }

  /// Opens the public Privacy Policy web page or shows in-app summary
  static Future<void> openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(privacyPolicyUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Show in-app privacy policy dialog
    }

    if (context.mounted) {
      showPrivacyPolicyDialog(context);
    }
  }

  /// Displays the in-app offline Privacy Policy dialog
  static void showPrivacyPolicyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.privacy_tip_rounded, color: ColorPalette.freshEmerald, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Home Pantry (${AppConstants.appVersion})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColorPalette.freshEmerald),
              ),
              const SizedBox(height: 10),
              const Text(
                '1. Offline-First Privacy Guarantee\n'
                'All your grocery inventory, purchase prices, expiration dates, custom notes, and consumption history are stored locally on your device in an application-private SQLite database. We do not transmit or sell your food records.\n\n'
                '2. Camera Permission (Barcode Scanner)\n'
                'Used strictly for scanning standard product barcodes (EAN-13, UPC). Image frames are analyzed entirely on-device and never stored or uploaded.\n\n'
                '3. Notification Permission\n'
                'Used to schedule on-device alarms that alert you before groceries spoil.\n\n'
                '4. Data Deletion Rights\n'
                'You retain total ownership over your data. You can export CSV records, create local JSON backups, or purge all data anytime in Chef Profile.\n\n'
                'Contact: privacy@homepantry.com',
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
