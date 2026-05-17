import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/study_timer.dart';
import '../../utils/web_size_utils.dart';
import '../../models/subject_model.dart';
import '../../models/module_model.dart';
import '../../models/module_chapter_model.dart';
import '../../screens/quiz/quiz_screen.dart';
import '../../screens/confirmation/confirmation_screen.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/subject/subject_bloc.dart';
import '../../utils/animation_utils.dart';
import '../../services/vibration_service.dart';
import '../smooth_scroll_wrapper.dart';

class HomeContent extends StatefulWidget {
  final StudyTimer studyTimer;
  final Function(int)? onNavigateToSubject;
  final Function(Color)? onPageColorChanged;

  const HomeContent({
    super.key,
    required this.studyTimer,
    this.onNavigateToSubject,
    this.onPageColorChanged,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late PageController _pageController;
  bool _hasResetPageController = false;
  late AnimationController _transitionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isTransitioning = false;
  
  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;
  
  // Image container animation
  late AnimationController _imageController;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _imageFadeAnimation;
  
  // Shimmer animation for loading state
  late AnimationController _shimmerController;
  
  // Start button press state
  bool _isStartButtonPressed = false;

  // Helper function to convert hex string to Color
  Color _hexToColor(String? hexString, {Color fallback = Colors.blue}) {
    if (hexString == null || hexString.isEmpty) {
      return fallback;
    }
    try {
      // Remove # if present and add it if not
      String hex = hexString.startsWith('#') ? hexString.substring(1) : hexString;
      // Add # prefix for Color parsing
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallback;
    }
  }

  Color _getCurrentPageColor(List<Subject>? subjects) {
    if (subjects != null && 
        subjects.isNotEmpty && 
        _currentPage < subjects.length) {
      final subject = subjects[_currentPage];
      return _hexToColor(subject.color);
    }
    // Fallback to default colors if subjects not loaded
    final List<Color> fallbackColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return fallbackColors[_currentPage % fallbackColors.length];
  }

  // Helper function to create light/pastel versions of color for gradients
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white, // Very subtle tint
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white, // Subtle tint
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white, // Light tint
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white, // Medium light tint
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white, // Pastel color
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white, // Fade back
      Colors.white, // Blend back to white
    ];
  }

  List<Color> _getBottomGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white, // Light tint
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white, // Pastel color
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.studyTimer.addListener(_onTimerChanged);
    
    // Initialize PageController with viewportFraction for easier scrolling
    // On web, use smaller viewport fraction so cards are easier to swipe
    _pageController = PageController(
      viewportFraction: kIsWeb ? 0.85 : 1.0,
    );

    // Initialize animation controllers
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

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

    // Initialize image container animation controller
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _imageScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeOut,
    ));

    _imageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeInOut,
    ));

    // Initialize shimmer animation controller
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Start initial animation
    _imageController.forward();

    // Load subjects when widget initializes, but only if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSubjectsLoaded();
    });

    // Notify parent about initial color
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onPageColorChanged != null && mounted) {
        final subjectBloc = context.read<SubjectBloc>();
        final subjects = subjectBloc.cachedSubjects;
        widget.onPageColorChanged!(_getCurrentPageColor(subjects));
      }
    });
  }

  @override
  void dispose() {
    widget.studyTimer.removeListener(_onTimerChanged);
    _pageController.dispose();
    _transitionController.dispose();
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _imageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTimerChanged() {
    setState(() {
      // Rebuild the widget when timer changes
    });
  }

  List<Subject> _getCurrentSubjects() {
    final subjectBloc = context.read<SubjectBloc>();
    final subjects = subjectBloc.cachedSubjects;
    // Sort subjects: has_due_module = true comes first
    return List<Subject>.from(subjects)
      ..sort((a, b) {
        // Subjects with has_due_module = true come first
        if (a.hasDueModule && !b.hasDueModule) return -1;
        if (!a.hasDueModule && b.hasDueModule) return 1;
        return 0; // Maintain original order for subjects with same has_due_module value
      });
  }

  void _ensureSubjectsLoaded() {
    final subjectBloc = context.read<SubjectBloc>();
    if (!subjectBloc.hasFetchedSubjects) {
      subjectBloc.add(const LoadSubjects());
    } else if (subjectBloc.cachedSubjects.isNotEmpty) {
      // Force emit cached subjects to update the UI
      subjectBloc.add(const LoadSubjects());
    }
  }

  void _resetPageController() {
    // Only reset if we're not already at page 0 and the controller has clients
    if (_pageController.hasClients &&
        _currentPage != 0 &&
        !_hasResetPageController) {
      _hasResetPageController = true;
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = 0;
      });

      // Reset the flag after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _hasResetPageController = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        // Get subjects from state or cached subjects
        List<Subject> subjects = [];
        if (state is SubjectsLoaded) {
          subjects = state.subjects;
        } else {
          subjects = _getCurrentSubjects();
        }
        
        // Sort subjects: has_due_module = true comes first
        subjects = List<Subject>.from(subjects)
          ..sort((a, b) {
            // Subjects with has_due_module = true come first
            if (a.hasDueModule && !b.hasDueModule) return -1;
            if (!a.hasDueModule && b.hasDueModule) return 1;
            return 0; // Maintain original order for subjects with same has_due_module value
          });
        
        final currentColor = _getCurrentPageColor(subjects);
        final topGradientColors = _getGradientColors(currentColor);
        final bottomGradientColors = _getBottomGradientColors(currentColor);
        
        return Stack(
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
                height: 0.25.sh, // 1/4 of screen height
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: topGradientColors,
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
                height: 0.33.sh, // 1/3 of screen height
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: bottomGradientColors,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Circular shapes overlay
            Positioned.fill(
              child: Stack(
                children: [
                  // Large circle in top right
                  AnimatedBuilder(
                    animation: _circle1Animation,
                    builder: (context, child) {
                      return Positioned(
                        top: -100 + _circle1Animation.value, // Fixed position
                        right: -100, // Fixed position
                        child: Container(
                          width: WebSize.width(context, 300), // Scaled size
                          height: WebSize.width(context, 300), // Scaled size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentColor.withOpacity(0.15),
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
                        top: 240 + _circle2Animation.value, // Fixed position
                        left: 40, // Fixed position
                        child: Container(
                          width: WebSize.width(context, 120), // Scaled size
                          height: WebSize.width(context, 120), // Scaled size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentColor.withOpacity(0.25),
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
                        bottom: 240 - _circle3Animation.value, // Fixed position
                        right: 20, // Fixed position
                        child: Container(
                          width: WebSize.width(context, 50), // Scaled size
                          height: WebSize.width(context, 50), // Scaled size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentColor.withOpacity(0.25),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Content - wrapped in LayoutBuilder to fill available space
            LayoutBuilder(
              builder: (context, constraints) {
                return SmoothScrollOverlay(
                  showTopFade: false,
                  showBottomFade: true,
                  fadeHeight: kIsWeb ? 40 : 40.h,
                  fadeColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top spacing - only on mobile
                          if (!kIsWeb)
                            SizedBox(
                              height: WebSize.height(context, 70),
                            ),

                          // Central Card with Subjects
                          SizedBox(
                            height: WebSize.height(context, 472),
                            width: double.infinity,
                            child: _buildCentralCard(),
                          ),

                          // Pagination Dots
                          _buildPaginationDots(),

                          // Flexible spacer to push content and fill remaining space
                          const Spacer(),

                          // Bottom Buttons
                          _buildBottomButtons(context),
                          
                          // Bottom padding for floating navigation bar
                          SizedBox(height: WebSize.height(context, 20)),
                          if (!kIsWeb)
                            SizedBox(
                              height: 100.h, // Space for floating nav bar
                            ),

                        ],
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeHeader() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        String userName = 'Student';
        if (state is UserAuthenticated) {
          userName = state.user.firstName.isNotEmpty
              ? state.user.firstName
              : state.user.username;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: kIsWeb ? 16 : 16.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: kIsWeb ? 4 : 4.h),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: kIsWeb ? 24 : 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: kIsWeb ? 50 : 50.w,
                  height: kIsWeb ? 50 : 50.w,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: kIsWeb ? 20 : 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCentralCard() {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        if (state is SubjectLoading) {
          return _buildSkeletonLoader();
        }

        if (state is SubjectError) {
          return Container(
            height: kIsWeb ? 200 : 200.h,
            padding: EdgeInsets.all(kIsWeb ? 24 : 24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: kIsWeb ? 8 : 8.r,
                  offset: Offset(0, kIsWeb ? 2 : 2.h),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Error loading subjects: ${state.message}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Handle SubjectsLoaded state
        if (state is SubjectsLoaded) {
          // Sort subjects: has_due_module = true comes first
          final sortedSubjects = List<Subject>.from(state.subjects)
            ..sort((a, b) {
              // Subjects with has_due_module = true come first
              if (a.hasDueModule && !b.hasDueModule) return -1;
              if (!a.hasDueModule && b.hasDueModule) return 1;
              return 0; // Maintain original order for subjects with same has_due_module value
            });
          
          if (sortedSubjects.isNotEmpty) {
            // Don't reset page controller - preserve current page state

            return Center(
              child: SizedBox(
                width: kIsWeb ? 500 : double.infinity, // Constrained width on web for easier scrolling
                child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(), // Clean, natural page snapping
                pageSnapping: true, // Ensure pages snap
                onPageChanged: (index) async {
                  // Add vibration effect when sliding between pages
                  await VibrationService().selectionVibration();

                  setState(() {
                    _currentPage = index;
                  });
                  
                  // Trigger image animation on page change
                  _imageController.reset();
                  _imageController.forward();
                  
                  // Notify parent about color change
                  if (widget.onPageColorChanged != null) {
                    widget.onPageColorChanged!(_getCurrentPageColor(sortedSubjects));
                  }
                },
                itemCount: sortedSubjects.length,
                itemBuilder: (context, index) {
                  final subject = sortedSubjects[index];
                  return AnimatedBuilder(
                    animation: _transitionController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: AnimationUtils.animatedCard(
                          index: index,
                          delay: Duration(milliseconds: index * 100),
                          child: _buildSubjectCard(subject),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            );
          } else {
            // Subjects loaded but empty
            return Container(
              padding: EdgeInsets.all(kIsWeb ? 24 : 24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: kIsWeb ? 8 : 8.r,
                    offset: Offset(0, kIsWeb ? 2 : 2.h),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'No subjects available',
                  style: TextStyle(
                    fontSize: kIsWeb ? 16 : 16.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }
        }

        // Default empty state - try to load subjects if not already loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureSubjectsLoaded();
        });

        return Container(
          padding: EdgeInsets.all(kIsWeb ? 24 : 24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: kIsWeb ? 8 : 8.r,
                offset: Offset(0, kIsWeb ? 2 : 2.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Loading subjects...',
              style: TextStyle(
                fontSize: kIsWeb ? 16 : 16.sp,
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Padding(
      padding: EdgeInsets.only(top: kIsWeb ? 16 : 16.h, left: kIsWeb ? 16 : 16.w, right: kIsWeb ? 16 : 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subject Name and Class
          Text(
            subject.name,
            style: TextStyle(
              fontSize: kIsWeb ? 35 : 35.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kIsWeb ? 40 : 40.h),
          Text(
            'Class IX',
            style: TextStyle(
              fontSize: kIsWeb ? 16 : 16.sp,
              color: _hexToColor(subject.color),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: kIsWeb ? 40 : 40.h),
          // Image with curved border card
          AnimatedBuilder(
            animation: _imageController,
            builder: (context, child) {
              return Transform.scale(
                scale: _imageScaleAnimation.value,
                child: Opacity(
                  opacity: _imageFadeAnimation.value,
                  child: Container(
                    height: kIsWeb ? 276 : 276.h,
                    width: kIsWeb ? 285 : 285.w,
                    margin: EdgeInsets.only(left: kIsWeb ? 50 : 50.w, right: kIsWeb ? 50 : 50.w, top: kIsWeb ? 24 : 24.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kIsWeb ? 32 : 32.r),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: kIsWeb ? 1 : 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: kIsWeb ? 4 : 4.r,
                          offset: Offset(0, kIsWeb ? 2 : 2.h),
                        ),
                      ],
                    ),
                    child: ClipRRect  (
                      borderRadius: BorderRadius.circular(kIsWeb ? 32 : 32.r),
                      child: Image.network(
                              subject.logo,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                final subjectColor = _hexToColor(subject.color);
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        subjectColor.withOpacity(0.05),
                                        subjectColor.withOpacity(0.12),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: kIsWeb ? 60 : 60.w,
                                        height: kIsWeb ? 60 : 60.w,
                                        decoration: BoxDecoration(
                                          color: subjectColor.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getSubjectIcon(subject.name),
                                          size: kIsWeb ? 28 : 28.w,
                                          color: subjectColor.withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: kIsWeb ? 12 : 12.h),
                                      Text(
                                        subject.name,
                                        style: TextStyle(
                                          fontSize: kIsWeb ? 14 : 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: subjectColor.withOpacity(0.8),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                // Calculate progress percentage
                                final progress = loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null;
                                
                                return AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(-1.0 + 2 * _shimmerController.value, -0.3),
                                          end: Alignment(-0.5 + 2 * _shimmerController.value, 0.3),
                                          colors: [
                                            _hexToColor(subject.color).withOpacity(0.08),
                                            _hexToColor(subject.color).withOpacity(0.02),
                                            _hexToColor(subject.color).withOpacity(0.08),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Custom circular progress with subject color
                                            SizedBox(
                                              width: kIsWeb ? 50 : 50.w,
                                              height: kIsWeb ? 50 : 50.w,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  // Background circle
                                                  Container(
                                                    width: kIsWeb ? 50 : 50.w,
                                                    height: kIsWeb ? 50 : 50.w,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _hexToColor(subject.color).withOpacity(0.2),
                                                        width: kIsWeb ? 3 : 3.w,
                                                      ),
                                                    ),
                                                  ),
                                                  // Progress indicator
                                                  SizedBox(
                                                    width: kIsWeb ? 50 : 50.w,
                                                    height: kIsWeb ? 50 : 50.w,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: kIsWeb ? 3 : 3.w,
                                                      value: progress,
                                                      backgroundColor: Colors.transparent,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        _hexToColor(subject.color).withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ),
                                                  // Percentage text
                                                  if (progress != null)
                                                    Text(
                                                      '${(progress * 100).toInt()}%',
                                                      style: TextStyle(
                                                        fontSize: kIsWeb ? 11 : 11.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: _hexToColor(subject.color).withOpacity(0.8),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: kIsWeb ? 16 : 16.h),
                                            // Loading text with dots animation
                                            Text(
                                              'Loading...',
                                              style: TextStyle(
                                                fontSize: kIsWeb ? 12 : 12.sp,
                                                fontWeight: FontWeight.w500,
                                                color: _hexToColor(subject.color).withOpacity(0.6),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') ||
        name.contains('algebra') ||
        name.contains('geometry')) {
      return Icons.functions;
    } else if (name.contains('science') ||
        name.contains('physics') ||
        name.contains('chemistry')) {
      return Icons.science;
    } else if (name.contains('english') || name.contains('language')) {
      return Icons.language;
    } else if (name.contains('history') || name.contains('social')) {
      return Icons.history_edu;
    } else if (name.contains('geography')) {
      return Icons.public;
    } else if (name.contains('computer') || name.contains('programming')) {
      return Icons.computer;
    } else {
      return Icons.book;
    }
  }

  Widget _buildSkeletonLoader() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            top: kIsWeb ? 16 : 16.h,
            left: kIsWeb ? 16 : 16.w,
            right: kIsWeb ? 16 : 16.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subject Name skeleton
              _buildShimmerBox(
                width: kIsWeb ? 180 : 180.w,
                height: kIsWeb ? 40 : 40.h,
                borderRadius: kIsWeb ? 8 : 8.r,
              ),
              SizedBox(height: kIsWeb ? 40 : 40.h),
              // Class skeleton
              _buildShimmerBox(
                width: kIsWeb ? 80 : 80.w,
                height: kIsWeb ? 20 : 20.h,
                borderRadius: kIsWeb ? 6 : 6.r,
              ),
              SizedBox(height: kIsWeb ? 40 : 40.h),
              // Image container skeleton
              Container(
                height: kIsWeb ? 276 : 276.h,
                width: kIsWeb ? 285 : 285.w,
                margin: EdgeInsets.only(
                  left: kIsWeb ? 50 : 50.w,
                  right: kIsWeb ? 50 : 50.w,
                  top: kIsWeb ? 24 : 24.h,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kIsWeb ? 32 : 32.r),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + 2 * _shimmerController.value, 0),
                    end: Alignment(-0.5 + 2 * _shimmerController.value, 0),
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade50,
                      Colors.grey.shade200,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: kIsWeb ? 4 : 4.r,
                      offset: Offset(0, kIsWeb ? 2 : 2.h),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle icon placeholder
                    Icon(
                      Icons.image_outlined,
                      size: kIsWeb ? 60 : 60.w,
                      color: Colors.grey.shade300,
                    ),
                    // Pulsing overlay
                    AnimatedBuilder(
                      animation: _circle1Controller,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(kIsWeb ? 32 : 32.r),
                            color: Colors.white.withOpacity(0.1 * _circle1Animation.value.abs() / 20),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _shimmerController.value, 0),
              end: Alignment(-0.5 + 2 * _shimmerController.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade50,
                Colors.grey.shade200,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationDots() {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        List<Subject> subjects = [];

        // Get subjects from different states
        if (state is SubjectsLoaded) {
          subjects = state.subjects;
        } else if (state is SubjectLoaded) {
          subjects = [state.subject];
        } else {
          // Try to get cached subjects from bloc
          final subjectBloc = context.read<SubjectBloc>();
          if (subjectBloc.hasFetchedSubjects) {
            subjects = subjectBloc.cachedSubjects;
          }
        }

        // Sort subjects: has_due_module = true comes first
        subjects = List<Subject>.from(subjects)
          ..sort((a, b) {
            // Subjects with has_due_module = true come first
            if (a.hasDueModule && !b.hasDueModule) return -1;
            if (!a.hasDueModule && b.hasDueModule) return 1;
            return 0; // Maintain original order for subjects with same has_due_module value
          });

        if (subjects.isNotEmpty && subjects.length > 1) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pagination dots
              ...List.generate(
                subjects.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: WebSize.width(context, 4)),
                  width: index == _currentPage ? WebSize.width(context, 12) : WebSize.width(context, 8),
                  height: index == _currentPage ? WebSize.height(context, 12) : WebSize.height(context, 8),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? _getCurrentPageColor(_getCurrentSubjects())
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: index == _currentPage
                        ? [
                            BoxShadow(
                              color: _getCurrentPageColor(_getCurrentSubjects()).withOpacity(0.3),
                              blurRadius: WebSize.radius(context, 4),
                              offset: Offset(0, WebSize.height(context, 2)),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          );
        }

        // Default dots when no subjects or single subject
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              5,
              (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: WebSize.width(context, 4)),
                    width: WebSize.width(context, 8),
                    height: WebSize.width(context, 8),
                    decoration: BoxDecoration(
                      color: index == 0 ? _getCurrentPageColor(_getCurrentSubjects()) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  )),
        );
      },
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: WebSize.width(context, 20),
      ),
      child: Column(
        children: [
          // Start Button
          _buildStartButton(context),
          SizedBox(height: WebSize.height(context, 18)),
          // Set My Study Time Link
          Visibility(
            visible: false,
            child: AnimationUtils.animatedButton(
              onPressed: () async {
                await VibrationService().lightVibration();
                if (widget.studyTimer.isActive) {
                  widget.studyTimer.stop();
                } else {
                  widget.studyTimer.start();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: WebSize.width(context, 16), vertical: WebSize.height(context, 8)),
                child: Text(
                  widget.studyTimer.isActive
                      ? 'Stop Study Time'
                      : 'Set My Study Time',
                  style: TextStyle(
                    fontSize: WebSize.fontSize(context, 18),
                    color: widget.studyTimer.isActive
                        ? Colors.red
                        : _getCurrentPageColor(_getCurrentSubjects()),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final buttonColor = _getCurrentPageColor(_getCurrentSubjects());
    
    return SizedBox(
      width: kIsWeb ? double.infinity : WebSize.width(context, 386),
      height: WebSize.height(context, 53),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isStartButtonPressed = true;
          });
        },
        onTapUp: (_) async {
          setState(() {
            _isStartButtonPressed = false;
          });
          await VibrationService().navigationVibration();
          // Navigate to subject tab and auto-select current subject
          if (widget.onNavigateToSubject != null) {
            widget.onNavigateToSubject!(_currentPage);
          }
        },
        onTapCancel: () {
          setState(() {
            _isStartButtonPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(WebSize.radius(context, 28.5)),
            border: Border(
              bottom: BorderSide(
                width: _isStartButtonPressed ? 1 : 4,
                color: buttonColor,
              ),
              right: BorderSide(
                width: _isStartButtonPressed ? 1 : 3,
                color: buttonColor,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(_isStartButtonPressed ? 0.15 : 0.3),
                spreadRadius: _isStartButtonPressed ? 0 : 1,
                blurRadius: WebSize.radius(context, _isStartButtonPressed ? 4 : 8),
                offset: Offset(0, WebSize.height(context, _isStartButtonPressed ? 1 : 4)),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Start',
              style: TextStyle(
                fontSize: WebSize.fontSize(context, 20),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
