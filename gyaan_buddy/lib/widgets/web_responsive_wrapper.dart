import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that constrains the app to a phone-like width on web
/// while centering it with a nice background for larger screens.
class WebResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color backgroundColor;
  final bool showDeviceFrame;

  const WebResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 430, // iPhone 14 Pro Max width
    this.backgroundColor = const Color(0xFFF0F2F5),
    this.showDeviceFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    // Only apply wrapper on web
    if (!kIsWeb) {
      return child;
    }

    return Container(
      color: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: double.infinity,
          ),
          child: showDeviceFrame
              ? _buildDeviceFrame(context)
              : _buildSimpleContainer(),
        ),
      ),
    );
  }

  Widget _buildSimpleContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        child: child,
      ),
    );
  }

  Widget _buildDeviceFrame(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = MediaQuery.of(context).size.width > maxWidth + 100;

    return Container(
      margin: isLargeScreen
          ? const EdgeInsets.symmetric(vertical: 20)
          : EdgeInsets.zero,
      constraints: BoxConstraints(
        maxHeight: isLargeScreen ? screenHeight - 40 : screenHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isLargeScreen ? BorderRadius.circular(40) : null,
        boxShadow: isLargeScreen
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: isLargeScreen ? BorderRadius.circular(40) : BorderRadius.zero,
        child: child,
      ),
    );
  }
}

/// Extension to easily check if running on web with large screen
extension WebLayoutExtension on BuildContext {
  bool get isWebLargeScreen {
    if (!kIsWeb) return false;
    return MediaQuery.of(this).size.width > 500;
  }

  bool get isWebMediumScreen {
    if (!kIsWeb) return false;
    final width = MediaQuery.of(this).size.width;
    return width > 400 && width <= 500;
  }

  double get webContentMaxWidth {
    if (!kIsWeb) return double.infinity;
    return 430; // iPhone 14 Pro Max width
  }
}

