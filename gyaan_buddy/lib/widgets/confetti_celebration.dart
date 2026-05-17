import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A particle celebration widget that shows confetti particles
/// exploding from the center when triggered.
class ConfettiCelebration extends StatefulWidget {
  final bool isPlaying;
  final int particleCount;
  final Duration duration;
  final Widget? child;

  const ConfettiCelebration({
    super.key,
    required this.isPlaying,
    this.particleCount = 50,
    this.duration = const Duration(milliseconds: 1500),
    this.child,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  // Bright celebration colors
  final List<Color> _colors = [
    const Color(0xFF26de81), // Green
    const Color(0xFFfd79a8), // Pink
    const Color(0xFFfdcb6e), // Yellow
    const Color(0xFF74b9ff), // Blue
    const Color(0xFFa29bfe), // Purple
    const Color(0xFFff7675), // Red
    const Color(0xFF55efc4), // Teal
    const Color(0xFFffeaa7), // Light Yellow
    const Color(0xFFe17055), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _particles = [];

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _particles = [];
        });
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    setState(() {
      _particles = List.generate(widget.particleCount, (index) {
        final angle = _random.nextDouble() * 2 * math.pi;
        final speed = 200 + _random.nextDouble() * 300;
        final size = 6 + _random.nextDouble() * 10;
        final rotationSpeed = (_random.nextDouble() - 0.5) * 10;

        return _Particle(
          color: _colors[_random.nextInt(_colors.length)],
          angle: angle,
          speed: speed,
          size: size,
          rotationSpeed: rotationSpeed,
          shape: _ParticleShape.values[_random.nextInt(_ParticleShape.values.length)],
        );
      });
    });
    _controller.forward(from: 0);
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
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      isComplex: true,
                      willChange: true,
                      painter: _ConfettiPainter(
                        particles: _particles,
                        progress: _controller.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _ParticleShape { circle, square, star, triangle }

class _Particle {
  final Color color;
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final _ParticleShape shape;

  _Particle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = 400 * progress * progress; // Gravity effect

    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress * 0.7)
        ..style = PaintingStyle.fill;

      // Calculate position with gravity
      final dx = math.cos(particle.angle) * particle.speed * progress;
      final dy = math.sin(particle.angle) * particle.speed * progress + gravity;

      final position = Offset(center.dx + dx, center.dy + dy - 100);

      // Skip if particle is outside visible area
      if (position.dx < -50 || position.dx > size.width + 50 ||
          position.dy < -50 || position.dy > size.height + 50) {
        continue;
      }

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotationSpeed * progress * math.pi);

      final particleSize = particle.size * (1 - progress * 0.3);

      switch (particle.shape) {
        case _ParticleShape.circle:
          canvas.drawCircle(Offset.zero, particleSize / 2, paint);
          break;
        case _ParticleShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: particleSize, height: particleSize),
            paint,
          );
          break;
        case _ParticleShape.star:
          _drawStar(canvas, particleSize, paint);
          break;
        case _ParticleShape.triangle:
          _drawTriangle(canvas, particleSize, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final halfSize = size / 2;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final point = Offset(
        math.cos(angle) * halfSize,
        math.sin(angle) * halfSize,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final halfSize = size / 2;
    path.moveTo(0, -halfSize);
    path.lineTo(-halfSize, halfSize);
    path.lineTo(halfSize, halfSize);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

