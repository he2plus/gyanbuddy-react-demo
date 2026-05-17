import 'package:flutter/material.dart';
import 'dart:math' as math;

class EnhancedTransitions {
  // Hero-like shared element transition
  static PageRouteBuilder<T> heroTransition<T>({
    required Widget page,
    required String tag,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return Hero(
          tag: tag,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  // 3D flip transition
  static PageRouteBuilder<T> flipTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Axis axis = Axis.vertical,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final angle = animation.value * math.pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(axis == Axis.horizontal ? angle : 0)
                ..rotateY(axis == Axis.vertical ? angle : 0),
              child: child,
            );
          },
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  // Scale and fade transition
  static PageRouteBuilder<T> scaleFadeTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
    double beginScale = 0.8,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: beginScale,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  // Slide with bounce transition
  static PageRouteBuilder<T> slideBounceTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
    Offset begin = const Offset(1.0, 0.0),
    Curve curve = Curves.elasticOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  // Parallax transition
  static PageRouteBuilder<T> parallaxTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    double parallaxValue = 0.5,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                (1 - animation.value) * parallaxValue * 100,
                0,
              ),
              child: child,
            );
          },
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  // Morphing transition
  static PageRouteBuilder<T> morphingTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(curvedAnimation.value * 0.1)
                ..scale(0.9 + curvedAnimation.value * 0.1),
              child: Opacity(
                opacity: curvedAnimation.value,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  // Staggered entrance transition
  static PageRouteBuilder<T> staggeredEntranceTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }
}

// Staggered Entrance Widget
class StaggeredEntrance extends StatefulWidget {
  final Animation<double> animation;
  final Duration staggerDelay;
  final Widget child;

  const StaggeredEntrance({
    super.key,
    required this.animation,
    required this.staggerDelay,
    required this.child,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Find all child widgets that can be animated
    final childCount = _getChildCount(widget.child);
    
    _controllers = List.generate(
      childCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
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

  int _getChildCount(Widget widget) {
    if (widget is Column || widget is Row) {
      // For Column/Row, count the children
      return 5; // Default count for staggered effect
    }
    return 3; // Default count for other widgets
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
    return widget.child;
  }
}

// Enhanced Hero Widget with custom transitions
class EnhancedHero extends StatefulWidget {
  final String tag;
  final Widget child;
  final Duration flightDuration;
  final Curve flightCurve;

  const EnhancedHero({
    super.key,
    required this.tag,
    required this.child,
    this.flightDuration = const Duration(milliseconds: 400),
    this.flightCurve = Curves.easeInOutCubic,
  });

  @override
  State<EnhancedHero> createState() => _EnhancedHeroState();
}

class _EnhancedHeroState extends State<EnhancedHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.flightDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.flightCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.flightCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: widget.child,
              ),
            );
          },
        );
      },
      child: widget.child,
    );
  }
}

// Shared Element Transition Widget
class SharedElementTransition extends StatefulWidget {
  final Widget child;
  final String tag;
  final Duration duration;
  final Curve curve;

  const SharedElementTransition({
    super.key,
    required this.child,
    required this.tag,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  State<SharedElementTransition> createState() => _SharedElementTransitionState();
}

class _SharedElementTransitionState extends State<SharedElementTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
