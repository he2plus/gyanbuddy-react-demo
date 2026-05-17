import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../services/posthog_service.dart';
import '../../services/vibration_service.dart';
import '../../utils/connected_page_transitions.dart';

/// Onboarding screen that introduces users to the app's features
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Page controller
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  // Floating animation
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  // Colors
  static const Color _primaryBlue = Color(0xFF0A1172);
  static const Color _accentCyan = Color(0xFF00D4FF);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _gold = Color(0xFFFBBF24);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _green = Color(0xFF10B981);

  // Onboarding data
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Welcome to GyanBuddy',
      subtitle: 'Your Smart Learning Companion',
      description:
          'Master any subject with personalized quizzes and track your progress as you learn.',
      icon: Icons.school_rounded,
      backgroundColor: _primaryBlue,
      accentColor: _accentCyan,
      illustration: 'celebrate',
    ),
    OnboardingPageData(
      title: 'Interactive Quizzes',
      subtitle: 'Learn by Doing',
      description:
          'Take engaging quizzes across multiple subjects. Get instant feedback and explanations for every answer.',
      icon: Icons.quiz_rounded,
      backgroundColor: const Color(0xFF1E3A5F),
      accentColor: _gold,
      illustration: 'quiz',
    ),
    OnboardingPageData(
      title: 'Track Your Progress',
      subtitle: 'See Your Growth',
      description:
          'Monitor your learning journey with detailed progress tracking. Watch your XP grow as you master topics.',
      icon: Icons.trending_up_rounded,
      backgroundColor: const Color(0xFF0F172A),
      accentColor: _green,
      illustration: 'progress',
    ),
    OnboardingPageData(
      title: 'Compete & Win',
      subtitle: 'Rise to the Top',
      description:
          'Challenge yourself on the leaderboard. Compete with other learners and become the week\'s champion!',
      icon: Icons.emoji_events_rounded,
      backgroundColor: const Color(0xFF1A1A2E),
      accentColor: _purple,
      illustration: 'trophy',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _trackOnboardingStart();
  }

  void _initAnimations() {
    // Floating animation for icons
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -12.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for page content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  void _trackOnboardingStart() {
    PostHogService.capture('onboarding_started', properties: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _slideController.reset();
    _slideController.forward();
    VibrationService().lightVibration();

    PostHogService.capture('onboarding_page_viewed', properties: {
      'page_index': page,
      'page_title': _pages[page].title,
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    PostHogService.capture('onboarding_skipped', properties: {
      'skipped_at_page': _currentPage,
    });
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await VibrationService().navigationVibration();
    await OnboardingService.completeOnboarding();

    PostHogService.capture('onboarding_completed', properties: {
      'completed_all_pages': _currentPage == _pages.length - 1,
    });

    if (mounted) {
      Navigator.of(context).pushReplacement(
        ConnectedPageTransitions.depthTransition(
          page: const LoginOrHomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPageData = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentPageData.backgroundColor,
              currentPageData.backgroundColor.withOpacity(0.8),
              Color.lerp(
                currentPageData.backgroundColor,
                currentPageData.accentColor,
                0.2,
              )!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              _buildHeader(),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index == _currentPage);
                  },
                ),
              ),

              // Bottom section with indicators and button
              _buildBottomSection(currentPageData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 24 : 20.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Text(
                'Gyan',
                style: TextStyle(
                  fontSize: kIsWeb ? 24 : 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Buddy',
                style: TextStyle(
                  fontSize: kIsWeb ? 24 : 24.sp,
                  fontWeight: FontWeight.w700,
                  color: _accentCyan,
                ),
              ),
            ],
          ),

          // Skip button
          if (_currentPage < _pages.length - 1)
            GestureDetector(
              onTap: _skipOnboarding,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: kIsWeb ? 16 : 16.w,
                  vertical: kIsWeb ? 8 : 8.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, bool isActive) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        final slideValue =
            isActive ? _slideController.value : 1.0;
        final fadeValue =
            isActive ? _slideController.value : 1.0;

        return Transform.translate(
          offset: Offset(0, 30 * (1 - slideValue)),
          child: Opacity(
            opacity: fadeValue,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 32 : 28.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration area
                  _buildIllustration(pageData),

                  SizedBox(height: kIsWeb ? 48 : 40.h),

                  // Title
                  Text(
                    pageData.title,
                    style: TextStyle(
                      fontSize: kIsWeb ? 32 : 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: kIsWeb ? 8 : 8.h),

                  // Subtitle
                  Text(
                    pageData.subtitle,
                    style: TextStyle(
                      fontSize: kIsWeb ? 18 : 16.sp,
                      fontWeight: FontWeight.w600,
                      color: pageData.accentColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: kIsWeb ? 20 : 16.h),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 16 : 12.w),
                    child: Text(
                      pageData.description,
                      style: TextStyle(
                        fontSize: kIsWeb ? 16 : 15.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIllustration(OnboardingPageData pageData) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow circles
              _buildGlowCircles(pageData.accentColor),

              // Main icon container
              Container(
                width: kIsWeb ? 180 : 160.w,
                height: kIsWeb ? 180 : 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      pageData.accentColor,
                      pageData.accentColor.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: pageData.accentColor.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  pageData.icon,
                  size: kIsWeb ? 80 : 72.sp,
                  color: Colors.white,
                ),
              ),

              // Floating decorative elements
              ..._buildFloatingElements(pageData.accentColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowCircles(Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: kIsWeb ? 240 : 220.w,
          height: kIsWeb ? 240 : 220.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withOpacity(0.08),
          ),
        ),
        // Middle glow
        Container(
          width: kIsWeb ? 200 : 190.w,
          height: kIsWeb ? 200 : 190.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingElements(Color accentColor) {
    return [
      // Top right star
      Positioned(
        top: kIsWeb ? 10 : 10.h,
        right: kIsWeb ? 40 : 35.w,
        child: Transform.rotate(
          angle: _floatingController.value * 0.5,
          child: Icon(
            Icons.star_rounded,
            size: kIsWeb ? 24 : 22.sp,
            color: accentColor.withOpacity(0.8),
          ),
        ),
      ),
      // Bottom left sparkle
      Positioned(
        bottom: kIsWeb ? 20 : 20.h,
        left: kIsWeb ? 30 : 25.w,
        child: Transform.rotate(
          angle: -_floatingController.value * 0.3,
          child: Icon(
            Icons.auto_awesome,
            size: kIsWeb ? 20 : 18.sp,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
      // Top left circle
      Positioned(
        top: kIsWeb ? 40 : 35.h,
        left: kIsWeb ? 50 : 45.w,
        child: Container(
          width: kIsWeb ? 12 : 10.w,
          height: kIsWeb ? 12 : 10.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ),
      // Bottom right diamond
      Positioned(
        bottom: kIsWeb ? 30 : 25.h,
        right: kIsWeb ? 45 : 40.w,
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: kIsWeb ? 14 : 12.w,
            height: kIsWeb ? 14 : 12.w,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(kIsWeb ? 3 : 3.r),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildBottomSection(OnboardingPageData currentPageData) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Container(
      padding: EdgeInsets.only(
        left: kIsWeb ? 32 : 28.w,
        right: kIsWeb ? 32 : 28.w,
        bottom: kIsWeb ? 40 : 36.h,
        top: kIsWeb ? 24 : 20.h,
      ),
      child: Column(
        children: [
          // Page indicators
          _buildPageIndicators(currentPageData.accentColor),

          SizedBox(height: kIsWeb ? 32 : 28.h),

          // CTA Button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isLastPage ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: double.infinity,
                    height: kIsWeb ? 56 : 54.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLastPage
                            ? [currentPageData.accentColor, currentPageData.accentColor.withOpacity(0.8)]
                            : [Colors.white, Colors.white.withOpacity(0.95)],
                      ),
                      borderRadius: BorderRadius.circular(kIsWeb ? 16 : 14.r),
                      boxShadow: [
                        BoxShadow(
                          color: isLastPage
                              ? currentPageData.accentColor.withOpacity(0.4)
                              : Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? 'Get Started' : 'Next',
                          style: TextStyle(
                            fontSize: kIsWeb ? 18 : 17.sp,
                            fontWeight: FontWeight.w700,
                            color: isLastPage
                                ? Colors.white
                                : currentPageData.backgroundColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 8 : 8.w),
                        Icon(
                          isLastPage
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          size: kIsWeb ? 22 : 20.sp,
                          color: isLastPage
                              ? Colors.white
                              : currentPageData.backgroundColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 4 : 4.w),
          height: kIsWeb ? 8 : 8.h,
          width: isActive ? (kIsWeb ? 32 : 28.w) : (kIsWeb ? 8 : 8.w),
          decoration: BoxDecoration(
            color: isActive ? accentColor : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(kIsWeb ? 4 : 4.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// Data model for onboarding pages
class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final String illustration;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    required this.illustration,
  });
}

