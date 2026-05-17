import 'package:flutter/material.dart';

enum GradientDirection {
  upward,
  downward,
}

/// A custom container widget with gradient support and direction control.
/// 
/// This widget creates a container with a linear gradient that can be
/// configured to flow upward or downward.
/// 
/// Example usage:
/// ```dart
/// // Downward gradient (default)
/// GradientContainer(
///   height: 100,
///   startColor: Colors.blue.withOpacity(0.1),
///   endColor: Colors.blue.withOpacity(0.05),
///   direction: GradientDirection.downward,
///   child: Text('Content'),
/// )
/// 
/// // Upward gradient
/// GradientContainer(
///   height: 100,
///   startColor: Colors.red.withOpacity(0.2),
///   endColor: Colors.red.withOpacity(0.05),
///   direction: GradientDirection.upward,
///   child: Text('Content'),
/// )
/// ```
class GradientContainer extends StatelessWidget {
  final Widget? child;
  final Color? startColor;
  final Color? endColor;
  final GradientDirection direction;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GradientContainer({
    super.key,
    this.child,
    this.startColor,
    this.endColor,
    this.direction = GradientDirection.downward,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: direction == GradientDirection.upward 
              ? Alignment.bottomCenter 
              : Alignment.topCenter,
          end: direction == GradientDirection.upward 
              ? Alignment.topCenter 
              : Alignment.bottomCenter,
          colors: [
            startColor ?? Colors.blue.withOpacity(0.1),
            endColor ?? Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
