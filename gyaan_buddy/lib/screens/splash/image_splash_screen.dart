import 'package:flutter/material.dart';
import 'package:gyanbuddy/main.dart';
import 'package:gyanbuddy/utils/animation_utils.dart';
import 'package:gyanbuddy/utils/connected_page_transitions.dart';

import '../../services/index.dart';
import '../onboarding/onboarding_screen.dart';

class ImageSplashScreen extends StatefulWidget {
  const ImageSplashScreen({super.key});

  @override
  State<ImageSplashScreen> createState() => _ImageSplashScreenState();
}

class _ImageSplashScreenState extends State<ImageSplashScreen> {
  @override
  void initState() {
    super.initState();
    _showSplashAndNavigate();
  }

  /// Show splash screen and navigate based on onboarding status
  Future<void> _showSplashAndNavigate() async {
    // Track app launch
    PostHogService.capture('app_launched', properties: {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    });

    // Check if onboarding has been completed
    final hasCompletedOnboarding = true? true:await OnboardingService.isOnboardingComplete();

    // Show splash screen for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      if (!hasCompletedOnboarding) {
        // Show onboarding for new users
        Navigator.of(context).pushReplacement(
          ConnectedPageTransitions.fadeThrough(page: const OnboardingScreen()),
        );
      } else {
        // Navigate to LoginOrHomeScreen which will:
        // 1. Check authentication
        // 2. Trigger caching on LoadingScreen if authenticated
        // 3. Navigate to home or login
        // Using depth transition for immersive splash-to-app transition
        Navigator.of(context).pushReplacement(
          ConnectedPageTransitions.depthTransition(page: const LoginOrHomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          'assets/images/splash_screen.jpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image fails to load
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0A1172),
              child: const Center(
                child: Text(
                  'GyanBuddy',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

