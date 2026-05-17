import 'package:flutter/material.dart';
import '../utils/game_animations.dart';

/// A widget that provides animated app bar and body layout
/// App bar slides in from top, body slides in from bottom
class AnimatedScreenLayout extends StatefulWidget {
  final Widget? appBar;
  final Widget body;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableStaggeredAnimation;
  final Duration staggerDelay;

  const AnimatedScreenLayout({
    super.key,
    required this.appBar,
    required this.body,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationCurve = Curves.easeOutCubic,
    this.enableStaggeredAnimation = true,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedScreenLayout> createState() => _AnimatedScreenLayoutState();
}

class _AnimatedScreenLayoutState extends State<AnimatedScreenLayout>
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
    
    // App bar animation controller
    _appBarController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Body animation controller (staggered if enabled)
    _bodyController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // App bar slide animation (from top)
    _appBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start from above screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: widget.animationCurve,
    ));

    // Body slide animation (from bottom)
    _bodySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from below screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bodyController,
      curve: widget.animationCurve,
    ));

    // Opacity animations for smooth fade-in
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

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    // Start app bar animation immediately
    _appBarController.forward();
    
    // Start body animation with delay if staggered animation is enabled
    if (widget.enableStaggeredAnimation) {
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
      mainAxisSize: MainAxisSize.max,
      children: [
        // Animated App Bar
        widget.appBar !=null ? AnimatedBuilder(
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
        ):SizedBox(),
        
        // Animated Body
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

/// Enhanced version with bounce effects
class BouncyAnimatedScreenLayout extends StatefulWidget {
  final Widget appBar;
  final Widget body;
  final Duration animationDuration;
  final bool enableBounceEffect;
  final double bounceIntensity;

  const BouncyAnimatedScreenLayout({
    super.key,
    required this.appBar,
    required this.body,
    this.animationDuration = const Duration(milliseconds: 800),
    this.enableBounceEffect = true,
    this.bounceIntensity = 0.1,
  });

  @override
  State<BouncyAnimatedScreenLayout> createState() => _BouncyAnimatedScreenLayoutState();
}

class _BouncyAnimatedScreenLayoutState extends State<BouncyAnimatedScreenLayout>
    with TickerProviderStateMixin {
  late AnimationController _appBarController;
  late AnimationController _bodyController;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<Offset> _bodySlideAnimation;
  late Animation<double> _appBarScaleAnimation;
  late Animation<double> _bodyScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _appBarController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _bodyController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // App bar animations
    _appBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: widget.enableBounceEffect ? Curves.elasticOut : Curves.easeOutCubic,
    ));

    _appBarScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: Curves.elasticOut,
    ));

    // Body animations
    _bodySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bodyController,
      curve: widget.enableBounceEffect ? Curves.elasticOut : Curves.easeOutCubic,
    ));

    _bodyScaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bodyController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _appBarController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _bodyController.forward();
      }
    });
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated App Bar with bounce
        AnimatedBuilder(
          animation: _appBarController,
          builder: (context, child) {
            return SlideTransition(
              position: _appBarSlideAnimation,
              child: Transform.scale(
                scale: _appBarScaleAnimation.value,
                child: widget.appBar,
              ),
            );
          },
        ),
        
        // Animated Body with bounce
        Flexible(
          child: AnimatedBuilder(
            animation: _bodyController,
            builder: (context, child) {
              return SlideTransition(
                position: _bodySlideAnimation,
                child: Transform.scale(
                  scale: _bodyScaleAnimation.value,
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

/// Simple slide animations for quick implementation
class SimpleAnimatedScreenLayout extends StatefulWidget {
  final Widget appBar;
  final Widget body;
  final Duration duration;

  const SimpleAnimatedScreenLayout({
    super.key,
    required this.appBar,
    required this.body,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<SimpleAnimatedScreenLayout> createState() => _SimpleAnimatedScreenLayoutState();
}

class _SimpleAnimatedScreenLayoutState extends State<SimpleAnimatedScreenLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _appBarAnimation;
  late Animation<Offset> _bodyAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _appBarAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _bodyAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SlideTransition(
          position: _appBarAnimation,
          child: widget.appBar,
        ),
        Flexible(
          child: SlideTransition(
            position: _bodyAnimation,
            child: widget.body,
          ),
        ),
      ],
    );
  }
}
