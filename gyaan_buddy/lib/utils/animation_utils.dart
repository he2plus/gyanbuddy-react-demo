import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/vibration_service.dart';

/// Direction from which the page enters
enum TransitionDirection { top, bottom, left, right }

/// Type of animation effect
enum TransitionEffect { fade, bounce, elastic, jiggly, scale, slideAndFade, spring }

class AnimationUtils {
  // Common animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Common animation curves
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutBack = Curves.easeOutBack;

  // Random generator for transitions
  static final math.Random _random = math.Random();

  /// Random animated page transition - direction and effect are randomized
  /// Smooth, polished animations with natural timing
  static PageRouteBuilder<T> randomTransition<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 350),
    bool randomDirection = true,
    bool randomEffect = true,
  }) {
    final direction = randomDirection 
        ? TransitionDirection.values[_random.nextInt(TransitionDirection.values.length)]
        : TransitionDirection.right;
    final effect = randomEffect
        ? TransitionEffect.values[_random.nextInt(TransitionEffect.values.length)]
        : TransitionEffect.slideAndFade;
    
    return _buildTransition<T>(page, direction, effect, duration);
  }

  /// Random replacement transition for pushReplacement
  static PageRouteBuilder<T> randomReplacementTransition<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return randomTransition<T>(page, duration: duration);
  }

  static PageRouteBuilder<T> _buildTransition<T>(
    Widget page,
    TransitionDirection direction,
    TransitionEffect effect,
    Duration duration,
  ) {
    // Adjust duration based on effect for natural feel
    Duration adjustedDuration = duration;
    switch (effect) {
      case TransitionEffect.bounce:
        adjustedDuration = const Duration(milliseconds: 500);
        break;
      case TransitionEffect.elastic:
        adjustedDuration = const Duration(milliseconds: 550);
        break;
      case TransitionEffect.jiggly:
        adjustedDuration = const Duration(milliseconds: 400);
        break;
      case TransitionEffect.spring:
        adjustedDuration = const Duration(milliseconds: 300);
        break;
      default:
        adjustedDuration = duration;
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: adjustedDuration,
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Subtle offset for smooth movement - reduced for elegance
        Offset beginOffset;
        switch (direction) {
          case TransitionDirection.top:
            beginOffset = const Offset(0, -0.08);
            break;
          case TransitionDirection.bottom:
            beginOffset = const Offset(0, 0.08);
            break;
          case TransitionDirection.left:
            beginOffset = const Offset(-0.08, 0);
            break;
          case TransitionDirection.right:
            beginOffset = const Offset(0.08, 0);
            break;
        }

        // Smooth curves and subtle effects
        Curve curve;
        Curve fadeCurve;
        double startScale = 1.0;
        double rotationAmount = 0.0;
        double fadeStart = 0.0;
        double fadeEnd = 0.4;
        
        switch (effect) {
          case TransitionEffect.fade:
            curve = Curves.easeOutQuart;
            fadeCurve = Curves.easeOut;
            beginOffset = Offset(beginOffset.dx * 0.5, beginOffset.dy * 0.5);
            fadeEnd = 0.5;
            break;
          case TransitionEffect.bounce:
            curve = Curves.easeOutBack;
            fadeCurve = Curves.easeOut;
            startScale = 0.94;
            beginOffset = Offset(beginOffset.dx * 1.5, beginOffset.dy * 1.5);
            break;
          case TransitionEffect.elastic:
            curve = Curves.easeOutCubic;
            fadeCurve = Curves.easeOut;
            startScale = 0.96;
            beginOffset = Offset(beginOffset.dx * 1.2, beginOffset.dy * 1.2);
            break;
          case TransitionEffect.jiggly:
            curve = Curves.easeOutQuart;
            fadeCurve = Curves.easeOut;
            startScale = 0.98;
            rotationAmount = 0.012; // Subtle wobble
            break;
          case TransitionEffect.scale:
            curve = Curves.easeOutCubic;
            fadeCurve = Curves.easeOut;
            startScale = 0.92;
            beginOffset = Offset(beginOffset.dx * 0.3, beginOffset.dy * 0.3);
            break;
          case TransitionEffect.slideAndFade:
            curve = Curves.easeOutQuart;
            fadeCurve = Curves.easeOut;
            beginOffset = Offset(beginOffset.dx * 2.0, beginOffset.dy * 2.0);
            fadeEnd = 0.35;
            break;
          case TransitionEffect.spring:
            curve = Curves.easeOutExpo;
            fadeCurve = Curves.easeOutQuad;
            startScale = 0.97;
            fadeEnd = 0.25;
            break;
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        // Smooth fade-in with proper easing
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(fadeStart, fadeEnd, curve: fadeCurve),
        ));

        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curvedAnimation);

        final scaleAnimation = Tween<double>(
          begin: startScale,
          end: 1.0,
        ).animate(curvedAnimation);

        // Build rotation animation for jiggly effect - smooth and subtle
        Widget result = child;
        
        if (rotationAmount > 0) {
          final rotationAnimation = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween<double>(begin: rotationAmount, end: -rotationAmount * 0.4)
                  .chain(CurveTween(curve: Curves.easeOutQuad)),
              weight: 2,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: -rotationAmount * 0.4, end: rotationAmount * 0.15)
                  .chain(CurveTween(curve: Curves.easeInOutQuad)),
              weight: 1.5,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: rotationAmount * 0.15, end: 0.0)
                  .chain(CurveTween(curve: Curves.easeOutQuad)),
              weight: 1,
            ),
          ]).animate(animation);
          
          result = AnimatedBuilder(
            animation: rotationAnimation,
            builder: (context, child) => Transform.rotate(
              angle: rotationAnimation.value,
              child: child,
            ),
            child: result,
          );
        }

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: result,
            ),
          ),
        );
      },
    );
  }

  // Page transition animations
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: normal,
    );
  }

  static PageRouteBuilder<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: normal,
    );
  }

  static PageRouteBuilder<T> fadeIn<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: normal,
    );
  }

  static PageRouteBuilder<T> scaleIn<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(scale: animation, child: child);
      },
      transitionDuration: normal,
    );
  }

  // Button press animation
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = fast,
    double scale = 0.95,
    bool enableVibration = true,
  }) {
    return AnimatedButton(
      child: child,
      onPressed: onPressed,
      duration: duration,
      scale: scale,
      enableVibration: enableVibration,
    );
  }

  // Card entrance animation
  static Widget animatedCard({
    required Widget child,
    required int index,
    Duration duration = normal,
    Duration delay = Duration.zero,
  }) {
    return AnimatedCard(
      child: child,
      index: index,
      duration: duration,
      delay: delay,
    );
  }

  // Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration duration = normal,
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    return StaggeredList(
      duration: duration,
      staggerDelay: staggerDelay,
      children: children,
    );
  }
}

// Animated Button Widget
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  final double scale;
  final bool enableVibration;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = const Duration(milliseconds: 200),
    this.scale = 0.95,
    this.enableVibration = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
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
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () async {
        if (widget.enableVibration) {
          await VibrationService().lightVibration();
        }
        widget.onPressed();
      },
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

// Animated Card Widget
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration delay;

  const AnimatedCard({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Staggered List Widget
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;

  const StaggeredList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start staggered animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted && i < _controllers.length) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For single child, return it directly without Column wrapper
    // This prevents layout issues with full-screen widgets
    if (widget.children.length == 1) {
      return FadeTransition(
        opacity: _opacityAnimations[0],
        child: SlideTransition(
          position: _slideAnimations[0],
          child: widget.children[0],
        ),
      );
    }
    
    // For multiple children, use Column
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.children.length, (index) {
        return FadeTransition(
          opacity: _opacityAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}

// Ripple effect widget
class RippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final Duration duration;

  const RippleEffect({
    super.key,
    required this.child,
    this.rippleColor = Colors.white,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Offset? _rippleCenter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _rippleCenter = details.localPosition;
    });
    _controller.forward().then((_) {
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      child: Stack(
        children: [
          widget.child,
          if (_rippleCenter != null)
            Positioned(
              left: _rippleCenter!.dx - 20,
              top: _rippleCenter!.dy - 20,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.rippleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
