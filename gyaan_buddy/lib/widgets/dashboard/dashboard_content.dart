import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/subject/subject_bloc.dart';
import '../../blocs/module_chapter/module_chapter_bloc.dart';
import '../../models/user_model.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';
import '../../widgets/web_safe_area.dart';
import '../../utils/web_size_utils.dart';
import '../../services/sound_service.dart';
import '../smooth_scroll_wrapper.dart';
import 'ranked_item.dart';

class DashboardContent extends StatefulWidget {
  final bool fromQuizScreen;
  final String? moduleId;

  const DashboardContent({
    super.key,
    this.fromQuizScreen = false,
    this.moduleId,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent>
    with TickerProviderStateMixin {
  String? _selectedFilter;
  String? _className;
  String? _gradeName;

  // Flag to track if animations are initialized
  bool _animationsInitialized = false;

  // Circle animation controllers
  AnimationController? _circle1Controller;
  AnimationController? _circle2Controller;
  AnimationController? _circle3Controller;
  Animation<double>? _circle1Animation;
  Animation<double>? _circle2Animation;
  Animation<double>? _circle3Animation;

  // User avatar animation controllers
  AnimationController? _firstUserScaleController;
  AnimationController? _firstUserFloatController;
  AnimationController? _secondUserScaleController;
  AnimationController? _secondUserFloatController;
  AnimationController? _thirdUserScaleController;
  AnimationController? _thirdUserFloatController;
  Animation<double>? _firstUserScaleAnimation;
  Animation<double>? _firstUserFloatAnimation;
  Animation<double>? _secondUserScaleAnimation;
  Animation<double>? _secondUserFloatAnimation;
  Animation<double>? _thirdUserScaleAnimation;
  Animation<double>? _thirdUserFloatAnimation;

  // Dotted circle animation controller
  AnimationController? _dottedCircleController;
  Animation<double>? _dottedCircleRotationAnimation;

  // Scroll controller for resetting scroll position
  late ScrollController _scrollController;

  // Current user rank animation (for quiz screen transition)
  AnimationController? _userRankAnimationController;
  Animation<Offset>? _userRankSlideAnimation;
  Animation<double>? _userRankScaleAnimation;
  bool _hasAnimatedUserRank = false;

  // Continue button press state
  bool _isContinueButtonPressed = false;

  String? firstUserName;
  String? secondUserName;
  String? thirdUserName;
  bool _didPrecacheAssets = false;

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
    // Create a light shade of the base color
    final lightBaseColor = Color.lerp(Colors.white, baseColor, 0.15) ??
        baseColor.withOpacity(0.15);

    return [
      Colors.white,
      Color.lerp(lightBaseColor, baseColor, 0.05) ?? lightBaseColor,
      Color.lerp(lightBaseColor, baseColor, 0.1) ?? lightBaseColor,
      lightBaseColor,
      Color.lerp(lightBaseColor, baseColor, 0.1) ?? lightBaseColor,
      Color.lerp(lightBaseColor, baseColor, 0.15) ?? lightBaseColor,
      Color.lerp(lightBaseColor, baseColor, 0.1) ?? lightBaseColor,
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
    // Initialize scroll controller immediately (lightweight)
    _scrollController = ScrollController();

    // Initialize default selected filter
    _selectedFilter = 'IX-A'; // Default fallback value

    // Play leaderboard loading sound
    // SoundService().playLeaderboardLoading();

    // Load leaderboard data when dashboard is opened
    context.read<UserBloc>().add(const LoadLeaderboard(limit: 10, grade: null));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAnimations();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheAssets) return;
    _didPrecacheAssets = true;
    precacheImage(const AssetImage('assets/images/prize.png'), context);
  }

  /// Initialize all animation controllers (deferred to avoid blocking UI)
  void _initializeAnimations() {
    if (_animationsInitialized) return;

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
      begin: -20.wWeb,
      end: 20.wWeb,
    ).animate(CurvedAnimation(
      parent: _circle1Controller!,
      curve: Curves.easeInOut,
    ));

    _circle2Animation = Tween<double>(
      begin: -15.wWeb,
      end: 15.wWeb,
    ).animate(CurvedAnimation(
      parent: _circle2Controller!,
      curve: Curves.easeInOut,
    ));

    _circle3Animation = Tween<double>(
      begin: -8.wWeb,
      end: 8.wWeb,
    ).animate(CurvedAnimation(
      parent: _circle3Controller!,
      curve: Curves.easeInOut,
    ));

    // Initialize user avatar animation controllers
    // Scale controllers (one-time animation)
    _firstUserScaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _secondUserScaleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _thirdUserScaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Float controllers (continuous animation)
    _firstUserFloatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _secondUserFloatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _thirdUserFloatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _firstUserScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _firstUserScaleController!,
      curve: Curves.elasticOut,
    ));

    _firstUserFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _firstUserFloatController!,
      curve: Curves.easeInOut,
    ));

    _secondUserScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondUserScaleController!,
      curve: Curves.elasticOut,
    ));

    _secondUserFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondUserFloatController!,
      curve: Curves.easeInOut,
    ));

    _thirdUserScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _thirdUserScaleController!,
      curve: Curves.elasticOut,
    ));

    _thirdUserFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _thirdUserFloatController!,
      curve: Curves.easeInOut,
    ));

    // Initialize dotted circle animation controller
    _dottedCircleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _dottedCircleRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _dottedCircleController!,
      curve: Curves.linear,
    ));

    // Initialize user rank animation if coming from quiz screen
    if (widget.fromQuizScreen) {
      _userRankAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      _userRankSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 2), // Start from mid-list area
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _userRankAnimationController!,
        curve: Curves.easeOutCubic,
      ));

      _userRankScaleAnimation = Tween<double>(
        begin: 0.6,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _userRankAnimationController!,
        curve: Curves.easeOutBack,
      ));
    }

    _animationsInitialized = true;
    if (mounted) {
      setState(() {}); // Trigger rebuild with animations ready
    }
  }

  @override
  void dispose() {
    _circle1Controller?.dispose();
    _circle2Controller?.dispose();
    _circle3Controller?.dispose();
    _firstUserScaleController?.dispose();
    _firstUserFloatController?.dispose();
    _secondUserScaleController?.dispose();
    _secondUserFloatController?.dispose();
    _thirdUserScaleController?.dispose();
    _thirdUserFloatController?.dispose();
    _dottedCircleController?.dispose();
    _scrollController.dispose();
    _userRankAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _hexToColor("C5E1FF");
    final topGradientColors = _getGradientColors(baseColor);
    final bottomGradientColors = _getBottomGradientColors(baseColor);

    return Scaffold(
      body: Stack(
        children: [
          // White base background
          // Positioned.fill(
          //   child: Container(
          //     color:_hexToColor("C5E1FF"),
          //   ),
          // ),
          // Top gradient (1/4 of screen)
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     height: 200.hWeb,
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
          //     height: 250.hWeb,
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
          // Circular shapes overlay (only show when animations are initialized)
          if (_animationsInitialized && _circle1Animation != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      _AnimatedTranslatedCircle(
                        animation: _circle1Animation!,
                        top: -100.hWeb,
                        right: -100.wWeb,
                        width: 300.wWeb,
                        height: 300.wWeb,
                        color: baseColor.withOpacity(0.15),
                      ),
                      _AnimatedTranslatedCircle(
                        animation: _circle2Animation!,
                        top: 200.hWeb,
                        left: 40.wWeb,
                        width: 120.wWeb,
                        height: 120.wWeb,
                        color: baseColor.withOpacity(0.25),
                      ),
                      _AnimatedTranslatedCircle(
                        animation: _circle3Animation!,
                        bottom: 200.hWeb,
                        right: 20.wWeb,
                        width: 50.wWeb,
                        height: 50.wWeb,
                        color: baseColor.withOpacity(0.25),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_animationsInitialized && _dottedCircleRotationAnimation != null)
            Positioned(
              top: 60.hWeb,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _dottedCircleRotationAnimation!,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(500.wWeb, 400.hWeb),
                      painter: _DottedCirclePainter(),
                    ),
                  ),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _dottedCircleRotationAnimation!.value,
                      child: child,
                    );
                  },
                ),
              ),
            ),
          // Content - User avatars positioned relative to screen center
          if (firstUserName != null &&
              _animationsInitialized &&
              _firstUserScaleAnimation != null)
            _FloatingPodiumUser(
              scaleAnimation: _firstUserScaleAnimation!,
              floatAnimation: _firstUserFloatAnimation!,
              top: kIsWeb ? 130.0 : 185.h,
              left: kIsWeb ? .5.swWeb - 40.wWeb : 190.w,
              floatDistance: kIsWeb ? 5 : 5.h,
              child: Column(
                children: [
                  Container(
                    width: 54.wWeb,
                    height: 54.wWeb,
                    decoration: BoxDecoration(
                      color: getRankColor(1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        firstUserName?.characters.first ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 24.spWeb,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    firstUserName ?? "",
                    style: TextStyle(
                        fontSize: 13.spWeb, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          if (secondUserName != null &&
              _animationsInitialized &&
              _secondUserScaleAnimation != null)
            _FloatingPodiumUser(
              scaleAnimation: _secondUserScaleAnimation!,
              floatAnimation: _secondUserFloatAnimation!,
              top: kIsWeb ? 180.0 : 240.h,
              left: kIsWeb ? .5.swWeb - 180.wWeb : 110.w,
              floatDistance: kIsWeb ? 5 : 5.h,
              child: Column(
                children: [
                  Container(
                    width: 54.wWeb,
                    height: 54.wWeb,
                    decoration: BoxDecoration(
                      color: getRankColor(2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        secondUserName?.characters.first ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 24.spWeb,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    secondUserName ?? "",
                    style: TextStyle(
                        fontSize: 13.spWeb, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          if (thirdUserName != null &&
              _animationsInitialized &&
              _thirdUserScaleAnimation != null)
            _FloatingPodiumUser(
              scaleAnimation: _thirdUserScaleAnimation!,
              floatAnimation: _thirdUserFloatAnimation!,
              top: kIsWeb ? 205.0 : 245.h,
              left: kIsWeb ? .5.swWeb + 70.wWeb : null,
              right: kIsWeb ? null : 110.w,
              floatDistance: kIsWeb ? 5 : 5.h,
              child: Column(
                children: [
                  Container(
                    width: 54.wWeb,
                    height: 54.wWeb,
                    decoration: BoxDecoration(
                      color: getRankColor(3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        thirdUserName?.characters.first ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 24.spWeb,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    thirdUserName ?? "",
                    style: TextStyle(
                        fontSize: 13.spWeb, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Prize Image - fixed position, doesn't scroll
          Positioned(
            top: kIsWeb ? 200.hWeb : 250.h,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Center(
                  child: _buildPrizeImage(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  _buildLeaderboardHeader(),

                  // Navigation/Filter Bar (hidden when coming from quiz screen)
                  if (!widget.fromQuizScreen) _buildFilterBar(),
                  // SizedBox(height: 140.h),

                  Expanded(
                    child: SmoothScrollOverlay(
                      showTopFade: false,
                      showBottomFade: true,
                      fadeHeight: kIsWeb ? 60 : 60.hWeb,
                      fadeColor: Colors.white,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: kIsWeb
                                  ? 230.hWeb
                                  : 220.h +
                                      (widget.fromQuizScreen ? 80.h : 30.h),
                            ),
                            _buildLeaderboardContent(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Continue button when coming from quiz screen
                  if (widget.fromQuizScreen) _buildContinueButton(),
                  SizedBox(
                    height: 20.h,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return Container(
      padding: kIsWeb ? EdgeInsets.zero : EdgeInsets.all(16.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Arrow - positioned on the left
          Visibility(
            visible: widget.fromQuizScreen,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  // Handle back navigation
                  if (widget.fromQuizScreen) {
                    // Refresh module chapters so subject screen shows updated data
                    if (widget.moduleId != null) {
                      context
                          .read<ModuleChapterBloc>()
                          .add(RefreshModuleChapters(widget.moduleId!));
                    }
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 22.wWeb,
                ),
              ),
            ),
          ),
          // Title - centered
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: kIsWeb ? 10.hWeb : 10.h,
            ),
            child: Text(
              'Leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 29.spWeb,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    // Build filter list from API values: first is class_name, second is grade_name
    final filters = <String>[];
    if (_className != null && _className!.isNotEmpty) {
      filters.add(_className!);
    }
    if (_gradeName != null && _gradeName!.isNotEmpty) {
      filters.add(_gradeName!);
    }

    // Fallback to default values if API values are not available
    if (filters.isEmpty) {
      filters.addAll(['IX-A', 'IX']);
    }

    // Ensure selected filter is valid (in case API values changed)
    if (_selectedFilter == null || !filters.contains(_selectedFilter)) {
      if (filters.isNotEmpty) {
        _selectedFilter = filters[0];
      }
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.wWeb, vertical: 10.hWeb),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.rWeb),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 53.hWeb,
              constraints: BoxConstraints(
                maxWidth: kIsWeb ? 350 : 0.9.sw,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hexToColor("6A8AFF").withOpacity(0.85),
                    _hexToColor("5A7AEF").withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(22.rWeb),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hexToColor("3960EA").withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Expanded(
                    flex: isSelected ? 6 : 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });

                        // Scroll back to initial position immediately
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0.0);
                        }

                        // Reload leaderboard with new filter
                        // If grade filter is selected, pass grade parameter
                        final gradeParam =
                            (filter == _gradeName && _gradeName != null)
                                ? _gradeName
                                : null;
                        context
                            .read<UserBloc>()
                            .add(LoadLeaderboard(limit: 10, grade: gradeParam));

                        // Ensure scroll position is reset after content rebuilds
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && _scrollController.hasClients) {
                              _scrollController.jumpTo(0.0);
                            }
                          });
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.all(4.wWeb),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _hexToColor("3960EA").withOpacity(0.9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18.rWeb),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: isSelected ? 17.spWeb : 16.spWeb,
                            ),
                            child: Text(
                              filter,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeImage() {
    return SizedBox(
      height: 276.hWeb,
      width: 400.wWeb,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Prize image
              Image.asset(
                'assets/images/prize.png',
                width: 400.wWeb,
                height: 276.hWeb,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150.wWeb,
                    height: 150.hWeb,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.rWeb),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 50.spWeb,
                      color: Colors.amber,
                    ),
                  );
                },
              ),
              Positioned(
                top: 40.hWeb,
                right: 180.wWeb,
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 58.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 100.hWeb,
                right: 310.wWeb,
                child: Text(
                  '2',
                  style: TextStyle(
                    fontSize: 58.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 110.hWeb,
                right: 55.wWeb,
                child: Text(
                  '3',
                  style: TextStyle(
                    fontSize: 58.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return Center(
      child: Container(
        margin: EdgeInsets.only(
          top: 30.hWeb,
        ),
        padding: EdgeInsets.only(
            top: 16.hWeb,
            bottom: 150.hWeb + (widget.fromQuizScreen ? 50.hWeb : 0)),
        constraints: BoxConstraints(
          maxWidth: kIsWeb ? 660 : double.infinity,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.5),
            ),
            left: BorderSide(
              color: Colors.grey.withOpacity(0.5),
            ),
            right: BorderSide(
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24.rWeb),
            topLeft: Radius.circular(24.rWeb),
          ),
        ),
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is LeaderboardLoading) {
              return Container(
                height: 300.hWeb,
                width: double.infinity,
                padding: EdgeInsets.all(30.wWeb),
                child: const Center(child: CircularProgressIndicator()),
              );
            } else if (state is LeaderboardLoaded) {
              // Extract className and gradeName from state
              if (state.className != null || state.gradeName != null) {
                // Only update if values actually changed to prevent infinite rebuilds
                final classNameChanged = _className != state.className;
                final gradeNameChanged = _gradeName != state.gradeName;

                if (classNameChanged || gradeNameChanged) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _className = state.className;
                        _gradeName = state.gradeName;

                        // Only set default filter if:
                        // 1. No filter is currently selected, OR
                        // 2. The previously selected filter is no longer valid (API values changed)
                        if (_selectedFilter == null) {
                          // First time: set to class_name (first value)
                          _selectedFilter = state.className ?? state.gradeName;
                        } else {
                          // Check if current selection is still valid
                          final validFilters = <String>[];
                          if (_className != null && _className!.isNotEmpty)
                            validFilters.add(_className!);
                          if (_gradeName != null && _gradeName!.isNotEmpty)
                            validFilters.add(_gradeName!);

                          // If current selection is not in valid filters, reset to first filter
                          if (!validFilters.contains(_selectedFilter)) {
                            _selectedFilter = validFilters.isNotEmpty
                                ? validFilters[0]
                                : null;
                          }
                          // Otherwise, preserve the user's selection
                        }
                      });

                      // Only reset scroll position if filter values actually changed
                      if ((classNameChanged || gradeNameChanged) &&
                          _scrollController.hasClients) {
                        Future.delayed(const Duration(milliseconds: 150), () {
                          if (mounted && _scrollController.hasClients) {
                            _scrollController.jumpTo(0.0);
                          }
                        });
                      }
                    }
                  });
                } else {
                  // Update values without setState if they haven't changed (to keep them in sync)
                  _className = state.className;
                  _gradeName = state.gradeName;
                }
              }
              return _buildLeaderboardData(state.users);
            } else if (state is LeaderboardError) {
              return _buildErrorState(state.message);
            } else {
              return Container(
                padding: EdgeInsets.all(30.wWeb),
                child: const Center(
                  child: Text('No leaderboard data available'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardData(List<User> users) {
    if (users.isEmpty) {
      return Container(
        padding: EdgeInsets.all(30.wWeb),
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(fontSize: 14.spWeb, color: Colors.grey),
          ),
        ),
      );
    }

    // Take top 10 users for dashboard preview
    final topUsers = users.take(10).toList();

    return _buildRankedList(users);
  }

  Widget _buildPodiumTier(
      {required double height,
      required double width,
      required int rank,
      required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.rWeb),
          topRight: Radius.circular(10.rWeb),
        ),
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontSize: 40.spWeb,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumUser(User user, int rank) {
    Color avatarColor;
    switch (rank) {
      case 1:
        avatarColor = Colors.blue;
        break;
      case 2:
        avatarColor = Colors.brown;
        break;
      case 3:
        avatarColor = Colors.amber;
        break;
      default:
        avatarColor = Colors.grey;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User avatar
        CircleAvatar(
          radius: 26.wWeb,
          backgroundColor: avatarColor,
          backgroundImage:
              (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                  ? NetworkImage(user.profilePicture!)
                  : null,
          child: (user.profilePicture == null || user.profilePicture!.isEmpty)
              ? Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 18.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),

        SizedBox(height: 8.hWeb),

        // User name
        SizedBox(
          width: 90.wWeb,
          child: Text(
            user.fullName,
            style: TextStyle(
              fontSize: 13.spWeb,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(height: 4.hWeb),

        // XP Points
        Text(
          '${user.totalExp} XP Points',
          style: TextStyle(
            fontSize: 11.spWeb,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRankedList(List<User> users) {
    // Get current user ID for animation
    final currentUser = context.read<UserBloc>().currentUser;
    final currentUserId = currentUser?.id;

    // Check if current user is in the list
    final currentUserInList =
        currentUserId != null && users.any((u) => u.id == currentUserId);

    // Start animation if coming from quiz, not yet animated, and current user is in the list
    if (widget.fromQuizScreen &&
        !_hasAnimatedUserRank &&
        _userRankAnimationController != null &&
        currentUserInList) {
      _hasAnimatedUserRank = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _userRankAnimationController != null) {
          _userRankAnimationController!.forward();
        }
      });
    }

    // Set user names for animations
    if (users.length > 0) {
      final wasFirstNull = firstUserName == null;
      final wasSecondNull = secondUserName == null;
      final wasThirdNull = thirdUserName == null;

      final newFirstUserName = users[0].fullName;
      final newSecondUserName = users.length > 1 ? users[1].fullName : null;
      final newThirdUserName = users.length > 2 ? users[2].fullName : null;
      // Only update and trigger animations if names actually changed
      final firstChanged = firstUserName != newFirstUserName;
      final secondChanged = secondUserName != newSecondUserName;
      final thirdChanged = thirdUserName != newThirdUserName;

      if (firstChanged || secondChanged || thirdChanged) {
        firstUserName = newFirstUserName;
        if (users.length > 1) {
          secondUserName = newSecondUserName;
          if (users.length > 2) {
            thirdUserName = newThirdUserName;
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
          if (mounted && _animationsInitialized) {
            setState(() {
              // Trigger scale animations when user names are first set or changed
              if (wasFirstNull && firstUserName != null) {
                _firstUserScaleController?.forward();
              }
              if (wasSecondNull && secondUserName != null) {
                _secondUserScaleController?.forward();
              }
              if (wasThirdNull && thirdUserName != null) {
                _thirdUserScaleController?.forward();
              }
            });
          }
        });
      }
    }

    return Center(
      child: Container(
        width: 600.wWeb,
        padding: EdgeInsets.symmetric(horizontal: 20.wWeb),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(users.length, (index) {
            final user = users[index];
            final rank = index + 1;
            final isCurrentUser = user.id == currentUserId;

            Widget rankedItemWidget = RankedItem(
              user: user,
              rank: rank,
              isCurrentUser: isCurrentUser,
            );

            // Apply staggered slide animation for all items when coming from quiz screen
            if (widget.fromQuizScreen) {
              // Current user gets special animation: scale up → slide to position → scale down
              if (isCurrentUser) {
                rankedItemWidget = TweenAnimationBuilder<double>(
                  key: const ValueKey('current_user_anim'),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  builder: (context, progress, child) {
                    // Phase 1 (0.0 - 0.25): Scale up from 0.6 to 1.2
                    // Phase 2 (0.25 - 0.7): Slide to position (still scaled up)
                    // Phase 3 (0.7 - 1.0): Scale down from 1.2 to 1.0

                    double scale;
                    double slideY;
                    double opacity;

                    if (progress < 0.25) {
                      // Phase 1: Scale up, stay at mid-list position, fade in
                      final phaseProgress = (progress / 0.25).clamp(0.0, 1.0);
                      scale = 0.6 +
                          (0.6 *
                              Curves.easeOut
                                  .transform(phaseProgress)); // 0.6 → 1.2
                      slideY = 100; // Start from mid-list area
                      opacity = Curves.easeOut.transform(phaseProgress);
                    } else if (progress < 0.7) {
                      // Phase 2: Slide up to position, stay scaled up
                      final phaseProgress =
                          ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
                      scale = 1.2; // Stay scaled up
                      slideY = 100 *
                          (1 -
                              Curves.easeOutCubic
                                  .transform(phaseProgress)); // Slide up
                      opacity = 1.0;
                    } else {
                      // Phase 3: Scale down to normal
                      final phaseProgress =
                          ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
                      scale = 1.2 -
                          (0.2 *
                              Curves.easeInOut
                                  .transform(phaseProgress)); // 1.2 → 1.0
                      slideY = 0; // Already in position
                      opacity = 1.0;
                    }

                    return Transform.translate(
                      offset: Offset(0, slideY),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: rankedItemWidget,
                );
              } else {
                // Other users: scale down → slide to position → scale up
                final isEven = index % 2 == 0;
                final staggerDelay =
                    index * 0.06; // Stagger delay between items

                rankedItemWidget = TweenAnimationBuilder<double>(
                  key: ValueKey('ranked_item_$index'),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800 + (index * 60)),
                  curve: Curves.linear,
                  // We handle curves per phase
                  builder: (context, rawProgress, child) {
                    // Apply stagger delay
                    final progress =
                        ((rawProgress - staggerDelay) / (1 - staggerDelay))
                            .clamp(0.0, 1.0);

                    // Phase 1 (0.0 - 0.25): Scale down from 1.0 to 0.7, fade in
                    // Phase 2 (0.25 - 0.7): Slide to position (stay scaled down)
                    // Phase 3 (0.7 - 1.0): Scale up from 0.7 to 1.0

                    double scale;
                    double slideX;
                    double opacity;

                    // Starting position (off screen left or right)
                    final startX = isEven ? -120.0 : 120.0;

                    if (progress < 0.25) {
                      // Phase 1: Scale down, fade in, stay at starting position
                      final phaseProgress = (progress / 0.25).clamp(0.0, 1.0);
                      scale = 1.0 -
                          (0.3 *
                              Curves.easeOut
                                  .transform(phaseProgress)); // 1.0 → 0.7
                      slideX = startX; // Stay at start
                      opacity = Curves.easeOut.transform(phaseProgress);
                    } else if (progress < 0.7) {
                      // Phase 2: Slide to position, stay scaled down
                      final phaseProgress =
                          ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
                      scale = 0.7; // Stay scaled down
                      slideX = startX *
                          (1 -
                              Curves.easeOutCubic
                                  .transform(phaseProgress)); // Slide to center
                      opacity = 1.0;
                    } else {
                      // Phase 3: Scale up to normal
                      final phaseProgress =
                          ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
                      scale = 0.7 +
                          (0.3 *
                              Curves.easeOutBack
                                  .transform(phaseProgress)); // 0.7 → 1.0
                      slideX = 0; // Already in position
                      opacity = 1.0;
                    }

                    return Transform.translate(
                      offset: Offset(slideX, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: rankedItemWidget,
                );
              }
            }

            if (index == users.length - 1) {
              return Column(
                children: [
                  rankedItemWidget,
                ],
              );
            }
            return rankedItemWidget;
          }),
        ),
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
            size: 40.wWeb,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.hWeb),
          Text(
            'Error loading leaderboard',
            style: TextStyle(
              fontSize: 14.spWeb,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.hWeb),
          Text(
            message,
            style: TextStyle(
              fontSize: 13.spWeb,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.hWeb),
          ElevatedButton(
            onPressed: () {
              // Retry with current filter selection
              final gradeParam =
                  (_selectedFilter == _gradeName && _gradeName != null)
                      ? _gradeName
                      : null;
              context
                  .read<UserBloc>()
                  .add(LoadLeaderboard(limit: 10, grade: gradeParam));
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final baseColor = const Color(0xFF4A90E2); // Blue color matching the theme

    return Container(
      margin: EdgeInsets.only(
        bottom: 30.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 20.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.75,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                _isContinueButtonPressed = true;
              });
            },
            onTapUp: (_) {
              setState(() {
                _isContinueButtonPressed = false;
              });
              // Refresh subject modules so subject screen shows updated data
              context.read<SubjectBloc>().add(const LoadSubjects());
              // Navigate back to module chapter screen
              Navigator.of(context).pop();
            },
            onTapCancel: () {
              setState(() {
                _isContinueButtonPressed = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              height: kIsWeb ? 56 : 56.h,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(kIsWeb ? 28 : 28.r),
                border: Border(
                  bottom: BorderSide(
                    color: Color.lerp(baseColor, Colors.black, 0.3)!,
                    width: _isContinueButtonPressed ? 1 : 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseColor
                        .withOpacity(_isContinueButtonPressed ? 0.2 : 0.3),
                    blurRadius: _isContinueButtonPressed ? 6 : 12,
                    offset: Offset(0, _isContinueButtonPressed ? 2 : 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: kIsWeb ? 18 : 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTranslatedCircle extends StatelessWidget {
  final Animation<double> animation;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double width;
  final double height;
  final Color color;

  const _AnimatedTranslatedCircle({
    required this.animation,
    required this.width,
    required this.height,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        child: RepaintBoundary(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animation.value),
            child: child,
          );
        },
      ),
    );
  }
}

class _FloatingPodiumUser extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> floatAnimation;
  final double top;
  final double? left;
  final double? right;
  final double floatDistance;
  final Widget child;

  const _FloatingPodiumUser({
    required this.scaleAnimation,
    required this.floatAnimation,
    required this.top,
    required this.floatDistance,
    required this.child,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([scaleAnimation, floatAnimation]),
            child: child,
            builder: (context, child) {
              final floatOffset =
                  sin(floatAnimation.value * 2 * pi) * floatDistance;
              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.scale(
                  scale: scaleAnimation.value.clamp(0.0, 1.2),
                  child: Opacity(
                    opacity: scaleAnimation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Convert C5E1FF to Color
    final circleColor = Color(0xFFC5E1FF);

    final paint = Paint()
      ..color = circleColor.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw 3 concentric dotted circles
    final radii = [
      size.width / 2 - 20, // Outer circle
      size.width / 2 - 50, // Middle circle
      size.width / 2 - 80, // Inner circle
    ];

    for (final radius in radii) {
      // Draw dotted circle
      final dashWidth = 5;
      final dashSpace = 5;
      final circumference = 2 * pi * radius;
      final dashCount = (circumference / (dashWidth + dashSpace)).floor();

      for (int i = 0; i < dashCount; i++) {
        final startAngle = (2 * pi * i) / dashCount;
        final endAngle = startAngle + (dashWidth / radius);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          endAngle - startAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 15.0; // Radius for the rounded tip

    // Triangle pointing upward with rounded tip
    path.moveTo(0, size.height); // Bottom left
    path.lineTo(size.width / 2 - radius, radius); // Left side near top

    // Create rounded tip using quadratic bezier curve
    path.quadraticBezierTo(
      size.width / 2, 0, // Control point at the very top (creates rounded tip)
      size.width / 2 + radius, radius, // End point on right side near top
    );

    path.lineTo(size.width, size.height); // Bottom right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
