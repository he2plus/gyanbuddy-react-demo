import 'package:flutter/material.dart';
import '../services/sound_service.dart';

/// A wrapper widget that shows a splash/ripple effect when tapping anywhere.
/// For tappable widgets, both the widget's own splash AND this global splash
/// will show. If you want to exclude tappable widgets, see the alternative
/// implementation using gesture arena.
class GlobalSplashWrapper extends StatefulWidget {
  final Widget child;
  final Color? splashColor;
  final Duration splashDuration;

  const GlobalSplashWrapper({
    super.key,
    required this.child,
    this.splashColor,
    this.splashDuration = const Duration(milliseconds: 500),
  });

  @override
  State<GlobalSplashWrapper> createState() => _GlobalSplashWrapperState();
}

class _GlobalSplashWrapperState extends State<GlobalSplashWrapper> {
  final List<_SplashData> _splashes = [];
  int _splashIdCounter = 0;

  void _showSplash(Offset localPosition) {
    final splashId = _splashIdCounter++;
    
    // Play click sound when splash effect is shown
    // SoundService().playPlayClick();
    
    setState(() {
      _splashes.add(_SplashData(
        id: splashId,
        position: localPosition,
      ));
    });

    // Remove the splash after animation completes
    Future.delayed(widget.splashDuration + const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _splashes.removeWhere((s) => s.id == splashId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSplashColor = widget.splashColor ?? 
        theme.colorScheme.primary.withOpacity(0.2);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _showSplash(event.localPosition);
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // The actual app content
          widget.child,
          // Splash effects layer (non-interactive, on top)
          if (_splashes.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _splashes.map((splash) {
                    return Positioned(
                      left: splash.position.dx - 60,
                      top: splash.position.dy - 60,
                      child: _RippleAnimation(
                        key: ValueKey(splash.id),
                        color: effectiveSplashColor,
                        duration: widget.splashDuration,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashData {
  final int id;
  final Offset position;

  _SplashData({required this.id, required this.position});
}

class _RippleAnimation extends StatefulWidget {
  final Color color;
  final Duration duration;

  const _RippleAnimation({
    super.key,
    required this.color,
    required this.duration,
  });

  @override
  State<_RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<_RippleAnimation>
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

    // Scale from small to large
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    // Fade out towards the end
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
