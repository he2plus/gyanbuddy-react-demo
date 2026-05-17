import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/game_animations.dart';

// Interactive Card with 3D tilt effect
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double elevation;
  final Duration animationDuration;
  final bool enableTilt;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.elevation = 8.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableTilt = true,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;
  
  bool _isPressed = false;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _tiltAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
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
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.enableTilt) {
      setState(() {
        _dragOffset = details.localPosition - Offset(100, 100);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final tiltX = widget.enableTilt 
              ? (_dragOffset.dy / 100) * _tiltAnimation.value
              : 0.0;
          final tiltY = widget.enableTilt 
              ? (-_dragOffset.dx / 100) * _tiltAnimation.value
              : 0.0;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(tiltX)
              ..rotateY(tiltY),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Progress Indicator with Game-like Feel
class GameProgressIndicator extends StatefulWidget {
  final double value;
  final double maxValue;
  final Color color;
  final Color backgroundColor;
  final double height;
  final Duration animationDuration;
  final bool showGlow;

  const GameProgressIndicator({
    super.key,
    required this.value,
    required this.maxValue,
    this.color = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.height = 12.0,
    this.animationDuration = const Duration(milliseconds: 800),
    this.showGlow = true,
  });

  @override
  State<GameProgressIndicator> createState() => _GameProgressIndicatorState();
}

class _GameProgressIndicatorState extends State<GameProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value / widget.maxValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(GameProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.value / oldWidget.maxValue,
        end: widget.value / widget.maxValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
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
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                width: MediaQuery.of(context).size.width * _progressAnimation.value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  boxShadow: widget.showGlow
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.5),
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          if (widget.showGlow)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.0),
                          widget.color.withOpacity(0.8),
                          widget.color.withOpacity(0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Floating Action Button with Particle Effect
class GameFloatingActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color particleColor;
  final double size;
  final Duration animationDuration;

  const GameFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor = Colors.blue,
    this.particleColor = Colors.amber,
    this.size = 56.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<GameFloatingActionButton> createState() => _GameFloatingActionButtonState();
}

class _GameFloatingActionButtonState extends State<GameFloatingActionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _particleAnimation;
  
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    _showParticles = true;
    _particleController.forward().then((_) {
      setState(() {
        _showParticles = false;
      });
      _particleController.reset();
    });
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.4),
                      blurRadius: 12.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
        if (_showParticles)
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return Stack(
                children: List.generate(8, (index) {
                  final angle = index * math.pi / 4;
                  final distance = 60.0 * _particleAnimation.value;
                  final opacity = (1.0 - _particleAnimation.value);
                  
                  return Positioned(
                    left: widget.size / 2 + math.cos(angle) * distance - 4,
                    top: widget.size / 2 + math.sin(angle) * distance - 4,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.particleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
      ],
    );
  }
}

// Animated Counter with Bounce Effect
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration animationDuration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.elasticOut,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            widget.value.toString(),
            style: widget.style ?? Theme.of(context).textTheme.headlineMedium,
          ),
        );
      },
    );
  }
}

// Interactive List Item with Swipe Actions
class InteractiveListItem extends StatefulWidget {
  final Widget child;
  final List<Widget>? trailingActions;
  final VoidCallback? onTap;
  final Duration animationDuration;

  const InteractiveListItem({
    super.key,
    required this.child,
    this.trailingActions,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<InteractiveListItem> createState() => _InteractiveListItemState();
}

class _InteractiveListItemState extends State<InteractiveListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  double _dragOffset = 0.0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
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
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-100.0, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset < -50) {
      setState(() {
        _isExpanded = true;
        _dragOffset = -100.0;
      });
    } else {
      setState(() {
        _isExpanded = false;
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          if (widget.trailingActions != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                children: widget.trailingActions!.map((action) {
                  return Container(
                    width: 100,
                    height: double.infinity,
                    child: action,
                  );
                }).toList(),
              ),
            ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(_dragOffset * _slideAnimation.value, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
