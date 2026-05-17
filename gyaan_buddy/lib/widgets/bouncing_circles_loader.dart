import 'package:flutter/material.dart';
import 'dart:math';

class BouncingCirclesLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final VoidCallback? onTransitionComplete;

  const BouncingCirclesLoader({
    super.key,
    this.color,
    this.size = 60.0,
    this.onTransitionComplete,
  });

  @override
  State<BouncingCirclesLoader> createState() => BouncingCirclesLoaderState();
}

class BouncingCirclesLoaderState extends State<BouncingCirclesLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();

  // Exit animation controllers
  late AnimationController _mergeController;
  late AnimationController _scaleController;
  late Animation<double> _mergeAnimation;
  late Animation<double> _dotFadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isExiting = false;

  // Three different colors for the dots
  final List<Color> _dotColors = [
    const Color(0xFF00167A), // Deep Blue
    const Color(0xFF1FB7EB), // Sky Blue
    const Color(0xFF1800AD), // Violet Blue
  ];

  // Current positions of dots (index = dot, value = position 0/1/2)
  List<int> _dotPositions = [0, 1, 2];

  // Target positions for animation
  List<int> _targetPositions = [0, 1, 2];

  // Track which direction each dot jumps (-1 = down, 0 = no jump, 1 = up)
  List<int> _jumpDirections = [0, 0, 0];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Merge animation - dots come together
    _mergeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _mergeAnimation = CurvedAnimation(
      parent: _mergeController,
      curve: Curves.easeInOut,
    );

    _dotFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mergeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Scale animation - circle expands
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isExiting) {
        setState(() {
          _dotPositions = List.from(_targetPositions);
        });
        _controller.reset();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_isExiting) {
            _calculateNextMove();
            _controller.forward();
          }
        });
      }
    });

    _mergeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scaleController.forward();
      }
    });

    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTransitionComplete?.call();
      }
    });

    _calculateNextMove();
    _controller.forward();
  }

  /// Call this method to trigger the exit transition
  void triggerTransition() {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
    });
    _controller.stop();
    _mergeController.forward();
  }

  void _calculateNextMove() {
    int dotAtLeft = _dotPositions.indexOf(0);
    int dotAtCenter = _dotPositions.indexOf(1);
    int dotAtRight = _dotPositions.indexOf(2);

    bool centerGoesToLeft = _random.nextBool();

    _targetPositions = List.from(_dotPositions);
    _jumpDirections = [0, 0, 0];

    _targetPositions[dotAtLeft] = 1;
    _jumpDirections[dotAtLeft] = 1;

    if (centerGoesToLeft) {
      _targetPositions[dotAtCenter] = 0;
      _jumpDirections[dotAtCenter] = -1;
      _targetPositions[dotAtRight] = 2;
      _jumpDirections[dotAtRight] = 0;
    } else {
      _targetPositions[dotAtCenter] = 2;
      _jumpDirections[dotAtCenter] = -1;
      _targetPositions[dotAtRight] = 0;
      _jumpDirections[dotAtRight] = -1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mergeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.size * 1.8;
    final dotSize = widget.size / 4;
    final spacing = widget.size / 1.8;
    final xPositions = [-spacing, 0.0, spacing];
    final arcHeight = spacing * 0.7;

    // Get screen size for scale animation
    final screenSize = MediaQuery.of(context).size;
    final maxScale = (screenSize.longestSide * 2) / containerSize;

    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _mergeAnimation, _scaleAnimation]),
      builder: (context, child) {
        final progress = _animation.value;
        final mergeProgress = _mergeAnimation.value;
        final scaleProgress = _scaleAnimation.value;
        final dotOpacity = _dotFadeAnimation.value;

        // Calculate scale (1.0 -> maxScale during exit)
        final currentScale = 1.0 + (maxScale - 1.0) * scaleProgress;

        // Calculate arc offset for normal animation
        double arcOffset = 4 * arcHeight * progress * (1 - progress);

        return Transform.scale(
          scale: currentScale,
          child: Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.withOpacity(0.2 * (1 - scaleProgress)),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08 * (1 - scaleProgress)),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(3, (dotIndex) {
                final startPos = _dotPositions[dotIndex];
                final endPos = _targetPositions[dotIndex];
                final jumpDir = _jumpDirections[dotIndex];

                // Normal X position during bounce animation
                double normalX = xPositions[startPos] +
                    (xPositions[endPos] - xPositions[startPos]) * progress;

                // During merge, all dots move to center (0, 0)
                double currentX = _isExiting
                    ? normalX * (1 - mergeProgress)
                    : normalX;

                // Normal Y offset based on jump direction
                double normalY = 0;
                if (jumpDir == 1) {
                  normalY = -arcOffset;
                } else if (jumpDir == -1) {
                  normalY = arcOffset;
                }

                // During merge, Y also goes to 0
                double currentY = _isExiting
                    ? normalY * (1 - mergeProgress)
                    : normalY;

                // Dot size shrinks during merge
                double currentDotSize = _isExiting
                    ? dotSize * (1 - mergeProgress * 0.5)
                    : dotSize;

                return Opacity(
                  opacity: _isExiting ? dotOpacity : 1.0,
                  child: Transform.translate(
                    offset: Offset(currentX, currentY),
                    child: _buildDot(_dotColors[dotIndex], currentDotSize),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
