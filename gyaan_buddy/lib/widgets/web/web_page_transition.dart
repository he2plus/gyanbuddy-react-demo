import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Direction from which the page enters
enum PageDirection { top, bottom, left, right }

/// Type of animation effect
enum PageAnimationType { fade, bounce, elastic, jiggly, scale, slideAndFade, spring }

/// Smooth animated page switcher with random transitions
/// Optimized for fluid, natural-feeling animations
class AnimatedPageSwitcher extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Duration duration;
  final bool randomizeDirection;
  final bool randomizeEffect;

  const AnimatedPageSwitcher({
    super.key,
    required this.child,
    required this.currentIndex,
    this.duration = const Duration(milliseconds: 320),
    this.randomizeDirection = true,
    this.randomizeEffect = true,
  });

  @override
  State<AnimatedPageSwitcher> createState() => _AnimatedPageSwitcherState();
}

class _AnimatedPageSwitcherState extends State<AnimatedPageSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  final math.Random _random = math.Random();
  int _lastIndex = -1;
  PageDirection _currentDirection = PageDirection.right;
  PageAnimationType _currentType = PageAnimationType.slideAndFade;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.currentIndex;
    _initController();
  }

  void _initController() {
    // Adjust duration based on effect type for natural feel
    Duration adjustedDuration = widget.duration;
    switch (_currentType) {
      case PageAnimationType.bounce:
        adjustedDuration = const Duration(milliseconds: 420);
        break;
      case PageAnimationType.elastic:
        adjustedDuration = const Duration(milliseconds: 450);
        break;
      case PageAnimationType.jiggly:
        adjustedDuration = const Duration(milliseconds: 350);
        break;
      case PageAnimationType.spring:
        adjustedDuration = const Duration(milliseconds: 280);
        break;
      default:
        adjustedDuration = widget.duration;
    }

    _controller = AnimationController(
      duration: adjustedDuration,
      vsync: this,
    );
    _setupAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _lastIndex = oldWidget.currentIndex;
      
      // Randomize direction and effect
      if (widget.randomizeDirection) {
        _currentDirection = PageDirection.values[_random.nextInt(PageDirection.values.length)];
      }
      if (widget.randomizeEffect) {
        _currentType = PageAnimationType.values[_random.nextInt(PageAnimationType.values.length)];
      }
      
      _controller.dispose();
      _initController();
    }
  }

  Offset _getOffset() {
    // Subtle offset for smooth, elegant movement
    switch (_currentDirection) {
      case PageDirection.top:
        return const Offset(0, -0.06);
      case PageDirection.bottom:
        return const Offset(0, 0.06);
      case PageDirection.left:
        return const Offset(-0.06, 0);
      case PageDirection.right:
        return const Offset(0.06, 0);
    }
  }

  Curve _getCurve() {
    // Smooth, refined curves for each effect
    switch (_currentType) {
      case PageAnimationType.fade:
        return Curves.easeOutQuart;
      case PageAnimationType.bounce:
        return Curves.easeOutBack;
      case PageAnimationType.elastic:
        return Curves.easeOutCubic;
      case PageAnimationType.jiggly:
        return Curves.easeOutQuart;
      case PageAnimationType.scale:
        return Curves.easeOutCubic;
      case PageAnimationType.slideAndFade:
        return Curves.easeOutQuart;
      case PageAnimationType.spring:
        return Curves.easeOutExpo;
    }
  }

  void _setupAnimations() {
    final curve = _getCurve();
    Offset offset = _getOffset();
    
    // Adjust offset based on animation type
    double offsetMultiplier = 1.0;
    double fadeEnd = 0.35;
    
    switch (_currentType) {
      case PageAnimationType.fade:
        offsetMultiplier = 0.4;
        fadeEnd = 0.45;
        break;
      case PageAnimationType.bounce:
        offsetMultiplier = 1.8;
        break;
      case PageAnimationType.elastic:
        offsetMultiplier = 1.5;
        break;
      case PageAnimationType.jiggly:
        offsetMultiplier = 0.8;
        break;
      case PageAnimationType.scale:
        offsetMultiplier = 0.3;
        fadeEnd = 0.4;
        break;
      case PageAnimationType.slideAndFade:
        offsetMultiplier = 2.2;
        fadeEnd = 0.3;
        break;
      case PageAnimationType.spring:
        offsetMultiplier = 1.0;
        fadeEnd = 0.25;
        break;
    }
    
    offset = Offset(offset.dx * offsetMultiplier, offset.dy * offsetMultiplier);
    
    // Smooth fade with refined easing
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, fadeEnd, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: curve,
    ));
    
    // Subtle scale for depth
    double startScale = 1.0;
    switch (_currentType) {
      case PageAnimationType.scale:
        startScale = 0.94;
        break;
      case PageAnimationType.bounce:
        startScale = 0.96;
        break;
      case PageAnimationType.elastic:
        startScale = 0.97;
        break;
      case PageAnimationType.jiggly:
        startScale = 0.98;
        break;
      case PageAnimationType.spring:
        startScale = 0.98;
        break;
      default:
        startScale = 0.99;
    }
    
    _scaleAnimation = Tween<double>(
      begin: startScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: curve,
    ));
    
    // Subtle rotation for jiggly effect
    double rotationAmount = 0.0;
    if (_currentType == PageAnimationType.jiggly) {
      rotationAmount = 0.01; // Very subtle wobble
    }
    
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: rotationAmount, end: -rotationAmount * 0.35)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -rotationAmount * 0.35, end: rotationAmount * 0.1)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 1.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: rotationAmount * 0.1, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 1,
      ),
    ]).animate(_controller);
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
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Web-specific animated page transition with random directions and effects
class WebPageTransition extends StatefulWidget {
  final Widget child;
  final int pageIndex;
  final Duration duration;
  final bool randomizeDirection;
  final bool randomizeEffect;
  final PageDirection? forcedDirection;
  final PageAnimationType? forcedAnimationType;

  const WebPageTransition({
    super.key,
    required this.child,
    required this.pageIndex,
    this.duration = const Duration(milliseconds: 320),
    this.randomizeDirection = true,
    this.randomizeEffect = true,
    this.forcedDirection,
    this.forcedAnimationType,
  });

  @override
  State<WebPageTransition> createState() => _WebPageTransitionState();
}

class _WebPageTransitionState extends State<WebPageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  late PageDirection _direction;
  late PageAnimationType _animationType;
  
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(WebPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
      _randomizeAndRestart();
    }
  }

  void _initializeAnimations() {
    _direction = widget.forcedDirection ?? _getRandomDirection();
    _animationType = widget.forcedAnimationType ?? _getRandomAnimationType();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _setupAnimations();
    _controller.forward();
  }

  void _randomizeAndRestart() {
    if (widget.randomizeDirection) {
      _direction = _getRandomDirection();
    }
    if (widget.randomizeEffect) {
      _animationType = _getRandomAnimationType();
    }
    
    _setupAnimations();
    _controller.reset();
    _controller.forward();
  }

  PageDirection _getRandomDirection() {
    final directions = PageDirection.values;
    return directions[_random.nextInt(directions.length)];
  }

  PageAnimationType _getRandomAnimationType() {
    final types = PageAnimationType.values;
    return types[_random.nextInt(types.length)];
  }

  Offset _getDirectionalOffset() {
    switch (_direction) {
      case PageDirection.top:
        return const Offset(0, -0.06);
      case PageDirection.bottom:
        return const Offset(0, 0.06);
      case PageDirection.left:
        return const Offset(-0.06, 0);
      case PageDirection.right:
        return const Offset(0.06, 0);
    }
  }

  Curve _getCurveForAnimationType() {
    switch (_animationType) {
      case PageAnimationType.fade:
        return Curves.easeOutQuart;
      case PageAnimationType.bounce:
        return Curves.easeOutBack;
      case PageAnimationType.elastic:
        return Curves.easeOutCubic;
      case PageAnimationType.jiggly:
        return Curves.easeOutQuart;
      case PageAnimationType.scale:
        return Curves.easeOutCubic;
      case PageAnimationType.slideAndFade:
        return Curves.easeOutQuart;
      case PageAnimationType.spring:
        return Curves.easeOutExpo;
    }
  }

  void _setupAnimations() {
    final curve = _getCurveForAnimationType();
    Offset offset = _getDirectionalOffset();
    
    double offsetMultiplier = 1.0;
    switch (_animationType) {
      case PageAnimationType.fade:
        offsetMultiplier = 0.4;
        break;
      case PageAnimationType.bounce:
        offsetMultiplier = 1.8;
        break;
      case PageAnimationType.elastic:
        offsetMultiplier = 1.5;
        break;
      case PageAnimationType.jiggly:
        offsetMultiplier = 0.8;
        break;
      case PageAnimationType.scale:
        offsetMultiplier = 0.3;
        break;
      case PageAnimationType.slideAndFade:
        offsetMultiplier = 2.2;
        break;
      case PageAnimationType.spring:
        offsetMultiplier = 1.0;
        break;
    }
    
    offset = Offset(offset.dx * offsetMultiplier, offset.dy * offsetMultiplier);
    
    // Smooth fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));
    
    // Smooth slide with direction
    _slideAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: curve,
    ));
    
    // Subtle scale animation
    double startScale = 1.0;
    switch (_animationType) {
      case PageAnimationType.scale:
        startScale = 0.94;
        break;
      case PageAnimationType.bounce:
        startScale = 0.96;
        break;
      case PageAnimationType.elastic:
        startScale = 0.97;
        break;
      case PageAnimationType.jiggly:
        startScale = 0.98;
        break;
      default:
        startScale = 0.99;
    }
    
    _scaleAnimation = Tween<double>(
      begin: startScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: curve,
    ));
    
    // Subtle rotation for jiggly effect
    double rotationAmount = 0.0;
    if (_animationType == PageAnimationType.jiggly) {
      rotationAmount = 0.01;
    }
    
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: rotationAmount, end: -rotationAmount * 0.35),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -rotationAmount * 0.35, end: rotationAmount * 0.1),
        weight: 1.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: rotationAmount * 0.1, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
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
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom page route with random directional animation
class RandomDirectionPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  static final math.Random _random = math.Random();
  
  RandomDirectionPageRoute({
    required this.page,
    Duration transitionDuration = const Duration(milliseconds: 320),
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Random direction with subtle offset
      final direction = PageDirection.values[_random.nextInt(PageDirection.values.length)];
      final animationType = PageAnimationType.values[_random.nextInt(PageAnimationType.values.length)];
      
      Offset beginOffset;
      switch (direction) {
        case PageDirection.top:
          beginOffset = const Offset(0, -0.06);
          break;
        case PageDirection.bottom:
          beginOffset = const Offset(0, 0.06);
          break;
        case PageDirection.left:
          beginOffset = const Offset(-0.06, 0);
          break;
        case PageDirection.right:
          beginOffset = const Offset(0.06, 0);
          break;
      }
      
      Curve curve;
      double offsetMultiplier = 1.0;
      double startScale = 0.99;
      
      switch (animationType) {
        case PageAnimationType.fade:
          curve = Curves.easeOutQuart;
          offsetMultiplier = 0.4;
          break;
        case PageAnimationType.bounce:
          curve = Curves.easeOutBack;
          offsetMultiplier = 1.8;
          startScale = 0.96;
          break;
        case PageAnimationType.elastic:
          curve = Curves.easeOutCubic;
          offsetMultiplier = 1.5;
          startScale = 0.97;
          break;
        case PageAnimationType.jiggly:
          curve = Curves.easeOutQuart;
          offsetMultiplier = 0.8;
          startScale = 0.98;
          break;
        case PageAnimationType.scale:
          curve = Curves.easeOutCubic;
          offsetMultiplier = 0.3;
          startScale = 0.94;
          break;
        case PageAnimationType.slideAndFade:
          curve = Curves.easeOutQuart;
          offsetMultiplier = 2.2;
          break;
        case PageAnimationType.spring:
          curve = Curves.easeOutExpo;
          startScale = 0.98;
          break;
      }
      
      beginOffset = Offset(beginOffset.dx * offsetMultiplier, beginOffset.dy * offsetMultiplier);
      
      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve));
      
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ));
      
      final scaleAnimation = Tween<double>(
        begin: startScale,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: curve));
      
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}
