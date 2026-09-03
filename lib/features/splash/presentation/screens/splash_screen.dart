import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_initializer.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

/// Instant, modern, animated Splash Screen providing instant visual feedback on app open
class SplashScreen extends ConsumerStatefulWidget {
  final Duration minDisplayDuration;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1200),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeIn,
      ),
    );

    _animController.forward();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final stopwatch = Stopwatch()..start();

    // Kick off initialization concurrently
    try {
      await AppInitializer.instance.initialize();
      if (mounted) {
        await ref.read(settingsControllerProvider.notifier).loadSettings();
      }
    } catch (e) {
      debugPrint('SplashScreen init non-fatal error: $e');
    }

    // Ensure smooth minimum display duration so animation feels polished and deliberate
    final elapsed = stopwatch.elapsed;
    final remaining = widget.minDisplayDuration - elapsed;

    if (remaining > Duration.zero) {
      _navigationTimer = Timer(remaining, () {
        if (mounted) {
          context.go(RoutePaths.home);
        }
      });
    } else {
      if (mounted) {
        context.go(RoutePaths.home);
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ColorPalette.darkBg : ColorPalette.lightBg,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Home Pantry App Icon
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: ColorPalette.freshEmerald
                                  .withValues(alpha: isDark ? 0.35 : 0.25),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF1B4332),
                              child: const Center(
                                child: Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Brand Name
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: isDark ? Colors.white : const Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        AppConstants.appTagline,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? ColorPalette.freshEmerald
                              : const Color(0xFF2D6A4F),
                          letterSpacing: 3.2,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Micro Loading Indicator with Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ColorPalette.darkCard
                              : ColorPalette.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? ColorPalette.darkBorder
                                : ColorPalette.lightBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorPalette.freshEmerald,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Fresh pantry loading...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? ColorPalette.darkTextTertiary
                                    : ColorPalette.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
