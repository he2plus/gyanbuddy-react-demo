import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;
  final Color? overlayColor;
  final double? opacity;
  final BoxFit fit;
  final Alignment alignment;
  final Gradient? gradient;

  const BackgroundContainer({
    super.key,
    required this.child,
    this.overlayColor,
    this.opacity,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.gradient
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        image: DecorationImage(
          image: const AssetImage('assets/images/background.png'),
          fit: fit,
          alignment: alignment,
          colorFilter: overlayColor != null 
              ? ColorFilter.mode(
                  overlayColor!.withOpacity(opacity ?? 0.3),
                  BlendMode.overlay,
                )
              : null,
        ),
      ),
      child: child,
    );
  }
}
