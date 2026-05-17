import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/module_content_model.dart';
import '../../models/module_model.dart';
import '../../models/subject_model.dart';
import '../../models/module_chapter_model.dart';
import '../../blocs/module_content/module_content_bloc.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smooth_scroll_wrapper.dart';

class TheoryScreen extends StatefulWidget {
  final Subject subject;
  final Module module;
  final ModuleChapter chapter;
  final ModuleContentItem content;

  const TheoryScreen({
    super.key,
    required this.subject,
    required this.module,
    required this.chapter,
    required this.content,
  });

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  bool _isCompleteButtonPressed = false;
  bool _isNextButtonPressed = false;
  bool _isMarkedComplete = false;

  // Helper function to convert hex string to Color
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
    
    // Clear any cached next content to ensure fresh data
    context.read<ModuleContentBloc>().clearNextContentCache();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
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
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  double get _progress {
    final totalItems = widget.chapter.questionCount;
    if (totalItems <= 0) return 0.0;
    return (widget.content.order / totalItems).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _hexToColor(widget.subject.color);
    
    return Scaffold(
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
                  colors: _getGradientColors(subjectColor),
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
                  colors: _getBottomGradientColors(subjectColor),
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
                        top: (kIsWeb ? 80.0 : 100.h) + _circle1Animation.value,
                        left: (kIsWeb ? -40.0 : -50.w) + _circle1Animation.value * 0.5,
                        child: Container(
                          width: kIsWeb ? 150 : 200.w,
                          height: kIsWeb ? 150 : 200.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: subjectColor.withOpacity(0.15),
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
                        right: (kIsWeb ? -20.0 : -30.w) - _circle2Animation.value * 0.5,
                        child: Container(
                          width: kIsWeb ? 120 : 150.w,
                          height: kIsWeb ? 120 : 150.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: subjectColor.withOpacity(0.2),
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
                        bottom: (kIsWeb ? 180.0 : 240.h) - _circle3Animation.value,
                        right: kIsWeb ? 20 : 20.w,
                        child: Container(
                          width: kIsWeb ? 40 : 50.w,
                          height: kIsWeb ? 40 : 50.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: subjectColor.withOpacity(0.25),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopNavigationBar(),
                
                // Main Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: kIsWeb ? 500 : double.infinity),
                          child: SmoothScrollOverlay(
                            showTopFade: true,
                            showBottomFade: true,
                            fadeHeight: kIsWeb ? 40 : 40.h,
                            fadeColor: Colors.white,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Module Info Header
                                  _buildModuleHeader(),
                                  
                                  SizedBox(height: kIsWeb ? 24 : 28.h),
                                  
                                  // Theory Content Card
                                  _buildTheoryContentCard(),
                                  
                                  SizedBox(height: kIsWeb ? 24 : 28.h),
                                  
                                  // Progress Indicator
                                  _buildProgressIndicator(),
                                  
                                  SizedBox(height: kIsWeb ? 32 : 40.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Action Buttons
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    final subjectColor = _hexToColor(widget.subject.color);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 20.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () async {
              // await SoundService().playButtonClick();
              await VibrationService().navigationVibration();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(kIsWeb ? 10 : 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: kIsWeb ? 20 : 22.sp,
              ),
            ),
          ),
          
          SizedBox(width: kIsWeb ? 16 : 16.w),
          
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theory',
                  style: TextStyle(
                    fontSize: kIsWeb ? 20 : 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: kIsWeb ? 2 : 2.h),
                Text(
                  widget.chapter.name,
                  style: TextStyle(
                    fontSize: kIsWeb ? 13 : 14.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Theory Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 12 : 14.w,
              vertical: kIsWeb ? 6 : 8.h,
            ),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kIsWeb ? 16 : 20.r),
              border: Border.all(
                color: subjectColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: subjectColor,
                  size: kIsWeb ? 16 : 18.sp,
                ),
                SizedBox(width: kIsWeb ? 4 : 6.w),
                Text(
                  '${widget.content.order}/${widget.chapter.questionCount}',
                  style: TextStyle(
                    fontSize: kIsWeb ? 12 : 13.sp,
                    fontWeight: FontWeight.w600,
                    color: subjectColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleHeader() {
    final subjectColor = _hexToColor(widget.subject.color);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(kIsWeb ? 20 : 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 24.r),
        border: Border(
          top: BorderSide(color: subjectColor.withOpacity(0.3), width: 1),
          left: BorderSide(color: subjectColor.withOpacity(0.3), width: 1),
          right: BorderSide(color: subjectColor.withOpacity(0.3), width: 1),
          bottom: BorderSide(color: subjectColor, width: kIsWeb ? 2 : 3),
        ),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Subject Icon
          Container(
            width: kIsWeb ? 56 : 64.w,
            height: kIsWeb ? 56 : 64.w,
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kIsWeb ? 14 : 16.r),
            ),
            child: Icon(
              Icons.school_rounded,
              color: subjectColor,
              size: kIsWeb ? 28 : 32.sp,
            ),
          ),
          
          SizedBox(width: kIsWeb ? 16 : 18.w),
          
          // Module Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.name,
                  style: TextStyle(
                    fontSize: kIsWeb ? 12 : 13.sp,
                    color: subjectColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: kIsWeb ? 4 : 4.h),
                Text(
                  widget.module.name,
                  style: TextStyle(
                    fontSize: kIsWeb ? 18 : 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheoryContentCard() {
    final subjectColor = _hexToColor(widget.subject.color);
    
    // Debug logging
    print('🔍 Theory Screen Debug:');
    print('  Content ID: ${widget.content.id}');
    print('  Content Type: ${widget.content.contentType}');
    print('  Theory: ${widget.content.theory}');
    print('  Theory Title: ${widget.content.theory?.title}');
    print('  Theory Description: ${widget.content.theory?.description}');
    
    if (widget.content.theory == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(kIsWeb ? 32 : 40.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kIsWeb ? 20 : 24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 1,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: kIsWeb ? 48 : 56.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: kIsWeb ? 16 : 20.h),
            Text(
              'No theory content available',
              style: TextStyle(
                fontSize: kIsWeb ? 16 : 18.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theory Title Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(kIsWeb ? 20 : 24.w),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kIsWeb ? 20 : 24.r),
                topRight: Radius.circular(kIsWeb ? 20 : 24.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(kIsWeb ? 10 : 12.w),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: subjectColor,
                    size: kIsWeb ? 20 : 24.sp,
                  ),
                ),
                SizedBox(width: kIsWeb ? 14 : 16.w),
                Expanded(
                  child: Text(
                    widget.content.theory!.title,
                    style: TextStyle(
                      fontSize: kIsWeb ? 18 : 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          // Theory Description
          Padding(
            padding: EdgeInsets.all(kIsWeb ? 20 : 24.w),
            child: Text(
              widget.content.theory!.description,
              style: TextStyle(
                fontSize: kIsWeb ? 15 : 16.sp,
                color: Colors.grey[700],
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final subjectColor = _hexToColor(widget.subject.color);
    final progressPercent = (_progress * 100).round();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(kIsWeb ? 20 : 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chapter Progress',
                style: TextStyle(
                  fontSize: kIsWeb ? 14 : 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: kIsWeb ? 10 : 12.w,
                  vertical: kIsWeb ? 4 : 5.h,
                ),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
                ),
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontSize: kIsWeb ? 12 : 13.sp,
                    fontWeight: FontWeight.bold,
                    color: subjectColor,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: kIsWeb ? 14 : 16.h),
          
          // Progress Bar
          Stack(
            children: [
              Container(
                height: kIsWeb ? 8 : 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(kIsWeb ? 4 : 5.r),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: kIsWeb ? 8 : 10.h,
                width: (MediaQuery.of(context).size.width - (kIsWeb ? 80 : 88.w)) * _progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      subjectColor,
                      Color.lerp(subjectColor, Colors.white, 0.3) ?? subjectColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(kIsWeb ? 4 : 5.r),
                  boxShadow: [
                    BoxShadow(
                      color: subjectColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: kIsWeb ? 10 : 12.h),
          
          Text(
            'Item ${widget.content.order} of ${widget.chapter.questionCount}',
            style: TextStyle(
              fontSize: kIsWeb ? 12 : 13.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final primaryColor = _hexToColor("365DEA");
    final secondaryColor = _hexToColor("2A4BC0");
    final successColor = _hexToColor("31C85D");
    final successSecondaryColor = _hexToColor("28A54D");
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 20.w,
        vertical: kIsWeb ? 16 : 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 500 : double.infinity),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mark as Complete Button
              if (!_isMarkedComplete)
                GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _isCompleteButtonPressed = true;
                    });
                  },
                  onTapUp: (_) async {
                    setState(() {
                      _isCompleteButtonPressed = false;
                      _isMarkedComplete = true;
                    });
                    // await SoundService().playCorrectAnswer();
                    await VibrationService().successVibration();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Theory marked as complete!'),
                          ],
                        ),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: kIsWeb ? 20 : 100.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onTapCancel: () {
                    setState(() {
                      _isCompleteButtonPressed = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    height: kIsWeb ? 52 : 56.h,
                    decoration: BoxDecoration(
                      color: successColor,
                      borderRadius: BorderRadius.circular(kIsWeb ? 26 : 28.r),
                      border: Border(
                        bottom: BorderSide(
                          width: _isCompleteButtonPressed ? 1 : 4,
                          color: successSecondaryColor,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: successColor.withOpacity(_isCompleteButtonPressed ? 0.2 : 0.4),
                          blurRadius: _isCompleteButtonPressed ? 4 : 8,
                          offset: Offset(0, _isCompleteButtonPressed ? 1 : 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: kIsWeb ? 20 : 22.sp,
                          ),
                          SizedBox(width: kIsWeb ? 8 : 10.w),
                          Text(
                            'Mark as Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: kIsWeb ? 16 : 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Completed Badge (shown after marking complete)
              if (_isMarkedComplete)
                Container(
                  width: double.infinity,
                  height: kIsWeb ? 52 : 56.h,
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kIsWeb ? 26 : 28.r),
                    border: Border.all(
                      color: successColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: successColor,
                          size: kIsWeb ? 20 : 22.sp,
                        ),
                        SizedBox(width: kIsWeb ? 8 : 10.w),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: successColor,
                            fontSize: kIsWeb ? 16 : 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              SizedBox(height: kIsWeb ? 12 : 14.h),
              
              // Next Content Button
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isNextButtonPressed = true;
                  });
                },
                onTapUp: (_) async {
                  setState(() {
                    _isNextButtonPressed = false;
                  });
                  // await SoundService().playButtonClick();
                  await VibrationService().navigationVibration();
                  
                  // Trigger get_next API call before navigation (force fresh data)
                  context.read<ModuleContentBloc>().add(
                    RefreshNextContent(
                      widget.chapter.id,
                      widget.content.id,
                    ),
                  );
                },
                onTapCancel: () {
                  setState(() {
                    _isNextButtonPressed = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  height: kIsWeb ? 52 : 56.h,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(kIsWeb ? 26 : 28.r),
                    border: Border(
                      bottom: BorderSide(
                        width: _isNextButtonPressed ? 1 : 4,
                        color: secondaryColor,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(_isNextButtonPressed ? 0.2 : 0.4),
                        blurRadius: _isNextButtonPressed ? 4 : 8,
                        offset: Offset(0, _isNextButtonPressed ? 1 : 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: kIsWeb ? 16 : 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 8 : 10.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: kIsWeb ? 20 : 22.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
