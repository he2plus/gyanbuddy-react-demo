import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Connected Page Transitions - A unified animation system that makes
/// your entire app feel cohesive with smooth scale up/down transitions.
/// 
/// Key principles:
/// 1. When navigating forward: current screen scales DOWN + fades, new screen scales UP
/// 2. When navigating back: current screen scales UP, previous screen scales DOWN + fades in
/// 3. Subtle parallax effects for depth
/// 4. Consistent timing and curves across all transitions

class ConnectedPageTransitions {
  // Unified durations for consistency
  static const Duration defaultDuration = Duration(milliseconds: 400);
  static const Duration fastDuration = Duration(milliseconds: 280);
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  // Unified curves for connected feel
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.easeOutBack;

  /// The main connected transition - scales the current screen down
  /// while the new screen scales up from a smaller size
  static PageRouteBuilder<T> connectedScale<T>({
    required Widget page,
    Duration duration = defaultDuration,
    bool reverse = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming page animation (scales up from 0.88)
        final scaleAnimation = Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: enterCurve),
        ));

        // Fade in for incoming page
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

        // Outgoing page scales down slightly
        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 0.92,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        // Outgoing page fades
        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            // Apply both incoming and outgoing effects
            double scale = scaleAnimation.value;
            double opacity = fadeAnimation.value;

            // If this is the page being replaced (secondaryAnimation is active)
            if (secondaryAnimation.status == AnimationStatus.forward ||
                secondaryAnimation.status == AnimationStatus.reverse) {
              scale *= secondaryScaleAnimation.value;
              opacity *= secondaryFadeAnimation.value;
            }

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  /// Scale inward transition - current screen scales UP (zooms away)
  /// while the new screen scales DOWN from a larger size
  /// Perfect for drilling into content (subject -> chapter)
  static PageRouteBuilder<T> scaleInward<T>({
    required Widget page,
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming page animation (scales DOWN from 1.15 to 1.0)
        final scaleAnimation = Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: enterCurve),
        ));

        // Fade in for incoming page
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));

        // Outgoing page scales UP (zooms away)
        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.25,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        // Outgoing page fades out
        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            // Apply both incoming and outgoing effects
            double scale = scaleAnimation.value;
            double opacity = fadeAnimation.value;

            // If this is the page being replaced (secondaryAnimation is active)
            if (secondaryAnimation.status == AnimationStatus.forward ||
                secondaryAnimation.status == AnimationStatus.reverse) {
              scale *= secondaryScaleAnimation.value;
              opacity *= secondaryFadeAnimation.value;
            }

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  /// Zoom transition - perfect for drilling into content
  /// Current screen zooms away while new screen zooms in
  static PageRouteBuilder<T> connectedZoom<T>({
    required Widget page,
    Duration duration = defaultDuration,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming page zooms in from small
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: bounceCurve,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));

        // Outgoing page zooms out
        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.5,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeIn,
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            double scale = scaleAnimation.value;
            double opacity = fadeAnimation.value;

            if (secondaryAnimation.status == AnimationStatus.forward) {
              scale = secondaryScaleAnimation.value;
              opacity = secondaryFadeAnimation.value;
            }

            return Transform.scale(
              alignment: alignment,
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  /// Shared axis transition - feels like elements are connected
  /// Perfect for lateral navigation (tabs, pagination)
  static PageRouteBuilder<T> sharedAxisHorizontal<T>({
    required Widget page,
    Duration duration = defaultDuration,
    bool forward = true,
  }) {
    final direction = forward ? 1.0 : -1.0;
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming slide + scale
        final slideAnimation = Tween<Offset>(
          begin: Offset(0.15 * direction, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        ));

        final scaleAnimation = Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

        // Outgoing slide + scale
        final secondarySlideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(-0.15 * direction, 0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 0.94,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            Offset offset = slideAnimation.value;
            double scale = scaleAnimation.value;
            double opacity = fadeAnimation.value;

            if (secondaryAnimation.status == AnimationStatus.forward) {
              offset = secondarySlideAnimation.value;
              scale = secondaryScaleAnimation.value;
              opacity = secondaryFadeAnimation.value;
            }

            return Transform.translate(
              offset: Offset(
                offset.dx * MediaQuery.of(context).size.width,
                offset.dy,
              ),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shared axis vertical - for hierarchical navigation
  static PageRouteBuilder<T> sharedAxisVertical<T>({
    required Widget page,
    Duration duration = defaultDuration,
    bool forward = true,
  }) {
    final direction = forward ? 1.0 : -1.0;
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming slide + scale
        final slideAnimation = Tween<Offset>(
          begin: Offset(0, 0.08 * direction),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        ));

        final scaleAnimation = Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));

        // Outgoing slide + scale
        final secondarySlideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(0, -0.05 * direction),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.1, 0.7, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            Offset offset = slideAnimation.value;
            double scale = scaleAnimation.value;
            double opacity = fadeAnimation.value;

            if (secondaryAnimation.status == AnimationStatus.forward) {
              offset = secondarySlideAnimation.value;
              scale = secondaryScaleAnimation.value;
              opacity = secondaryFadeAnimation.value;
            }

            return Transform.translate(
              offset: Offset(
                0,
                offset.dy * MediaQuery.of(context).size.height,
              ),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Container transform - the element expands to become the new screen
  /// Best for cards/items that lead to detail screens
  static PageRouteBuilder<T> containerTransform<T>({
    required Widget page,
    Duration duration = slowDuration,
    Color? scrimColor,
    Alignment? originAlignment,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        );

        // Scale from small to full
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        // Fade in
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        ));

        // Scrim (background overlay)
        final scrimAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        ));

        return Stack(
          children: [
            // Scrim background
            if (scrimColor != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: scrimAnimation,
                  builder: (context, _) {
                    return Container(
                      color: scrimColor.withOpacity(
                        scrimAnimation.value * 0.5,
                      ),
                    );
                  },
                ),
              ),
            // Main content with scale and fade
            AnimatedBuilder(
              animation: curvedAnimation,
              builder: (context, _) {
                return Transform.scale(
                  alignment: originAlignment ?? Alignment.center,
                  scale: scaleAnimation.value,
                  child: Opacity(
                    opacity: fadeAnimation.value,
                    child: child,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Fade through transition - elegant for switching between views
  static PageRouteBuilder<T> fadeThrough<T>({
    required Widget page,
    Duration duration = fastDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming: fade in + scale up slightly
        final fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ));

        final scaleIn = Tween<double>(
          begin: 0.96,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ));

        // Outgoing: fade out + scale down slightly
        final fadeOut = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        ));

        final scaleOut = Tween<double>(
          begin: 1.0,
          end: 0.96,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            double opacity = fadeIn.value;
            double scale = scaleIn.value;

            if (secondaryAnimation.status == AnimationStatus.forward) {
              opacity = fadeOut.value;
              scale = scaleOut.value;
            }

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  /// Depth transition - creates a sense of Z-axis movement
  static PageRouteBuilder<T> depthTransition<T>({
    required Widget page,
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming: comes from behind (small) to front (full size)
        final scaleAnimation = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

        // Slight slide up for parallax depth effect
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        ));

        // Outgoing: pushes to background
        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 0.88,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
        ));

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          builder: (context, _) {
            double scale = scaleAnimation.value;
            double opacity = fadeAnimation.value;
            Offset offset = slideAnimation.value;

            if (secondaryAnimation.status == AnimationStatus.forward) {
              scale = secondaryScaleAnimation.value;
              opacity = secondaryFadeAnimation.value;
              offset = Offset.zero;
            }

            return Transform.translate(
              offset: Offset(0, offset.dy * MediaQuery.of(context).size.height),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Circle expand transition - expands from center with color change
  /// Perfect for transitioning from loading screen to home screen
  static PageRouteBuilder<T> circleExpand<T>({
    required Widget page,
    Color startColor = Colors.white,
    Color endColor = const Color(0xFF365DEA),
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _CircleExpandTransitionWidget(
          animation: animation,
          startColor: startColor,
          endColor: endColor,
          curve: curve,
          child: child,
        );
      },
    );
  }

  /// Circle reveal transition - clean circular reveal effect
  static PageRouteBuilder<T> circleReveal<T>({
    required Widget page,
    Color overlayColor = Colors.white,
    Duration duration = const Duration(milliseconds: 700),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final size = MediaQuery.of(context).size;
        final maxRadius = math.sqrt(
          (size.width / 2) * (size.width / 2) + 
          (size.height / 2) * (size.height / 2)
        ) + 50;

        final radiusAnimation = Tween<double>(
          begin: 0.0,
          end: maxRadius,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Stack(
              children: [
                // Overlay background that fades out
                Positioned.fill(
                  child: Container(
                    color: overlayColor.withOpacity(1 - fadeAnimation.value),
                  ),
                ),
                // Clipped content
                ClipPath(
                  clipper: _CircleRevealClipper(
                    radius: radiusAnimation.value,
                    center: Offset(size.width / 2, size.height / 2),
                  ),
                  child: child,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A widget that wraps pages to provide consistent entrance/exit animations
class AnimatedPageWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool enableScale;
  final bool enableFade;
  final bool enableSlide;
  final double scaleStart;
  final Offset slideOffset;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.enableScale = true,
    this.enableFade = true,
    this.enableSlide = false,
    this.scaleStart = 0.95,
    this.slideOffset = const Offset(0, 0.02),
  });

  @override
  State<AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<AnimatedPageWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.scaleStart,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
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
        Widget result = widget.child;

        if (widget.enableSlide) {
          result = Transform.translate(
            offset: Offset(
              _slideAnimation.value.dx * MediaQuery.of(context).size.width,
              _slideAnimation.value.dy * MediaQuery.of(context).size.height,
            ),
            child: result,
          );
        }

        if (widget.enableScale) {
          result = Transform.scale(
            scale: _scaleAnimation.value,
            child: result,
          );
        }

        if (widget.enableFade) {
          result = Opacity(
            opacity: _fadeAnimation.value,
            child: result,
          );
        }

        return result;
      },
    );
  }
}

/// Enhanced AnimatedPageSwitcher for tab-like navigation
/// Provides connected animations when switching between pages
class ConnectedPageSwitcher extends StatefulWidget {
  final int currentIndex;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const ConnectedPageSwitcher({
    super.key,
    required this.currentIndex,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ConnectedPageSwitcher> createState() => _ConnectedPageSwitcherState();
}

class _ConnectedPageSwitcherState extends State<ConnectedPageSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ConnectedPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGoingForward = widget.currentIndex > _previousIndex;

    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: widget.curve,
      switchOutCurve: widget.curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Determine if this is the incoming or outgoing child
        final isEntering = child.key == widget.child.key;
        
        // Scale animation
        final scaleAnimation = Tween<double>(
          begin: isEntering ? 0.92 : 1.0,
          end: isEntering ? 1.0 : 0.92,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: widget.curve,
        ));

        // Slide animation based on direction
        final slideOffset = isGoingForward
            ? (isEntering ? const Offset(0.08, 0) : const Offset(-0.08, 0))
            : (isEntering ? const Offset(-0.08, 0) : const Offset(0.08, 0));

        final slideAnimation = Tween<Offset>(
          begin: isEntering ? slideOffset : Offset.zero,
          end: isEntering ? Offset.zero : slideOffset,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: widget.curve,
        ));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(widget.currentIndex),
        child: widget.child,
      ),
    );
  }
}

/// A smoother page switcher that animates between tab content
class SmoothPageSwitcher extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final Duration duration;

  const SmoothPageSwitcher({
    super.key,
    required this.currentIndex,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final scaleAnimation = Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey(currentIndex),
        child: child,
      ),
    );
  }
}

/// Circle Expand Transition - The signature transition where a circle
/// expands from the center to fill the screen while changing color,
/// revealing the new page content beneath.
/// 
/// This is used when transitioning from the loading screen to home screen.
class CircleExpandTransition extends PageRouteBuilder {
  final Widget page;
  final Color startColor;
  final Color endColor;
  final Duration duration;
  final Curve curve;

  CircleExpandTransition({
    required this.page,
    this.startColor = Colors.white,
    this.endColor = const Color(0xFF365DEA),
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _CircleExpandTransitionWidget(
              animation: animation,
              child: child,
              startColor: startColor,
              endColor: endColor,
              curve: curve,
            );
          },
        );
}

class _CircleExpandTransitionWidget extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final Color startColor;
  final Color endColor;
  final Curve curve;

  const _CircleExpandTransitionWidget({
    required this.animation,
    required this.child,
    required this.startColor,
    required this.endColor,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Calculate max radius to cover entire screen from center
    final maxRadius = math.sqrt(
      (size.width / 2) * (size.width / 2) + 
      (size.height / 2) * (size.height / 2)
    ) + 50;

    // Animation phases:
    // 0.0-0.4: Circle is fully covering, color transitions
    // 0.4-1.0: Circle shrinks to reveal content beneath
    
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    // Color transition animation (during first phase)
    final colorAnimation = ColorTween(
      begin: startColor,
      end: endColor,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));

    // Circle shrink animation (starts at max, shrinks to 0)
    final radiusAnimation = Tween<double>(
      begin: maxRadius,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.25, 1.0, curve: Curves.easeInOutCubic),
    ));

    // Content fade in animation
    final contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    ));

    // Content scale animation (subtle scale up)
    final contentScaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // The new page content (appears beneath the circle)
            Opacity(
              opacity: contentFadeAnimation.value,
              child: Transform.scale(
                scale: contentScaleAnimation.value,
                child: child,
              ),
            ),
            
            // The expanding/shrinking circle overlay
            if (radiusAnimation.value > 0)
              Positioned.fill(
                child: ClipPath(
                  clipper: _InvertedCircleClipper(
                    radius: radiusAnimation.value,
                    center: Offset(size.width / 2, size.height / 2),
                  ),
                  child: Container(
                    color: colorAnimation.value ?? startColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Custom clipper that clips everything EXCEPT a circle in the center
/// This creates the effect of a circle shrinking to reveal content
class _InvertedCircleClipper extends CustomClipper<Path> {
  final double radius;
  final Offset center;

  _InvertedCircleClipper({
    required this.radius,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    // Create a path that covers the entire screen
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create a circular path
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Combine using difference - this gives us everything EXCEPT the circle
    // Actually, we want the circle to be filled, so we just return the circle path
    return circlePath;
  }

  @override
  bool shouldReclip(_InvertedCircleClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

/// Alternative: Circle Reveal From Center - circle grows from center outward
/// revealing the new content (opposite of CircleExpandTransition)
class CircleRevealTransition extends PageRouteBuilder {
  final Widget page;
  final Color overlayColor;
  final Duration duration;

  CircleRevealTransition({
    required this.page,
    this.overlayColor = Colors.white,
    this.duration = const Duration(milliseconds: 700),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final size = MediaQuery.of(context).size;
            final maxRadius = math.sqrt(
              (size.width / 2) * (size.width / 2) + 
              (size.height / 2) * (size.height / 2)
            ) + 50;

            // Circle grows from 0 to max
            final radiusAnimation = Tween<double>(
              begin: 0.0,
              end: maxRadius,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            // Content fades in
            final contentFade = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            ));

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background (previous screen would be here)
                    Container(color: overlayColor),
                    
                    // New content revealed through circle
                    ClipPath(
                      clipper: _CircleRevealClipper(
                        radius: radiusAnimation.value,
                        center: Offset(size.width / 2, size.height / 2),
                      ),
                      child: Opacity(
                        opacity: contentFade.value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
}

/// Clipper for revealing content through a growing circle
class _CircleRevealClipper extends CustomClipper<Path> {
  final double radius;
  final Offset center;

  _CircleRevealClipper({
    required this.radius,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

/// Helper extension for easy navigation with connected transitions
extension ConnectedNavigator on NavigatorState {
  /// Push with connected scale transition
  Future<T?> pushConnected<T extends Object?>(Widget page) {
    return push(ConnectedPageTransitions.connectedScale<T>(page: page));
  }

  /// Push with depth transition
  Future<T?> pushDepth<T extends Object?>(Widget page) {
    return push(ConnectedPageTransitions.depthTransition<T>(page: page));
  }

  /// Push with zoom transition (good for cards/items)
  Future<T?> pushZoom<T extends Object?>(Widget page, {Alignment? alignment}) {
    return push(ConnectedPageTransitions.connectedZoom<T>(
      page: page,
      alignment: alignment ?? Alignment.center,
    ));
  }

  /// Push with scale inward transition (current scales UP, new scales DOWN)
  Future<T?> pushScaleInward<T extends Object?>(Widget page) {
    return push(ConnectedPageTransitions.scaleInward<T>(page: page));
  }

  /// Push with container transform
  Future<T?> pushContainer<T extends Object?>(Widget page, {Color? scrimColor}) {
    return push(ConnectedPageTransitions.containerTransform<T>(
      page: page,
      scrimColor: scrimColor,
    ));
  }

  /// Push replacement with connected transition
  Future<T?> pushReplacementConnected<T extends Object?, TO extends Object?>(
    Widget page,
  ) {
    return pushReplacement(
      ConnectedPageTransitions.connectedScale<T>(page: page),
    );
  }

  /// Push replacement with fade through
  Future<T?> pushReplacementFade<T extends Object?, TO extends Object?>(
    Widget page,
  ) {
    return pushReplacement(
      ConnectedPageTransitions.fadeThrough<T>(page: page),
    );
  }

  /// Push replacement with circle expand transition
  /// Perfect for transitioning from loading screen to home
  Future<T?> pushReplacementCircleExpand<T extends Object?, TO extends Object?>(
    Widget page, {
    Color startColor = Colors.white,
    Color endColor = const Color(0xFF365DEA),
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return pushReplacement(
      ConnectedPageTransitions.circleExpand<T>(
        page: page,
        startColor: startColor,
        endColor: endColor,
        duration: duration,
      ),
    );
  }

  /// Push replacement with circle reveal transition
  Future<T?> pushReplacementCircleReveal<T extends Object?, TO extends Object?>(
    Widget page, {
    Color overlayColor = Colors.white,
    Duration duration = const Duration(milliseconds: 700),
  }) {
    return pushReplacement(
      ConnectedPageTransitions.circleReveal<T>(
        page: page,
        overlayColor: overlayColor,
        duration: duration,
      ),
    );
  }
}

/// Staggered entrance animation for list items
class StaggeredEntranceItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double scaleStart;
  final Offset slideOffset;

  const StaggeredEntranceItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.scaleStart = 0.92,
    this.slideOffset = const Offset(0, 0.05),
  });

  @override
  State<StaggeredEntranceItem> createState() => _StaggeredEntranceItemState();
}

class _StaggeredEntranceItemState extends State<StaggeredEntranceItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.scaleStart,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation after staggered delay
    Future.delayed(widget.delay * widget.index, () {
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
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value.dx * MediaQuery.of(context).size.width,
            _slideAnimation.value.dy * MediaQuery.of(context).size.height,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

