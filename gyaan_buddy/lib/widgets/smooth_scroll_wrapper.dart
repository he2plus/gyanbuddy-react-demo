import 'package:flutter/material.dart';

/// A wrapper widget that adds a submerging/fade effect at the top and/or bottom edges
/// of scrollable content. Items smoothly fade as they approach viewport edges,
/// creating a polished "submerging" effect instead of harsh clipping.
///
/// This uses gradient overlays for performance and works with clipped scroll views.
class SmoothScrollOverlay extends StatelessWidget {
  /// The scrollable child widget
  final Widget child;

  /// Whether to show the fade effect at the top edge
  final bool showTopFade;

  /// Whether to show the fade effect at the bottom edge
  final bool showBottomFade;

  /// The height of the fade/submerge effect in pixels
  final double fadeHeight;

  /// The color to fade into (usually matches the background)
  final Color fadeColor;

  const SmoothScrollOverlay({
    super.key,
    required this.child,
    this.showTopFade = true,
    this.showBottomFade = true,
    this.fadeHeight = 40.0,
    this.fadeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The scrollable content (with normal clipping)
        child,

        // Top submerging gradient overlay
        if (showTopFade)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: fadeHeight,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      fadeColor,
                      fadeColor.withOpacity(0.85),
                      fadeColor.withOpacity(0.5),
                      fadeColor.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.25, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // Bottom submerging gradient overlay
        if (showBottomFade)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: fadeHeight,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      fadeColor,
                      fadeColor.withOpacity(0.85),
                      fadeColor.withOpacity(0.5),
                      fadeColor.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.25, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Extension to easily apply submerging scroll effect to any scrollable widget
extension SmoothScrollExtension on Widget {
  /// Wraps the widget with a submerging fade effect at edges
  Widget withSubmergeEffect({
    bool showTopFade = true,
    bool showBottomFade = true,
    double fadeHeight = 40.0,
    Color fadeColor = Colors.white,
  }) {
    return SmoothScrollOverlay(
      showTopFade: showTopFade,
      showBottomFade: showBottomFade,
      fadeHeight: fadeHeight,
      fadeColor: fadeColor,
      child: this,
    );
  }
}

