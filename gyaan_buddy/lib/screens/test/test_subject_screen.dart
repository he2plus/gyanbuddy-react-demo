import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/shimmer_image_placeholder.dart';
import '../../blocs/user_test/user_test_bloc.dart';
import '../../models/user_test_model.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/confetti_celebration.dart';
import 'test_quiz_screen.dart';

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

Color _hexToColor(String? hexString, {Color fallback = Colors.blue}) {
  if (hexString == null || hexString.isEmpty) {
    return fallback;
  }
  try {
    String hex = hexString.startsWith('#') ? hexString.substring(1) : hexString;
    return Color(int.parse('FF$hex', radix: 16));
  } catch (e) {
    return fallback;
  }
}

class TestSubjectScreen extends StatefulWidget {
  const TestSubjectScreen({super.key});

  @override
  State<TestSubjectScreen> createState() => _TestSubjectScreenState();
}

class _TestSubjectScreenState extends State<TestSubjectScreen>
    with TickerProviderStateMixin {
  // Animation controllers for floating circles
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  final ScrollController _testScrollController = ScrollController();

  // Card animation controllers
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<double>> _cardFadeAnimations;

  // Base color for the screen
  final Color _baseColor = const Color(0xFFFF9800);

  // Track pressed card index for visual feedback
  int? _pressedCardIndex;

  // Track the number of cards for animation controller management
  int _previousCardCount = 0;

  // Track locally completed test IDs for immediate UI update
  final Set<String> _locallyCompletedTestIds = {};

  // Track the just-completed test ID for animation
  String? _justCompletedTestId;
  
  // Completion celebration animation controllers
  AnimationController? _completionPulseController;
  AnimationController? _completionCheckController;
  AnimationController? _successOverlayController;
  Animation<double>? _completionPulseAnimation;
  Animation<double>? _completionCheckScaleAnimation;
  Animation<double>? _completionCheckOpacityAnimation;
  Animation<double>? _successOverlayScaleAnimation;
  Animation<double>? _successOverlayOpacityAnimation;
  
  // Flag to show confetti celebration
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _initializeCircleAnimations();
    _initializeCompletionAnimations();
    
    // Load user tests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserTestBloc>().add(const LoadUserTests());
    });
  }

  void _initializeCompletionAnimations() {
    // Pulse animation - card grows and shrinks
    _completionPulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _completionPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_completionPulseController!);
    
    // Checkmark animation - scales up with bounce
    _completionCheckController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _completionCheckScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_completionCheckController!);
    
    _completionCheckOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _completionCheckController!,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        ));
    
    // Full-screen success overlay animation
    _successOverlayController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _successOverlayScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_successOverlayController!);
    
    _successOverlayOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_successOverlayController!);
  }

  void _triggerCompletionAnimation(String testId) {
    setState(() {
      _justCompletedTestId = testId;
      _showConfetti = true;
    });
    
    // Play success sound and vibration
    // SoundService().playSuccess();
    VibrationService().successVibration();
    
    // Start the animations with a slight delay for visual impact
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _completionPulseController?.forward(from: 0);
        _completionCheckController?.forward(from: 0);
        _successOverlayController?.forward(from: 0);
      }
    });
    
    // Reset confetti after animation completes
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
    
    // Clear the just-completed state after animations finish
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _justCompletedTestId = null;
        });
      }
    });
  }

  void _initializeCircleAnimations() {
    // Circle animation controllers
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
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));
    
    // Initialize empty card controllers list
    _cardControllers = [];
    _cardScaleAnimations = [];
    _cardFadeAnimations = [];
  }

  void _initializeCardAnimations(List<UserTest> tests) {
    final cardCount = tests.length;
    
    // Only reinitialize if card count changed
    if (cardCount == _previousCardCount && _cardControllers.isNotEmpty) {
      return;
    }
    
    // Dispose old controllers if any
    if (_previousCardCount > 0) {
      for (var controller in _cardControllers) {
        controller.dispose();
      }
    }
    
    _previousCardCount = cardCount;

    // Card animations
    _cardControllers = List.generate(
      cardCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _cardScaleAnimations = _cardControllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _cardFadeAnimations = _cardControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // Start card animations with staggered delay
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (mounted && i < _cardControllers.length) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  // Get unique subjects from tests
  List<UserTest> _getUniqueSubjectTests(List<UserTest> tests) {
    final Map<String, UserTest> uniqueSubjects = {};
    for (final test in tests) {
      final key = test.subjectId ?? test.subjectName ?? test.title;
      if (!uniqueSubjects.containsKey(key)) {
        uniqueSubjects[key] = test;
      }
    }
    return uniqueSubjects.values.toList();
  }

  // Get all tests for a specific subject
  List<UserTest> _getTestsForSubject(List<UserTest> tests, String? subjectId, String? subjectName) {
    return tests.where((t) {
      if (subjectId != null) {
        return t.subjectId == subjectId;
      }
      return t.subjectName == subjectName;
    }).toList();
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _completionPulseController?.dispose();
    _completionCheckController?.dispose();
    _successOverlayController?.dispose();
    _testScrollController.dispose();
    super.dispose();
  }

  // Helper function to create gradient colors
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final topGradientColors = _getGradientColors(_baseColor);

    return BlocConsumer<UserTestBloc, UserTestState>(
      listener: (context, state) {
        if (state is UserTestsLoaded) {
          _initializeCardAnimations(state.tests);
        }
      },
      builder: (context, state) {
        List<UserTest> currentTests = [];
        String? errorMessage;

        if (state is UserTestsLoaded) {
          currentTests = state.tests;
        } else if (state is UserTestLoading) {
          // Show loading state
        } else if (state is UserTestError) {
          errorMessage = state.message;
        }
        
        final uniqueSubjectTests = _getUniqueSubjectTests(currentTests);

        return Scaffold(
          body: Stack(
            children: [
              // White base background
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                ),
              ),
              // Top gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: kIsWeb ? 250 : 0.3.sh,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: topGradientColors,
                      stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Floating circles
              _buildFloatingCircles(),
              // Main content
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    // Info card
                    _buildInfoCard(currentTests),
                    // Subject cards grid
                    Expanded(
                      child: state is UserTestLoading
                          ? _buildLoadingState()
                          : errorMessage != null
                              ? _buildErrorState(errorMessage)
                              : currentTests.isEmpty
                                  ? _buildEmptyState()
                                  : _buildSubjectCards(currentTests, uniqueSubjectTests),
                    ),
                  ],
                ),
              ),
              // Full-screen success particle effect overlay
              if (_showConfetti)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ConfettiCelebration(
                      isPlaying: _showConfetti,
                      particleCount: 80,
                      duration: const Duration(milliseconds: 2000),
                    ),
                  ),
                ),
              // Centered success checkmark animation with fade out
              if (_justCompletedTestId != null && _successOverlayController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _successOverlayController!,
                      builder: (context, child) {
                        final scale = _successOverlayScaleAnimation?.value ?? 0.0;
                        final opacity = _successOverlayOpacityAnimation?.value ?? 0.0;
                        
                        if (opacity <= 0) return const SizedBox.shrink();
                        
                        return Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: kIsWeb ? 140 : 140.w,
                                height: kIsWeb ? 140 : 140.w,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF2E7D32),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      spreadRadius: 15,
                                      blurRadius: 40,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      spreadRadius: -5,
                                      blurRadius: 20,
                                      offset: const Offset(-5, -5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: kIsWeb ? 80 : 80.sp,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCircles() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Large circle in top right
            AnimatedBuilder(
              animation: _circle1Animation,
              builder: (context, child) {
                return Positioned(
                  top: (kIsWeb ? -80.0 : -80.h) + _circle1Animation.value,
                  right: kIsWeb ? -60.0 : -60.w,
                  child: Container(
                    width: kIsWeb ? 200 : 200.w,
                    height: kIsWeb ? 200 : 200.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _baseColor.withOpacity(0.12),
                    ),
                  ),
                );
              },
            ),
            // Small circle in middle left
            AnimatedBuilder(
              animation: _circle2Animation,
              builder: (context, child) {
                return Positioned(
                  top: (kIsWeb ? 300.0 : 300.h) + _circle2Animation.value,
                  left: kIsWeb ? -40.0 : -40.w,
                  child: Container(
                    width: kIsWeb ? 100 : 100.w,
                    height: kIsWeb ? 100 : 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _baseColor.withOpacity(0.18),
                    ),
                  ),
                );
              },
            ),
            // Small circle in bottom right
            AnimatedBuilder(
              animation: _circle3Animation,
              builder: (context, child) {
                return Positioned(
                  bottom: (kIsWeb ? 150.0 : 150.h) - _circle3Animation.value,
                  right: kIsWeb ? 30.0 : 30.w,
                  child: Container(
                    width: kIsWeb ? 60 : 60.w,
                    height: kIsWeb ? 60 : 60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _baseColor.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(kIsWeb ? 16 : 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              // await SoundService().playButtonClick();
              await VibrationService().navigationVibration();
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: kIsWeb ? 22 : 24,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'My Tests',
                style: TextStyle(
                  fontSize: kIsWeb ? 25 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: kIsWeb ? 40 : 48),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<UserTest> tests) {
    // Count tests by status
    final completedTests = tests.where((t) => 
      t.isCompleted || _locallyCompletedTestIds.contains(t.id)
    ).length;
    final activeTests = tests.where((t) => 
      !t.isCompleted && !_locallyCompletedTestIds.contains(t.id) && t.isInActiveWindow
    ).length;
    final upcomingTests = tests.where((t) => 
      !t.isCompleted && !_locallyCompletedTestIds.contains(t.id) && t.isUpcoming
    ).length;
    final skippedTests = tests.where((t) => 
      !t.isCompleted && !_locallyCompletedTestIds.contains(t.id) && t.isSkipped
    ).length;
    
    String testCountText;
    Color? statusColor;
    if (completedTests == tests.length) {
      testCountText = 'All tests completed';
      statusColor = Colors.green[600];
    } else if (activeTests > 0) {
      testCountText = '$activeTests active, $upcomingTests upcoming';
      statusColor = Colors.blue[600];
    } else if (skippedTests > 0) {
      testCountText = '$skippedTests skipped, $upcomingTests upcoming';
      statusColor = Colors.orange[600];
    } else {
      testCountText = '$upcomingTests upcoming test${upcomingTests > 1 ? 's' : ''}';
      statusColor = Colors.grey[600];
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 150 : 40.w,
        vertical: kIsWeb ? 8 : 8.h,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 20 : 20.w,
          vertical: kIsWeb ? 16 : 16.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
          boxShadow: [
            BoxShadow(
              color: _baseColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(kIsWeb ? 12 : 12.w),
              decoration: BoxDecoration(
                color: _baseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
              ),
              child: Icon(
                Icons.assignment,
                color: _baseColor,
                size: kIsWeb ? 50 : 24.sp,
              ),
            ),
            SizedBox(width: kIsWeb ? 16 : 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Tests',
                  style: TextStyle(
                    fontSize: kIsWeb ? 20 : 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: kIsWeb ? 4 : 4.h),
                Text(
                  testCountText,
                  style: TextStyle(
                    fontSize: kIsWeb ? 15 : 13.sp,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_baseColor),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: kIsWeb ? 80 : 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: kIsWeb ? 16 : 16.h),
          Text(
            'Failed to load tests',
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 32 : 32.w),
            child: Text(
              message,
              style: TextStyle(
                fontSize: kIsWeb ? 14 : 13.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: kIsWeb ? 24 : 24.h),
          ElevatedButton(
            onPressed: () {
              context.read<UserTestBloc>().add(const LoadUserTests());
            },
            style: ElevatedButton.styleFrom(backgroundColor: _baseColor),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: kIsWeb ? 100 : 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: kIsWeb ? 16 : 16.h),
          Text(
            'No tests assigned',
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          Text(
            'Your assigned tests will appear here',
            style: TextStyle(
              fontSize: kIsWeb ? 14 : 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCards(List<UserTest> allTests, List<UserTest> uniqueSubjectTests) {
    return ScrollConfiguration(
      behavior: _NoScrollbarBehavior(),
      child: ListView.builder(
        controller: _testScrollController,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 150 : 40.w,
          vertical: kIsWeb ? 16 : 16.h,
        ),
        itemCount: allTests.length,
        itemBuilder: (context, index) {
          final test = allTests[index];

          // Ensure we have enough animation controllers
          if (index >= _cardControllers.length) {
            return _buildTestCard(test, index, null, null);
          }

          return AnimatedBuilder(
            animation: _cardControllers[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardScaleAnimations[index].value,
                child: Opacity(
                  opacity: _cardFadeAnimations[index].value,
                  child: _buildTestCard(
                    test,
                    index,
                    _cardScaleAnimations[index],
                    _cardFadeAnimations[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTestCard(
    UserTest test,
    int index,
    Animation<double>? scaleAnimation,
    Animation<double>? fadeAnimation,
  ) {
    final subjectColor = _hexToColor(test.subjectColor, fallback: _getSubjectColor(index));
    final subjectName = test.subjectName ?? 'Test';
    final subjectLogo = test.subjectLogo;
    final isPressed = _pressedCardIndex == index;
    final isCompleted = test.isCompleted || _locallyCompletedTestIds.contains(test.id);
    final testStatus = test.testStatus;
    
    // Override status if locally completed
    final displayStatus = isCompleted ? TestStatus.completed : testStatus;
    
    // Determine if test is enabled
    final isEnabled = displayStatus == TestStatus.active;
    final isUpcoming = displayStatus == TestStatus.upcoming;
    final isSkipped = displayStatus == TestStatus.skipped;
    
    // Check if this card should show the completion animation
    final showCompletionAnimation = _justCompletedTestId == test.id;

    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 12 : 12.h),
      child: GestureDetector(
        onTapDown: !isEnabled ? null : (_) {
          setState(() => _pressedCardIndex = index);
        },
        onTapUp: !isEnabled ? null : (_) async {
          setState(() => _pressedCardIndex = null);
          // await SoundService().playButtonClick();
          await VibrationService().selectionVibration();
          _navigateToTestQuiz(test);
        },
        onTapCancel: !isEnabled ? null : () {
          setState(() => _pressedCardIndex = null);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(isPressed ? 0.98 : 1.0),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.grey[100]
                  : (isUpcoming || isSkipped ? Colors.grey[50] : Colors.white),
              borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
              border: Border.all(
                color: isCompleted 
                    ? Colors.green.withOpacity(0.5)
                    : (isSkipped 
                        ? Colors.orange.withOpacity(0.5)
                        : (isUpcoming 
                            ? Colors.grey.withOpacity(0.3) 
                            : (isPressed ? subjectColor : subjectColor.withOpacity(0.3)))),
                width: isPressed ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCompleted 
                      ? Colors.green.withOpacity(0.1)
                      : (isSkipped 
                          ? Colors.orange.withOpacity(0.1)
                          : subjectColor.withOpacity(isPressed ? 0.2 : 0.1)),
                  spreadRadius: 1,
                  blurRadius: isPressed ? 12 : 8,
                  offset: Offset(0, isPressed ? 4 : 3),
                ),
              ],
            ),
            child: Opacity(
              opacity: (isUpcoming || isSkipped) && !isCompleted ? 0.7 : 1.0,
              child: Padding(
                padding: EdgeInsets.all(kIsWeb ? 24 : 20.w),
                child: Row(
                  children: [
                    // Subject icon/logo
                    Container(
                      width: kIsWeb ? 72 : 70.w,
                      height: kIsWeb ? 72 : 70.w,
                      decoration: BoxDecoration(
                        color: subjectColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(kIsWeb ? 18 : 18.r),
                      ),
                      child: subjectLogo != null && subjectLogo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(kIsWeb ? 18 : 18.r),
                              child: CachedNetworkImage(
                                imageUrl: subjectLogo,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => ShimmerImagePlaceholder(
                                  width: kIsWeb ? 72 : 70.w,
                                  height: kIsWeb ? 72 : 70.h,
                                  borderRadius: kIsWeb ? 18 : 18.r,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  _getSubjectIcon(subjectName),
                                  color: subjectColor,
                                  size: kIsWeb ? 36 : 34.sp,
                                ),
                              ),
                            )
                          : Icon(
                              _getSubjectIcon(subjectName),
                              color: subjectColor,
                              size: kIsWeb ? 36 : 34.sp,
                            ),
                    ),
                    SizedBox(width: kIsWeb ? 20 : 18.w),
                    // Test info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.title,
                            style: TextStyle(
                              fontSize: kIsWeb ? 20 : 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: kIsWeb ? 6 : 6.h),
                          Row(
                            children: [
                              Text(
                                subjectName,
                                style: TextStyle(
                                  fontSize: kIsWeb ? 18 : 15.sp,
                                  color: Colors.grey[1200],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(width: kIsWeb ? 15 : 12.w),
                              Icon(
                                Icons.schedule,
                                size: kIsWeb ? 16 : 15.sp,
                                color: Colors.grey[800],
                              ),
                              SizedBox(width: kIsWeb ? 4 : 4.w),
                              Text(
                                _formatTestTime(test),
                                style: TextStyle(
                                  fontSize: kIsWeb ? 14 : 13.sp,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (test.duration != null) ...[
                                SizedBox(width: kIsWeb ? 20 : 10.w),
                                Icon(
                                  Icons.timer_outlined,
                                  size: kIsWeb ? 16 : 15.sp,
                                  color: Colors.grey[800],
                                ),
                                SizedBox(width: kIsWeb ? 4 : 4.w),
                                Text(
                                  '${test.duration} min',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 14 : 13.sp,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    _buildStatusChip(displayStatus, subjectColor, showCompletionAnimation),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TestStatus status, Color subjectColor, bool showAnimation) {
    Color chipColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case TestStatus.completed:
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case TestStatus.upcoming:
        chipColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        label = 'Upcoming';
        icon = Icons.schedule;
        break;
      case TestStatus.skipped:
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Skipped';
        icon = Icons.warning_amber_rounded;
        break;
      case TestStatus.active:
        chipColor = subjectColor.withOpacity(0.1);
        textColor = subjectColor;
        label = 'Active';
        icon = Icons.play_circle_outline;
        break;
    }

    Widget chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 14 : 12.w,
        vertical: kIsWeb ? 8 : 8.h,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: kIsWeb ? 18 : 17.sp,
            color: textColor,
          ),
          SizedBox(width: kIsWeb ? 6 : 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: kIsWeb ? 15 : 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (showAnimation && status == TestStatus.completed) {
      return AnimatedBuilder(
        animation: _completionCheckController!,
        builder: (context, child) {
          return Transform.scale(
            scale: _completionCheckScaleAnimation?.value ?? 1.0,
            child: chip,
          );
        },
      );
    }

    return chip;
  }

  String _formatTestTime(UserTest test) {
    final datetime = test.testDatetime;
    final now = DateTime.now();
    final isToday = datetime.year == now.year && 
                    datetime.month == now.month && 
                    datetime.day == now.day;
    
    final hour = datetime.hour;
    final minute = datetime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    if (isToday) {
      return 'Today, $displayHour:$minute $period';
    }
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[datetime.month - 1]} ${datetime.day}, $displayHour:$minute $period';
  }

  Widget _buildSubjectCard(
    List<UserTest> allTests,
    UserTest test,
    int index,
    Animation<double>? scaleAnimation,
    Animation<double>? fadeAnimation,
  ) {
    final subjectColor = _hexToColor(test.subjectColor, fallback: _getSubjectColor(index));
    final subjectName = test.subjectName ?? test.title;
    final subjectLogo = test.subjectLogo;
    final isPressed = _pressedCardIndex == index;
    final testsForSubject = _getTestsForSubject(allTests, test.subjectId, test.subjectName);
    final testCount = testsForSubject.length;
    // Count completed tests including locally completed ones
    final completedCount = testsForSubject.where((t) => 
      t.isCompleted || _locallyCompletedTestIds.contains(t.id)
    ).length;
    final isAllCompleted = testCount == completedCount && testCount > 0;
    
    // Check if this card should show the completion animation
    final showCompletionAnimation = _shouldShowCompletionAnimation(test);
    final showFullCompletionCelebration = showCompletionAnimation && isAllCompleted;

    Widget cardContent = GestureDetector(
      onTapDown: isAllCompleted ? null : (_) {
        setState(() => _pressedCardIndex = index);
      },
      onTapUp: isAllCompleted ? null : (_) async {
        setState(() => _pressedCardIndex = null);
        // await SoundService().playButtonClick();
        await VibrationService().selectionVibration();
        _navigateToTestQuiz(test);
      },
      onTapCancel: isAllCompleted ? null : () {
        setState(() => _pressedCardIndex = null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isAllCompleted 
                ? (showFullCompletionCelebration ? Colors.green.withOpacity(0.05) : Colors.grey[100])
                : (showCompletionAnimation ? Colors.green.withOpacity(0.03) : Colors.white),
            borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
            border: Border.all(
              color: isAllCompleted 
                  ? (showFullCompletionCelebration ? Colors.green : Colors.grey[400]!)
                  : (showCompletionAnimation ? Colors.green : (isPressed ? subjectColor : subjectColor.withOpacity(0.3))),
              width: showCompletionAnimation ? 3.0 : (isPressed ? 2.5 : 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: showCompletionAnimation
                    ? Colors.green.withOpacity(0.3)
                    : (isAllCompleted 
                        ? Colors.grey.withOpacity(0.1)
                        : subjectColor.withOpacity(isPressed ? 0.25 : 0.15)),
                spreadRadius: showCompletionAnimation ? 4 : (isPressed ? 2 : 1),
                blurRadius: showCompletionAnimation ? 20 : (isPressed ? 15 : 10),
                offset: Offset(0, isPressed ? 6 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient overlay at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: kIsWeb ? 80 : 80.h,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(kIsWeb ? 20 : 20.r),
                      topRight: Radius.circular(kIsWeb ? 20 : 20.r),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        subjectColor.withOpacity(0.15),
                        subjectColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subject icon/logo
                    Container(
                      width: kIsWeb ? 70 : 70.w,
                      height: kIsWeb ? 70 : 70.w,
                      decoration: BoxDecoration(
                        color: subjectColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(kIsWeb ? 18 : 18.r),
                        boxShadow: [
                          BoxShadow(
                            color: subjectColor.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: subjectLogo != null && subjectLogo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(kIsWeb ? 18 : 18.r),
                              child: CachedNetworkImage(
                                imageUrl: subjectLogo,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => ShimmerImagePlaceholder(
                                  width: kIsWeb ? 64 : 64.w,
                                  height: kIsWeb ? 64 : 64.h,
                                  borderRadius: kIsWeb ? 18 : 18.r,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  _getSubjectIcon(subjectName ?? 'Test'),
                                  color: subjectColor,
                                  size: kIsWeb ? 32 : 32.sp,
                                ),
                              ),
                            )
                          : Icon(
                              _getSubjectIcon(subjectName ?? 'Test'),
                              color: subjectColor,
                              size: kIsWeb ? 32 : 32.sp,
                            ),
                    ),
                    SizedBox(height: kIsWeb ? 14 : 14.h),
                    // Subject name
                    Text(
                      subjectName ?? 'Test',
                      style: TextStyle(
                        fontSize: kIsWeb ? 15 : 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: kIsWeb ? 8 : 8.h),
                    // Test count
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 12 : 12.w,
                        vertical: kIsWeb ? 6 : 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isAllCompleted
                            ? Colors.green.withOpacity(0.1)
                            : subjectColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAllCompleted
                                ? Icons.check_circle
                                : Icons.assignment,
                            size: kIsWeb ? 14 : 14.sp,
                            color: isAllCompleted ? Colors.green : subjectColor,
                          ),
                          SizedBox(width: kIsWeb ? 4 : 4.w),
                          Text(
                            isAllCompleted
                                ? 'Completed'
                                : '$testCount test${testCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: kIsWeb ? 11 : 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isAllCompleted ? Colors.green : subjectColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Completion badge
              if (isAllCompleted || showCompletionAnimation)
                Positioned(
                  top: kIsWeb ? 10 : 10.h,
                  right: kIsWeb ? 10 : 10.w,
                  child: showCompletionAnimation
                      ? AnimatedBuilder(
                          animation: _completionCheckController!,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _completionCheckScaleAnimation?.value ?? 1.0,
                              child: Opacity(
                                opacity: _completionCheckOpacityAnimation?.value ?? 1.0,
                                child: Container(
                                  padding: EdgeInsets.all(kIsWeb ? 8 : 8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: kIsWeb ? 18 : 18.sp,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          padding: EdgeInsets.all(kIsWeb ? 6 : 6.w),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: kIsWeb ? 14 : 14.sp,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
    
    // Wrap with pulse animation and confetti if showing completion animation
    if (showCompletionAnimation && _completionPulseAnimation != null) {
      return ConfettiCelebration(
        isPlaying: _showConfetti,
        particleCount: showFullCompletionCelebration ? 50 : 30,
        duration: const Duration(milliseconds: 1500),
        child: AnimatedBuilder(
          animation: _completionPulseController!,
          builder: (context, child) {
            return Transform.scale(
              scale: _completionPulseAnimation!.value,
              child: cardContent,
            );
          },
        ),
      );
    }
    
    // Apply opacity for completed cards that are not currently animating
    if (isAllCompleted && !showCompletionAnimation) {
      return Opacity(
        opacity: 0.6,
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Color _getSubjectColor(int index) {
    final colors = [
      const Color(0xFFFF9800), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF6989FF), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFFE91E63), // Pink
    ];
    return colors[index % colors.length];
  }

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') || name.contains('algebra') || name.contains('geometry')) {
      return Icons.functions;
    } else if (name.contains('science') || name.contains('physics') || name.contains('chemistry')) {
      return Icons.science;
    } else if (name.contains('english') || name.contains('language')) {
      return Icons.language;
    } else if (name.contains('history') || name.contains('social')) {
      return Icons.history_edu;
    } else if (name.contains('geography')) {
      return Icons.public;
    } else if (name.contains('computer') || name.contains('programming')) {
      return Icons.computer;
    } else if (name.contains('biology') || name.contains('bio')) {
      return Icons.biotech;
    } else if (name.contains('art') || name.contains('draw')) {
      return Icons.palette;
    } else if (name.contains('music')) {
      return Icons.music_note;
    } else {
      return Icons.assignment;
    }
  }

  Future<void> _navigateToTestQuiz(UserTest test) async {
    final completedTestId = await Navigator.push<String>(
      context,
      ConnectedPageTransitions.connectedZoom(
        page: TestQuizScreen(test: test),
      ),
    );
    
    // If a test was completed, update local state and trigger celebration animation
    if (completedTestId != null && mounted) {
      setState(() {
        _locallyCompletedTestIds.add(completedTestId);
      });
      
      // Trigger the completion celebration animation
      _triggerCompletionAnimation(completedTestId);
    }
    
    // Refresh tests after returning from the quiz screen
    if (mounted) {
      context.read<UserTestBloc>().add(const RefreshUserTests());
    }
  }
  
  // Check if a card should show the completion animation
  bool _shouldShowCompletionAnimation(UserTest test) {
    if (_justCompletedTestId == null) return false;
    return test.id == _justCompletedTestId ||
           test.subjectId == _getSubjectIdFromTestId(_justCompletedTestId!);
  }
  
  // Helper to get subject ID from test ID
  String? _getSubjectIdFromTestId(String testId) {
    final userTestBloc = context.read<UserTestBloc>();
    for (final test in userTestBloc.cachedTests) {
      if (test.id == testId) {
        return test.subjectId;
      }
    }
    return null;
  }
}
