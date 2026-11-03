import 'dart:async';

import 'package:flutter/material.dart';

// StatefulWidget

// Purpose: Creates a reusable loading-screen widget.
// - StatefulWidget: Used because the loading screen changes over time.
// - child: Receives the actual application screen.
// - createState(): Connects the widget with its mutable state.
class MobileIntroLoader extends StatefulWidget {
  const MobileIntroLoader({required this.child, super.key});

  final Widget child;

  @override
  State<MobileIntroLoader> createState() => _MobileIntroLoaderState();
}


// SingleTickerProviderStateMixin: Provides a single ticker (a signal that ticks at a regular interval) for animations.

// Purpose: Provides a ticker for controlling animations.
// - State: Manages the widget's changing state.
// - SingleTickerProviderStateMixin: Supplies one ticker for an animation controller.
// - with: Adds reusable functionality through a mixin.
class _MobileIntroLoaderState extends State<MobileIntroLoader>
    with SingleTickerProviderStateMixin {
      
  // static: Shared at class level.
  static const _mobileBreakpoint = 600.0;
  static const _duration = Duration(seconds: 10);

// vsync	Synchronizes animation with screen refresh
  // addStatusListener	Listens for animation status changes
  // .. is called the cascade operator. It allows another method to be called on the same object.
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: _duration,
  )..addStatusListener(_handleProgressStatus);

  // TweenSequence – Pulse Animation
  //   Purpose: Makes the logo gently grow and shrink.
  // - Animation<double>: Animation produces decimal values.
  // - TweenSequence: Combines multiple animation steps.
  // - begin: Starting scale.
  // - end: Ending scale.
  // - index.isEven: Checks whether the index is even.
  // - Curves.easeInOut: Makes movement smooth.
  // - weight: Determines the relative duration of each sequence step.
  late final Animation<double> _pulse = TweenSequence<double>([
    for (var index = 0; index < 10; index++)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: index.isEven ? 0.96 : 1.04,
          end: index.isEven ? 1.04 : 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
  ]).animate(_progressController);

  bool _started = false;
  bool _fadingOut = false;
  bool _completed = false;
  // Timer? means the timer can be null.
  Timer? _dismissTimer;


// Animation Status Listener

  // Important concepts:
  // - mounted: Checks whether the widget is still in the widget tree.
  // - setState(): Tells Flutter to rebuild the widget.
  // - AnimationStatus.completed: Indicates animation has finished.

  void _handleProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _fadingOut = true);
      _dismissTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() => _completed = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    // LayoutBuilder – Responsive Design
    // LayoutBuilder: Provides the available layout constraints.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= _mobileBreakpoint;


        // Purpose: Starts the animation only once on mobile.
        // - !_started: Checks that animation hasn't started.
        // - WidgetsBinding: Provides access to Flutter's framework lifecycle.
        // - addPostFrameCallback: Executes code after the current frame is rendered.
        // - forward(): Starts the animation from beginning to end.
        if (isMobile && !_started) {
          _started = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _progressController.forward();
            }
          });
        }
// Stack and Positioned.fill
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (isMobile && !_completed)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _fadingOut ? 0 : 1,
                  duration: const Duration(milliseconds: 450),
                  child: _IntroOverlay(
                    progress: _progressController,
                    pulse: _pulse,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

// Dispose – Memory Management

  // Purpose: Cleans up resources when the widget is removed.
  // - cancel(): Stops the timer.
  // - removeStatusListener(): Removes the animation listener.
  // - dispose(): Releases animation controller resources.
  // - super.dispose(): Calls the parent lifecycle method.
  @override
  void dispose() {
    _dismissTimer?.cancel();
    _progressController
      ..removeStatusListener(_handleProgressStatus)
      ..dispose();
    super.dispose();
  }
}

class _IntroOverlay extends StatelessWidget {
  const _IntroOverlay({required this.progress, required this.pulse});

  final Animation<double> progress;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17132E), Color(0xFF281D4E), Color(0xFF111827)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -110,
              right: -95,
              child: _GlowOrb(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                size: 280,
              ),
            ),
            Positioned(
              bottom: -130,
              left: -100,
              child: _GlowOrb(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                size: 300,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Purpose: Rebuilds only the required animation section when the animation value changes
                    AnimatedBuilder(
                      animation: pulse,
                      builder: (context, child) =>
                          Transform.scale(scale: pulse.value, child: child),
                      child: SizedBox(
                        width: 144,
                        height: 144,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: progress,
                              builder: (context, _) => SizedBox.expand(

                                //Purpose: Displays loading progress in a    circular shape.
                                // - value: Current progress between 0.0 and 1.0.
                                // - strokeWidth: Thickness of the progress circle.
                                // - strokeCap: Makes line endings rounded.
                                // - backgroundColor: Background circle color.
                                // - valueColor: Progress indicator color.
                                child: CircularProgressIndicator(
                                  value: progress.value,
                                  strokeWidth: 3,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.12,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFA78BFA),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF4F46E5),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Post Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your social workspace is getting ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    AnimatedBuilder(
                      animation: progress,
                      builder: (context, _) => Text(
                        '${(progress.value * 100).round()}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PREPARING YOUR WORKSPACE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This creates decorative glowing circles using:
// - BoxShape.circle: Creates circular shape.
// - BoxShadow: Creates glowing effect.
// - blurRadius: Controls blur intensity.
// - spreadRadius: Controls shadow expansion.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 30)],
      ),
    );
  }
}
