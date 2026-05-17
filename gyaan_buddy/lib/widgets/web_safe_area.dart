import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A SafeArea wrapper that only applies SafeArea on mobile platforms.
/// On web, it returns the child directly without SafeArea padding.
class WebSafeArea extends StatelessWidget {
  final Widget child;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  const WebSafeArea({
    super.key,
    required this.child,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    // On web, skip SafeArea entirely
    if (kIsWeb) {
      return child;
    }

    // On mobile, use normal SafeArea
    return SafeArea(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      minimum: minimum,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }
}

