import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A widget that applies a shock/shake animation to its child
/// when triggered. Perfect for indicating wrong answers.
class ShockAnimation extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final Duration duration;
  final double intensity;
  final VoidCallback? onComplete;

  const ShockAnimation({
    super.key,
    required this.child,
    required this.isPlaying,
    this.duration = const Duration(milliseconds: 500),
    this.intensity = 1.0,
    this.onComplete,
  });

  @override
  State<ShockAnimation> createState() => _ShockAnimationState();
}

class _ShockAnimationState extends State<ShockAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _setupAnimations();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _setupAnimations() {
    // Shake animation - oscillates left and right with decreasing intensity
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 15.0 * widget.intensity)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 15.0 * widget.intensity, end: -12.0 * widget.intensity)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -12.0 * widget.intensity, end: 10.0 * widget.intensity)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 10.0 * widget.intensity, end: -8.0 * widget.intensity)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0 * widget.intensity, end: 5.0 * widget.intensity)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 5.0 * widget.intensity, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_controller);

    // Scale animation - quick pulse effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
    ]).animate(_controller);

    // Color tint animation - brief red flash
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.transparent,
          end: Colors.red.withOpacity(0.3),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.red.withOpacity(0.3),
          end: Colors.transparent,
        ),
        weight: 3,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(ShockAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0);
    }
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
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                _colorAnimation.value ?? Colors.transparent,
                BlendMode.srcATop,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// A more intense shock effect with visual cracks/lightning
class IntenseShockEffect extends StatefulWidget {
  final bool isPlaying;
  final Duration duration;
  final Widget? child;

  const IntenseShockEffect({
    super.key,
    required this.isPlaying,
    this.duration = const Duration(milliseconds: 600),
    this.child,
  });

  @override
  State<IntenseShockEffect> createState() => _IntenseShockEffectState();
}

class _IntenseShockEffectState extends State<IntenseShockEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(IntenseShockEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (widget.child != null) widget.child!,
        if (_controller.isAnimating || _controller.value > 0)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ShockWavePainter(
                      progress: _controller.value,
                      center: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ShockWavePainter extends CustomPainter {
  final double progress;
  final Offset center;

  _ShockWavePainter({
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = math.max(size.width, size.height);
    
    // Draw multiple expanding rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress - i * 0.1).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      final radius = ringProgress * maxRadius * 0.6;
      final opacity = (1 - ringProgress) * 0.4;

      final paint = Paint()
        ..color = Colors.red.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - ringProgress);

      canvas.drawCircle(center, radius, paint);
    }

    // Draw lightning bolts
    if (progress < 0.5) {
      _drawLightningBolt(canvas, center, size, progress * 2);
    }
  }

  void _drawLightningBolt(Canvas canvas, Offset center, Size size, double progress) {
    final random = math.Random(42); // Fixed seed for consistent animation
    final paint = Paint()
      ..color = Colors.red.withOpacity((1 - progress) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw 4 lightning bolts in different directions
    for (int bolt = 0; bolt < 4; bolt++) {
      final path = Path();
      final angle = (bolt * math.pi / 2) + math.pi / 4;
      var current = center;
      path.moveTo(current.dx, current.dy);

      for (int segment = 0; segment < 5; segment++) {
        final length = 20 + random.nextDouble() * 30;
        final deviation = (random.nextDouble() - 0.5) * 40;
        
        final nextX = current.dx + math.cos(angle) * length + math.cos(angle + math.pi / 2) * deviation;
        final nextY = current.dy + math.sin(angle) * length + math.sin(angle + math.pi / 2) * deviation;
        
        current = Offset(nextX, nextY);
        path.lineTo(current.dx, current.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ShockWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

