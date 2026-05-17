import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/module_questions/module_questions_bloc.dart';
import '../../models/module_model.dart';
import '../../models/subject_model.dart';
import '../../models/module_chapter_model.dart';
import '../../models/question_model.dart';
import '../../services/sound_service.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../widgets/smooth_scroll_wrapper.dart';
import '../../widgets/shimmer_image_placeholder.dart';
import '../quiz/quiz_screen.dart';

class ChapterTheoryScreen extends StatefulWidget {
  final Subject subject;
  final Module module;
  final ModuleChapter chapter;

  const ChapterTheoryScreen({
    super.key,
    required this.subject,
    required this.module,
    required this.chapter,
  });

  @override
  State<ChapterTheoryScreen> createState() => _ChapterTheoryScreenState();
}

class _ChapterTheoryScreenState extends State<ChapterTheoryScreen>
    with TickerProviderStateMixin {
  bool _isContinueButtonPressed = false;
  bool _isLoadingQuestions = false;

  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Content entrance animations
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Image floating animation
  late AnimationController _imageFloatController;
  late Animation<double> _imageFloatAnimation;

  // Image glow animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Helper function to convert hex string to Color
  Color _hexToColor(String? hexString, {Color fallback = Colors.blue}) {
    if (hexString == null || hexString.isEmpty) {
      return fallback;
    }
    try {
      String hex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallback;
    }
  }

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

    // Debug: Check what theory data we have
    print('🔍 ChapterTheoryScreen - Chapter: ${widget.chapter.name}');
    print('🔍 ChapterTheoryScreen - Theory: ${widget.chapter.theory}');
    print('🔍 ChapterTheoryScreen - Theory isEmpty: ${widget.chapter.theory?.isEmpty}');

    // Initialize circle animation controllers
    _circle1Controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _circle2Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _circle3Controller = AnimationController(
      duration: const Duration(seconds: 8),
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
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));

    // Initialize entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Initialize image floating animation
    _imageFloatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _imageFloatAnimation = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _imageFloatController,
      curve: Curves.easeInOut,
    ));

    // Initialize glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start entrance animation
    _entranceController.forward();
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _entranceController.dispose();
    _imageFloatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToQuiz() {
    // Play start questions sound before loading quiz
    // SoundService().playStartQuestions();
    
    // Trigger the API call to load module questions
    setState(() {
      _isLoadingQuestions = true;
    });
    context.read<ModuleQuestionsBloc>().add(LoadModuleQuestions(widget.chapter.id));
  }

  void _handleQuestionsLoaded(List<Question> questions) {
    setState(() {
      _isLoadingQuestions = false;
    });
    
    if (questions.isNotEmpty) {
      // Navigate to quiz with the list of questions using connected zoom
      Navigator.of(context).pushReplacement(
        ConnectedPageTransitions.connectedZoom(
          page: QuizScreen(
            subject: widget.subject,
            module: widget.module,
            chapter: widget.chapter,
            questions: questions,
          ),
        ),
      );
    } else {
      // No questions available - module is being uploaded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please wait, chapter is being uploaded',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _handleQuestionsError(String message) {
    setState(() {
      _isLoadingQuestions = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load content: $message',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ModuleQuestionsBloc, ModuleQuestionsState>(
      listener: (context, state) {
        if (state is ModuleQuestionsLoaded) {
          _handleQuestionsLoaded(state.questions);
        } else if (state is ModuleQuestionsError) {
          _handleQuestionsError(state.message);
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          // White base background
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),
          // Top gradient (1/4 of screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kIsWeb ? 200 : 0.25.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      _getGradientColors(_hexToColor(widget.subject.color)),
                  stops: const [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0],
                ),
              ),
            ),
          ),
          // Bottom gradient (1/3 of screen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kIsWeb ? 250 : 0.33.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getBottomGradientColors(
                      _hexToColor(widget.subject.color)),
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Circular shapes overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Large circle in upper left
                  AnimatedBuilder(
                    animation: _circle1Animation,
                    builder: (context, child) {
                      return Positioned(
                        top:
                            (kIsWeb ? 80.0 : 100.h) + _circle1Animation.value,
                        left: (kIsWeb ? -40.0 : -50.w) +
                            _circle1Animation.value * 0.5,
                        child: Container(
                          width: kIsWeb ? 150 : 200.w,
                          height: kIsWeb ? 150 : 200.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hexToColor(widget.subject.color)
                                .withOpacity(0.15),
                          ),
                        ),
                      );
                    },
                  ),
                  // Medium circle in upper right
                  AnimatedBuilder(
                    animation: _circle2Animation,
                    builder: (context, child) {
                      return Positioned(
                        top: (kIsWeb ? 40.0 : 50.h) + _circle2Animation.value,
                        right: (kIsWeb ? -20.0 : -30.w) -
                            _circle2Animation.value * 0.5,
                        child: Container(
                          width: kIsWeb ? 120 : 150.w,
                          height: kIsWeb ? 120 : 150.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hexToColor(widget.subject.color)
                                .withOpacity(0.2),
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
                        bottom: (kIsWeb ? 180.0 : 240.h) -
                            _circle3Animation.value,
                        right: kIsWeb ? 20 : 20.w,
                        child: Container(
                          width: kIsWeb ? 40 : 50.w,
                          height: kIsWeb ? 40 : 50.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hexToColor(widget.subject.color)
                                .withOpacity(0.25),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  margin: EdgeInsets.only(
                    top: kIsWeb ? 20 : 20.h,
                    left: kIsWeb ? 20 : 20.w,
                    right: kIsWeb ? 20 : 20.w,
                  ),
                  child: Row(
                    children: [
                      // Back Arrow
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: kIsWeb ? 22 : 24,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SmoothScrollOverlay(
                    showTopFade: false,
                    showBottomFade: false,
                    fadeHeight: kIsWeb ? 40 : 40.h,
                    fadeColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 24 : 24.w,
                        vertical: kIsWeb ? 20 : 20.h,
                      ),
                      child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: kIsWeb ? 600 : double.infinity,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chapter header
                            Center(
                              child: Column(
                                children: [
                                      // Module badge with animation
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kIsWeb ? 14 : 14.w,
                                          vertical: kIsWeb ? 6 : 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _hexToColor(widget.subject.color)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              kIsWeb ? 20 : 20.r),
                                          border: Border.all(
                                            color: _hexToColor(widget.subject.color)
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                    'MODULE ${widget.chapter.order}',
                                    style: TextStyle(
                                            fontSize: kIsWeb ? 12 : 13.sp,
                                      color: _hexToColor(widget.subject.color),
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                      SizedBox(height: kIsWeb ? 12 : 14.h),
                                  Text(
                                    widget.chapter.name,
                                    style: TextStyle(
                                          fontSize: kIsWeb ? 26 : 30.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                          height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: kIsWeb ? 32 : 40.h),

                            // Chapter image (if present)
                            if (widget.chapter.logo != null &&
                                widget.chapter.logo!.isNotEmpty)
                              Column(
                                children: [
                                  Center(
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge([
                                        _imageFloatAnimation,
                                        _glowAnimation,
                                      ]),
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _imageFloatAnimation.value),
                                          child: SizedBox(
                                            width: kIsWeb ? 500 : MediaQuery.of(context).size.width * 0.92,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                // Decorative blobs behind image
                                                Positioned(
                                                  top: kIsWeb ? -15 : -15.h,
                                                  left: kIsWeb ? -20 : -20.w,
                                                child: Container(
                                                  width: kIsWeb ? 70 : 80.w,
                                                  height: kIsWeb ? 70 : 80.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.5),
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.1),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: kIsWeb ? -10 : -10.h,
                                                right: kIsWeb ? -15 : -15.w,
                                                child: Container(
                                                  width: kIsWeb ? 50 : 60.w,
                                                  height: kIsWeb ? 50 : 60.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.4),
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.05),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Glass container
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(
                                                    kIsWeb ? 24 : 24.r),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                                  child: Container(
                                                    padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
                              decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          Colors.white.withOpacity(0.7),
                                                          Colors.white.withOpacity(0.5),
                                                          _hexToColor(widget.subject.color)
                                                              .withOpacity(0.08),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(
                                                          kIsWeb ? 24 : 24.r),
                                                      boxShadow: [
                                                        BoxShadow(
                                color: _hexToColor(widget.subject.color)
                                                              .withOpacity(_glowAnimation.value * 0.35),
                                                          blurRadius: 25,
                                                          spreadRadius: 0,
                                                        ),
                                                      ],
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.6),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                                            kIsWeb ? 14 : 14.r),
                                                        child: Image.network(
                                                          widget.chapter.logo!,
                                                          height: kIsWeb ? 180 : 200.h,
                                                          // width: kIsWeb ? 240 : 260.w,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder:
                                                              (context, child, loadingProgress) {
                                                            if (loadingProgress == null) {
                                                              return child;
                                                            }
                                                            return ShimmerImagePlaceholder(
                                                              width: kIsWeb ? 240 : 260.w,
                                                              height: kIsWeb ? 180 : 200.h,
                                                              borderRadius: kIsWeb ? 14 : 14.r,
                                                              baseColor: _hexToColor(
                                                                      widget.subject.color)
                                                                  .withOpacity(0.15),
                                                              highlightColor: _hexToColor(
                                                                      widget.subject.color)
                                                                  .withOpacity(0.05),
                                                            );
                                                          },
                                                          errorBuilder:
                                                              (context, error, stackTrace) {
                                                            return const SizedBox.shrink();
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: kIsWeb ? 28 : 32.h),
                                ],
                              ),

                                // Theory content card with glass effect
                                AnimatedBuilder(
                                  animation: _glowAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Animated decorative colored shapes behind glass
                                        Positioned(
                                          top: kIsWeb ? 15 : 15.h,
                                          left: kIsWeb ? -35 : -35.w,
                                          child: AnimatedBuilder(
                                            animation: _circle1Animation,
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(_circle1Animation.value * 0.3, 0),
                                                child: Container(
                                                  width: kIsWeb ? 110 : 130.w,
                                                  height: kIsWeb ? 110 : 130.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.65),
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.15),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: kIsWeb ? 50 : 70.h,
                                          right: kIsWeb ? -25 : -25.w,
                                          child: AnimatedBuilder(
                                            animation: _circle2Animation,
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(0, _circle2Animation.value * 0.4),
                                                child: Container(
                                                  width: kIsWeb ? 90 : 100.w,
                                                  height: kIsWeb ? 90 : 100.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.55),
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.1),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          bottom: kIsWeb ? 30 : 40.h,
                                          left: kIsWeb ? 30 : 40.w,
                                          child: AnimatedBuilder(
                                            animation: _circle3Animation,
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(_circle3Animation.value * 0.5, _circle3Animation.value * 0.3),
                                                child: Container(
                                                  width: kIsWeb ? 70 : 80.w,
                                                  height: kIsWeb ? 70 : 80.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.45),
                                                        _hexToColor(widget.subject.color)
                                                            .withOpacity(0.08),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Extra decorative blob
                                        Positioned(
                                          bottom: kIsWeb ? 80 : 100.h,
                                          right: kIsWeb ? 50 : 60.w,
                                          child: Container(
                                            width: kIsWeb ? 45 : 50.w,
                                            height: kIsWeb ? 45 : 50.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  _hexToColor(widget.subject.color)
                                                      .withOpacity(0.35),
                                                  _hexToColor(widget.subject.color)
                                                      .withOpacity(0.05),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Glass container
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(kIsWeb ? 28 : 28.r),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.all(kIsWeb ? 24 : 24.w),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(0.55),
                                                    Colors.white.withOpacity(0.35),
                                                    _hexToColor(widget.subject.color)
                                                        .withOpacity(0.12),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                                borderRadius: BorderRadius.circular(kIsWeb ? 28 : 28.r),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _hexToColor(widget.subject.color)
                                                        .withOpacity(_glowAnimation.value * 0.2),
                                                    blurRadius: 35,
                                                    spreadRadius: 0,
                                                    offset: const Offset(0, 12),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.7),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Decorative gradient line with glow
                            Container(
                                                    width: kIsWeb ? 60 : 60.w,
                                                    height: kIsWeb ? 5 : 5.h,
                              decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          _hexToColor(widget.subject.color),
                                                          _hexToColor(widget.subject.color)
                                                              .withOpacity(0.5),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                                          color: _hexToColor(widget.subject.color)
                                                              .withOpacity(0.4),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                                                  ),
                                                  SizedBox(height: kIsWeb ? 20 : 22.h),
                                                  Text(
                                                    widget.chapter.theory?? 'No theory content available for this chapter.',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 15 : 16.sp,
                                  color: Colors.black87,
                                                      height: 1.8,
                                                      letterSpacing: 0.25,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                            ),

                            SizedBox(height: kIsWeb ? 100 : 120.h),
                          ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),

                // Continue button at bottom
                _buildContinueButton(),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildContinueButton() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative gradient blobs behind button
          Positioned(
            left: kIsWeb ? 20 : 30.w,
            child: Container(
              width: kIsWeb ? 60 : 70.w,
              height: kIsWeb ? 60 : 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _hexToColor(widget.subject.color).withOpacity(0.5),
                    _hexToColor(widget.subject.color).withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: kIsWeb ? 30 : 40.w,
            child: Container(
              width: kIsWeb ? 50 : 55.w,
              height: kIsWeb ? 50 : 55.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _hexToColor("365DEA").withOpacity(0.4),
                    _hexToColor("365DEA").withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Glass container with button
          ClipRRect(
            borderRadius: BorderRadius.circular(kIsWeb ? 28 : 34.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
                width: kIsWeb ? 320 : 340.w,
                padding: EdgeInsets.all(kIsWeb ? 14 : 16.w),
        margin: EdgeInsets.only(
          bottom: kIsWeb ? 20 : 20.h,
        ),
        decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.65),
                      Colors.white.withOpacity(0.45),
                      _hexToColor(widget.subject.color).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(kIsWeb ? 28 : 34.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hexToColor(widget.subject.color).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        child: GestureDetector(
          onTapDown: _isLoadingQuestions ? null : (_) {
            setState(() {
              _isContinueButtonPressed = true;
            });
          },
          onTapUp: _isLoadingQuestions ? null : (_) {
            setState(() {
              _isContinueButtonPressed = false;
            });
            _navigateToQuiz();
          },
          onTapCancel: _isLoadingQuestions ? null : () {
            setState(() {
              _isContinueButtonPressed = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
                    width: kIsWeb ? 200 : 240.w,
                    height: kIsWeb ? 52 : 56.h,
            decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isLoadingQuestions
                            ? [
                                _hexToColor("365DEA").withOpacity(0.7),
                                _hexToColor("4A6FEF").withOpacity(0.7),
                              ]
                            : [
                                _hexToColor("365DEA"),
                                _hexToColor("4A6FEF"),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(kIsWeb ? 22 : 26.r),
              border: Border(
                bottom: BorderSide(
                  width: _isContinueButtonPressed ? 1 : 4,
                  color: _hexToColor("2A4BC0"),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: _hexToColor("365DEA")
                              .withOpacity(_isContinueButtonPressed ? 0.25 : 0.5),
                          blurRadius: _isContinueButtonPressed ? 6 : 12,
                          offset: Offset(0, _isContinueButtonPressed ? 2 : 6),
                ),
              ],
            ),
            child: Center(
              child: _isLoadingQuestions
                  ? SizedBox(
                      width: kIsWeb ? 24 : 24.w,
                      height: kIsWeb ? 24 : 24.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                                    fontSize: kIsWeb ? 17 : 20.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: kIsWeb ? 8 : 8.w),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: kIsWeb ? 20 : 22,
                                ),
                              ],
                      ),
                    ),
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }
}
