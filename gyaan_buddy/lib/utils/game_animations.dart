import 'package:flutter/material.dart';
import 'dart:math' as math;

class GameAnimations {
  // Particle system for celebration effects
  static Widget particleBurst({
    required Widget child,
    required VoidCallback onComplete,
    Color particleColor = Colors.amber,
    int particleCount = 20,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return ParticleBurst(
      child: child,
      onComplete: onComplete,
      particleColor: particleColor,
      particleCount: particleCount,
      duration: duration,
    );
  }

  // Floating animation for UI elements
  static Widget floatingAnimation({
    required Widget child,
    double amplitude = 8.0,
    Duration duration = const Duration(seconds: 2),
    Curve curve = Curves.easeInOut,
  }) {
    return FloatingAnimation(
      child: child,
      amplitude: amplitude,
      duration: duration,
      curve: curve,
    );
  }

  // Bounce animation for interactive elements
  static Widget bounceAnimation({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.95,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return BounceAnimation(
      child: child,
      onTap: onTap,
      scale: scale,
      duration: duration,
    );
  }

  // Shake animation for error feedback
  static Widget shakeAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return ShakeAnimation(
      child: child,
      duration: duration,
    );
  }

  // Pulse animation for loading states
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(seconds: 1),
  }) {
    return PulseAnimation(
      child: child,
      duration: duration,
    );
  }

  // Slide in animation with bounce
  static Widget slideInBounce({
    required Widget child,
    Offset begin = const Offset(0, 1),
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return SlideInBounce(
      child: child,
      begin: begin,
      duration: duration,
    );
  }

  // Rotate and scale animation
  static Widget rotateScale({
    required Widget child,
    double rotation = 360,
    double scale = 1.2,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return RotateScale(
      child: child,
      rotation: rotation,
      scale: scale,
      duration: duration,
    );
  }

  // App bar slide from top animation
  static Widget appBarSlideFromTop({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOutCubic,
  }) {
    return AppBarSlideFromTop(
      child: child,
      duration: duration,
      curve: curve,
    );
  }

  // Body slide from bottom animation
  static Widget bodySlideFromBottom({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOutCubic,
  }) {
    return BodySlideFromBottom(
      child: child,
      duration: duration,
      curve: curve,
    );
  }

  // Combined app bar and body animation
  static Widget screenSlideAnimation({
    required Widget appBar,
    required Widget body,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOutCubic,
    bool enableStaggered = true,
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    return ScreenSlideAnimation(
      appBar: appBar,
      body: body,
      duration: duration,
      curve: curve,
      enableStaggered: enableStaggered,
      staggerDelay: staggerDelay,
    );
  }
}

// Particle Burst Animation
class ParticleBurst extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;
  final Color particleColor;
  final int particleCount;
  final Duration duration;

  const ParticleBurst({
    super.key,
    required this.child,
    required this.onComplete,
    this.particleColor = Colors.amber,
    this.particleCount = 20,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _particleAnimations;
  late List<Animation<Offset>> _particlePositions;
  late List<Animation<double>> _particleScales;
  late List<Animation<double>> _particleOpacities;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particleAnimations = List.generate(
      widget.particleCount,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index / widget.particleCount,
          (index + 1) / widget.particleCount,
          curve: Curves.easeOut,
        ),
      )),
    );

    _particlePositions = List.generate(
      widget.particleCount,
      (index) => Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          math.cos(index * 2 * math.pi / widget.particleCount) * 100,
          math.sin(index * 2 * math.pi / widget.particleCount) * 100,
        ),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      )),
    );

    _particleScales = List.generate(
      widget.particleCount,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index / widget.particleCount,
          (index + 1) / widget.particleCount,
          curve: Curves.elasticOut,
        ),
      )),
    );

    _particleOpacities = List.generate(
      widget.particleCount,
      (index) => Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.7,
          1.0,
          curve: Curves.easeOut,
        ),
      )),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ...List.generate(widget.particleCount, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 +
                    _particlePositions[index].value.dx,
                top: MediaQuery.of(context).size.height / 2 +
                    _particlePositions[index].value.dy,
                child: Transform.scale(
                  scale: _particleScales[index].value,
                  child: Opacity(
                    opacity: _particleOpacities[index].value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.particleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// Floating Animation
class FloatingAnimation extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final Curve curve;

  const FloatingAnimation({
    super.key,
    required this.child,
    this.amplitude = 8.0,
    this.duration = const Duration(seconds: 2),
    this.curve = Curves.easeInOut,
  });

  @override
  State<FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<FloatingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_animation.value * 2 * math.pi) * widget.amplitude,
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Bounce Animation
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// Shake Animation
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(_animation.value * 20) * 10 * _animation.value,
            0,
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Pulse Animation
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.1 * math.sin(_animation.value * 2 * math.pi),
          child: widget.child,
        );
      },
    );
  }
}

// Slide In Bounce Animation
class SlideInBounce extends StatefulWidget {
  final Widget child;
  final Offset begin;
  final Duration duration;

  const SlideInBounce({
    super.key,
    required this.child,
    this.begin = const Offset(0, 1),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<SlideInBounce> createState() => _SlideInBounceState();
}

class _SlideInBounceState extends State<SlideInBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Rotate Scale Animation
class RotateScale extends StatefulWidget {
  final Widget child;
  final double rotation;
  final double scale;
  final Duration duration;

  const RotateScale({
    super.key,
    required this.child,
    this.rotation = 360,
    this.scale = 1.2,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<RotateScale> createState() => _RotateScaleState();
}

class _RotateScaleState extends State<RotateScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotation * math.pi / 180,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// App Bar Slide From Top Animation
class AppBarSlideFromTop extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AppBarSlideFromTop({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AppBarSlideFromTop> createState() => _AppBarSlideFromTopState();
}

class _AppBarSlideFromTopState extends State<AppBarSlideFromTop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Body Slide From Bottom Animation
class BodySlideFromBottom extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const BodySlideFromBottom({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<BodySlideFromBottom> createState() => _BodySlideFromBottomState();
}

class _BodySlideFromBottomState extends State<BodySlideFromBottom>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Combined Screen Slide Animation
class ScreenSlideAnimation extends StatefulWidget {
  final Widget appBar;
  final Widget body;
  final Duration duration;
  final Curve curve;
  final bool enableStaggered;
  final Duration staggerDelay;

  const ScreenSlideAnimation({
    super.key,
    required this.appBar,
    required this.body,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.enableStaggered = true,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  State<ScreenSlideAnimation> createState() => _ScreenSlideAnimationState();
}

class _ScreenSlideAnimationState extends State<ScreenSlideAnimation>
    with TickerProviderStateMixin {
  late AnimationController _appBarController;
  late AnimationController _bodyController;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<Offset> _bodySlideAnimation;
  late Animation<double> _appBarOpacityAnimation;
  late Animation<double> _bodyOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _appBarController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _bodyController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _appBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: widget.curve,
    ));

    _bodySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bodyController,
      curve: widget.curve,
    ));

    _appBarOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: Curves.easeIn,
    ));

    _bodyOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bodyController,
      curve: Curves.easeIn,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _appBarController.forward();
    
    if (widget.enableStaggered) {
      Future.delayed(widget.staggerDelay, () {
        if (mounted) {
          _bodyController.forward();
        }
      });
    } else {
      _bodyController.forward();
    }
  }

  @override
  void dispose() {
    _appBarController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _appBarController,
          builder: (context, child) {
            return SlideTransition(
              position: _appBarSlideAnimation,
              child: FadeTransition(
                opacity: _appBarOpacityAnimation,
                child: widget.appBar,
              ),
            );
          },
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _bodyController,
            builder: (context, child) {
              return SlideTransition(
                position: _bodySlideAnimation,
                child: FadeTransition(
                  opacity: _bodyOpacityAnimation,
                  child: widget.body,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
