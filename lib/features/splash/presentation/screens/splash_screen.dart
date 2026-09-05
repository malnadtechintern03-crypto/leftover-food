import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_initializer.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

/// Highly animated, premium Splash Screen for FoodSave / Home Pantry.
/// Features:
/// - Floating ambient organic pantry particles drifting smoothly in background
/// - Dual expanding sonar radar ripples pulsing outwards
/// - Levitation float effect (bobbing in mid-air with dynamic ground shadow)
/// - Flash & shimmer gleam beam sweeping across the squircle app icon
/// - Staggered typography entrance with emerald gradient shader mask
/// - Animated feature badges (Fresh Tracker • Smart Alerts • Zero Waste)
/// - Sleek glassmorphic progress bar with dynamic stage messages
/// - Cinematic zoom & fade transition on completion
class SplashScreen extends ConsumerStatefulWidget {
  final Duration minDisplayDuration;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 2800),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // 1. Staggered Entrance Controller
  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _letterSpacing;
  late final Animation<double> _badgesFade;
  late final Animation<Offset> _badgesSlide;
  late final Animation<double> _progressFade;

  // 2. Levitation Float Controller (Infinite Breathing Bob)
  late final AnimationController _floatController;
  late final Animation<double> _floatY;
  late final Animation<double> _shadowScale;

  // 3. Sonar Radar Ripple Controller (Infinite Pulse)
  late final AnimationController _rippleController;

  // 4. Shimmer Glint / Flash Beam Controller
  late final AnimationController _shimmerController;

  // 5. Floating Ambient Particles Controller
  late final AnimationController _particleController;

  // 6. Progress Fill Controller (Timed)
  late final AnimationController _progressController;

  // 7. Cinematic Exit Controller
  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  Timer? _displayTimer;
  bool _isNavigating = false;
  final List<_Particle> _particles = _generateParticles(18);

  @override
  void initState() {
    super.initState();

    // 1. Entrance orchestration (900ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _letterSpacing = Tween<double>(begin: 0.5, end: 3.2).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _badgesFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _badgesSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Levitation Float (2200ms easeInOut loop)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _floatY = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );
    _shadowScale = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Sonar Radar Ripples (2000ms repeating loop)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 4. Shimmer Glint / Flash Beam (2400ms repeating loop)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 5. Ambient Particles (5000ms continuous loop)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // 6. Timed Progress Loading Fill
    _progressController = AnimationController(
      vsync: this,
      duration: widget.minDisplayDuration,
    );

    // 7. Exit transition (300ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _startSplashScreenSequence();
  }

  void _startSplashScreenSequence() async {
    // Start continuous ambient animations
    _particleController.repeat();
    _rippleController.repeat();
    _shimmerController.repeat();

    // Start entrance animation, followed by float bobbing
    _entranceController.forward().then((_) {
      if (mounted && !_isNavigating) {
        _floatController.repeat(reverse: true);
      }
    });

    // Start progress bar animation
    _progressController.forward();

    // Concurrently wait for display duration and background initialization
    final displayCompleter = Completer<void>();
    _displayTimer = Timer(widget.minDisplayDuration, () {
      if (!displayCompleter.isCompleted) {
        displayCompleter.complete();
      }
    });

    final initFuture = _runBackgroundInit();

    await Future.wait([displayCompleter.future, initFuture]);

    if (mounted) {
      _finishAndNavigate();
    }
  }

  Future<void> _runBackgroundInit() async {
    try {
      await AppInitializer.instance.initialize();
      if (mounted) {
        await ref.read(settingsControllerProvider.notifier).loadSettings();
      }
    } catch (e) {
      debugPrint('SplashScreen background init note: $e');
    }
  }

  void _finishAndNavigate() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    _floatController.stop();
    _rippleController.stop();
    _shimmerController.stop();
    _particleController.stop();

    try {
      if (!_exitController.isCompleted) {
        await _exitController.forward();
      }
    } catch (_) {
      // Ignore ticker interruptions on exit
    }

    if (mounted) {
      try {
        context.go(RoutePaths.home);
      } catch (e) {
        debugPrint('SplashScreen navigation fallback: $e');
        try {
          Navigator.of(context).pushReplacementNamed(RoutePaths.home);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _entranceController.dispose();
    _floatController.dispose();
    _rippleController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? ColorPalette.darkBg : ColorPalette.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Layer 1: Ambient Organic Pantry Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlesPainter(
                    particles: _particles,
                    progress: _particleController.value,
                    color: ColorPalette.freshEmerald,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // Layer 2: Subtle Ambient Center Radial Glow
          Positioned.fill(
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorPalette.freshEmerald.withValues(
                        alpha: isDark ? 0.16 : 0.09,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Layer 3: Main Animated Content Stack
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _entranceController,
                  _floatController,
                  _rippleController,
                  _shimmerController,
                  _progressController,
                  _exitController,
                ]),
                builder: (context, child) {
                  final double currentScale =
                      _logoScale.value * _exitScale.value;
                  final double currentOpacity =
                      (_logoFade.value * _exitFade.value).clamp(0.0, 1.0);
                  final double floatOffset =
                      _entranceController.isCompleted ? _floatY.value : 0.0;
                  final double shadowScaleVal = _entranceController.isCompleted
                      ? _shadowScale.value
                      : 1.0;

                  return Opacity(
                    opacity: currentOpacity,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ---------------- HERO LOGO SECTION ----------------
                          SizedBox(
                            width: 200,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Concentric Radar Ripple Waves (Flash Pulse)
                                ..._buildRippleRings(isDark),

                                // Ground Shadow that breathes inversely with levitation
                                Positioned(
                                  bottom: 14 + floatOffset,
                                  child: Transform.scale(
                                    scaleX: shadowScaleVal,
                                    scaleY: 1.0 / shadowScaleVal,
                                    child: Container(
                                      width: 80,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? ColorPalette.freshEmerald
                                                    .withValues(alpha: 0.22)
                                                : Colors.black
                                                    .withValues(alpha: 0.12),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Levitating Brand Logo Icon
                                Positioned(
                                  top: 24 - floatOffset,
                                  child: Transform.scale(
                                    scale: currentScale,
                                    child: _buildBrandIconCard(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ---------------- BRAND TYPOGRAPHY ----------------
                          Transform.translate(
                            offset: _titleSlide.value * 20,
                            child: Opacity(
                              opacity: _titleFade.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Shimmering Gradient Brand Name
                                  ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        colors: [
                                          ColorPalette.freshEmerald,
                                          Color(0xFF34D399),
                                          Color(0xFF0EA5E9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      AppConstants.appName,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: _letterSpacing.value,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Sleek Tagline Capsule
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.freshEmerald
                                          .withValues(alpha: isDark ? 0.15 : 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: ColorPalette.freshEmerald
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${AppConstants.appTagline} • ZERO WASTE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFF6EE7B7)
                                            : ColorPalette.freshEmeraldDark,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ---------------- FEATURE PILLS (STAGGERED) ----------------
                          Transform.translate(
                            offset: _badgesSlide.value * 16,
                            child: Opacity(
                              opacity: _badgesFade.value,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildFeatureBadge(
                                    icon: Icons.eco_rounded,
                                    label: 'Fresh Track',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFeatureBadge(
                                    icon: Icons.alarm_rounded,
                                    label: 'Smart Alerts',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFeatureBadge(
                                    icon: Icons.recycling_rounded,
                                    label: 'Save Food',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ---------------- PROGRESS & STATUS SECTION ----------------
                          Opacity(
                            opacity: _progressFade.value,
                            child: _buildProgressSection(isDark),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the expanding sonar pulse ripple rings around the logo
  List<Widget> _buildRippleRings(bool isDark) {
    return List.generate(2, (index) {
      final double ringOffset = index * 0.5;
      final double ringProgress =
          (_rippleController.value + ringOffset) % 1.0;
      final double ringRadius = 70 + (ringProgress * 65);
      final double ringOpacity =
          (1.0 - ringProgress) * (isDark ? 0.35 : 0.22);

      return Container(
        width: ringRadius * 2,
        height: ringRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ColorPalette.freshEmerald.withValues(alpha: ringOpacity),
            width: 1.5,
          ),
        ),
      );
    });
  }

  /// Builds the squircle card with living ambient glow & flash shimmer beam
  Widget _buildBrandIconCard(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Emerald Glow Halo
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.freshEmerald.withValues(
                  alpha: isDark ? 0.42 : 0.28,
                ),
                blurRadius: 28,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: (isDark ? Colors.white : ColorPalette.freshEmeraldLight)
                    .withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        ),

        // Brand Icon Squircle Container
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131F2E) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? ColorPalette.freshEmerald.withValues(alpha: 0.5)
                  : ColorPalette.freshEmeraldLight,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Logo Image / Fallback
              Center(
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFECFDF5),
                      child: const Center(
                        child: Icon(
                          Icons.eco_rounded,
                          color: ColorPalette.freshEmerald,
                          size: 54,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Diagonal Shimmer / Flash Beam Passing Across Icon
              Positioned.fill(
                child: CustomPaint(
                  painter: _ShimmerFlashPainter(
                    progress: _shimmerController.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Feature badge pill
  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: ColorPalette.freshEmerald,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ColorPalette.darkTextSecondary
                  : ColorPalette.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar & dynamic stage feedback
  Widget _buildProgressSection(bool isDark) {
    final double progressVal = _progressController.value;

    String statusText;
    if (progressVal < 0.35) {
      statusText = 'Checking fresh groceries...';
    } else if (progressVal < 0.75) {
      statusText = 'Organizing smart alerts...';
    } else {
      statusText = 'Ready for a fresh day!';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sleek Capsule Progress Bar Track
        Container(
          width: 180,
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progressVal.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      ColorPalette.freshEmerald,
                      Color(0xFF34D399),
                      Color(0xFF0EA5E9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Live Dynamic Status Note
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorPalette.freshEmerald.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                statusText,
                key: ValueKey<String>(statusText),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ColorPalette.darkTextSecondary
                      : ColorPalette.lightTextSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper model for ambient floating particles
class _Particle {
  final double xRatio;
  final double yRatio;
  final double size;
  final double speed;
  final double phase;
  final double opacity;

  _Particle({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.speed,
    required this.phase,
    required this.opacity,
  });
}

List<_Particle> _generateParticles(int count) {
  final random = math.Random(42);
  return List.generate(count, (index) {
    return _Particle(
      xRatio: random.nextDouble(),
      yRatio: random.nextDouble(),
      size: 2.0 + random.nextDouble() * 3.5,
      speed: 0.5 + random.nextDouble() * 0.7,
      phase: random.nextDouble() * 2 * math.pi,
      opacity: 0.15 + random.nextDouble() * 0.35,
    );
  });
}

/// Custom painter for ethereal floating ambient particles
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;
  final bool isDark;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final double y = ((p.yRatio - (progress * p.speed)) % 1.0) * size.height;
      final double x = (p.xRatio * size.width) +
          (math.sin(p.phase + (progress * 2 * math.pi)) * 14);

      paint.color = color.withValues(
        alpha: p.opacity * (isDark ? 0.7 : 0.45),
      );

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Diagonal shimmer flash beam painter that sweeps across the app icon
class _ShimmerFlashPainter extends CustomPainter {
  final double progress;

  _ShimmerFlashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // progress moves from 0.0 to 1.0; beam travels from top-left to bottom-right
    final double sweepPosition = (progress * (size.width + size.height * 1.5)) - (size.height * 0.5);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(sweepPosition - 40, 0, 80, size.height),
      );

    canvas.save();
    // Rotate canvas slightly for a dramatic diagonal beam angle
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-size.width / 2, -size.height / 2);

    canvas.drawRect(
      Rect.fromLTWH(sweepPosition - 40, -size.height, 80, size.height * 3),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerFlashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
