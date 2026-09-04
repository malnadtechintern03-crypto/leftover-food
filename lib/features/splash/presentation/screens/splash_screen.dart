import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/services/app_initializer.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

/// Cinematic, animated Splash Screen inspired by ChatGPT & premium apps.
/// Features a smooth entrance bloom, living breathing glow aura, and cinematic exit dissolve.
class SplashScreen extends ConsumerStatefulWidget {
  final Duration minDisplayDuration;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1000),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _glowIntensity;

  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  Timer? _displayTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance bloom animation (380ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _entranceScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    // 2. Living breathing halo aura (1000ms loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseScale = Tween<double>(begin: 0.98, end: 1.035).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowIntensity = Tween<double>(begin: 0.25, end: 0.8).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Cinematic exit dissolve (200ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _startSplashScreenSequence();
  }

  void _startSplashScreenSequence() async {
    // 1. Run entrance bloom immediately, then loop the living pulse
    _entranceController.forward().then((_) {
      if (mounted && !_isNavigating) {
        _pulseController.repeat(reverse: true);
      }
    });

    // 2. Concurrently wait for display duration and background initialization
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

    _pulseController.stop();

    try {
      if (!_exitController.isCompleted) {
        await _exitController.forward();
      }
    } catch (_) {
      // Ignore ticker cancellations during exit
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
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _pulseController,
            _exitController,
          ]),
          builder: (context, child) {
            final double currentScale = _entranceScale.value *
                (_entranceController.isCompleted ? _pulseScale.value : 1.0) *
                _exitScale.value;

            final double currentOpacity = (_entranceFade.value * _exitFade.value)
                .clamp(0.0, 1.0);

            final double glowValue = _glowIntensity.value * _entranceFade.value;

            return Opacity(
              opacity: currentOpacity,
              child: Transform.scale(
                scale: currentScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ethereal Breathing Aura (Emerald & White Halo)
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.30 * glowValue),
                            blurRadius: 50 + (25 * glowValue),
                            spreadRadius: 6 + (10 * glowValue),
                          ),
                          BoxShadow(
                            color: Colors.white
                                .withValues(alpha: 0.15 * glowValue),
                            blurRadius: 25 + (15 * glowValue),
                            spreadRadius: 2 + (5 * glowValue),
                          ),
                        ],
                      ),
                    ),

                    // ChatGPT-Style Minimalist Centered Emblem
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Image.asset(
                        'assets/icons/chatgpt_style_logo_white.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.home_outlined,
                              color: Colors.white,
                              size: 72,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
