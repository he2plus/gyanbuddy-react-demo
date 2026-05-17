import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'bouncing_circles_loader.dart';
import '../utils/web_size_utils.dart';

class LoadingScreen extends StatefulWidget {
  final Color? primaryColor;
  final Widget? child;
  final VoidCallback? onTransitionComplete;

  const LoadingScreen({
    super.key,
    this.primaryColor,
    this.child,
    this.onTransitionComplete,
  });

  @override
  State<LoadingScreen> createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Key to access the loader state
  final GlobalKey<BouncingCirclesLoaderState> _loaderKey = GlobalKey();

  // Helper function to create light/pastel versions of color for gradients
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Colors.white,
    ];
  }

  List<Color> _getBottomGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
    ];
  }

  @override
  void initState() {
    super.initState();

    _circle1Controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _circle2Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _circle3Controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _circle1Animation = Tween<double>(
      begin: -20.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _circle1Controller,
      curve: Curves.easeInOut,
    ));

    _circle2Animation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _circle2Controller,
      curve: Curves.easeInOut,
    ));

    _circle3Animation = Tween<double>(
      begin: -25.0,
      end: 25.0,
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Call this method to trigger the navigation transition
  /// The dots will merge, vanish, and the circle will expand to fill the screen
  void triggerTransition() {
    _loaderKey.currentState?.triggerTransition();
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF00167A);
    final topGradientColors = _getGradientColors(primaryColor);
    final bottomGradientColors = _getBottomGradientColors(primaryColor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // White base background
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),
          // Top gradient (1/4 of screen)
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     height: 0.25.sh,
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: topGradientColors,
          //         stops: const [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0],
          //       ),
          //     ),
          //   ),
          // ),
          // Bottom gradient (1/3 of screen)
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     height: 0.33.sh,
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: bottomGradientColors,
          //         stops: const [0.0, 0.5, 1.0],
          //       ),
          //     ),
          //   ),
          // ),
          // Circular shapes overlay
          Positioned.fill(
            child: Stack(
              children: [
                // Large circle in top right
                AnimatedBuilder(
                  animation: _circle1Animation,
                  builder: (context, child) {
                    return Positioned(
                      top: -100 + _circle1Animation.value,
                      right: -100,
                      child: Container(
                        width: WebSize.width(context, 300),
                        height: WebSize.width(context, 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00167A),
                        ),
                      ),
                    );
                  },
                ),
                // Small circle in upper left
                AnimatedBuilder(
                  animation: _circle2Animation,
                  builder: (context, child) {
                    return Positioned(
                      top: 240 + _circle2Animation.value,
                      left: 40,
                      child: Container(
                        width: WebSize.width(context, 120),
                        height: WebSize.width(context, 120),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00167A),
                        ),
                      ),
                    );
                  },
                ),
                // Small circle in lower right
                AnimatedBuilder(
                  animation: _circle3Animation,
                  builder: (context, child) {
                    return Positioned(
                      bottom: 150 - _circle3Animation.value,
                      right: 60,
                      child: Container(
                        width: WebSize.width(context, 100),
                        height: WebSize.width(context, 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00167A),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Content (loader or custom child)
          Center(
            child: widget.child ??
                BouncingCirclesLoader(
                  key: _loaderKey,
                  color: const Color(0xFF00167A),
                  size: 60.0,
                  onTransitionComplete: widget.onTransitionComplete,
                ),
          ),
        ],
      ),
    );
  }
}
