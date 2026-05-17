import 'package:flutter/material.dart';

class RotatingCircleAnimation extends StatefulWidget {
  final double size;
  final Duration duration;
  final Widget child;

  const RotatingCircleAnimation({
    super.key,
    this.size = 200,
    this.duration = const Duration(seconds: 3),
    required this.child,
  });

  @override
  State<RotatingCircleAnimation> createState() => _RotatingCircleAnimationState();
}

class _RotatingCircleAnimationState extends State<RotatingCircleAnimation>
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
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating circle animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value * 2 * 3.14159,
                child: Image.asset(
                  'assets/images/circle_animation.png',
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          // Child widget (boy image) in the center
          widget.child,
        ],
      ),
    );
  }
}
