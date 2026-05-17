import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/study_timer.dart';
import '../../models/subject_model.dart';
import '../../models/module_model.dart';
import '../../models/user_model.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/subject/subject_bloc.dart';
import '../../blocs/user_test/user_test_bloc.dart';
import '../../screens/notifications/notification_screen.dart';
import '../../screens/test/test_subject_screen.dart';
import '../../services/vibration_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/notification_service.dart';
import '../smooth_scroll_wrapper.dart';
import '../tutorial_overlay.dart';
import '../dashboard/leaderboard_widget.dart';

class NewHomeContent extends StatefulWidget {
  final StudyTimer studyTimer;
  final Function(int)? onNavigateToSubject;
  final Function(Color)? onPageColorChanged;
  final VoidCallback? onProfileTap;

  const NewHomeContent({
    super.key,
    required this.studyTimer,
    this.onNavigateToSubject,
    this.onPageColorChanged,
    this.onProfileTap,
  });

  @override
  State<NewHomeContent> createState() => _NewHomeContentState();
}

class _NewHomeContentState extends State<NewHomeContent>
    with TickerProviderStateMixin {
  // Shimmer animation controller
  late AnimationController _shimmerController;

  // Card animation controllers
  late AnimationController _cardAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;

  // Track which subject card is being pressed (-1 means none)
  int _pressedCardIndex = -1;

  // Track selected subject for web detail card
  int _selectedSubjectIndex = 0;

  // Theme colors
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _lightBlue = Color(0xFF60A5FA);
  static const Color _yellowAccent = Color(0xFFFBBF24);

  // Tutorial state
  bool _showTutorial = false;
  bool _tutorialChecked = false;

  // Notification badge state
  int _unreadNotificationCount = 0;
  bool _didPrecacheAssets = false;

  // GlobalKeys for tutorial highlights
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _leaderboardCardKey = GlobalKey();
  final GlobalKey _subjectGridKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Initialize card animation
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _cardAnimationController.forward();

    // Load subjects and tests if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSubjectsLoaded();
      _ensureUserTestsLoaded();
      _notifyInitialColor();
      _loadUnreadNotificationCount();
    });

    // Check if tutorial should be shown
    _checkTutorialStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheAssets) return;
    _didPrecacheAssets = true;
    precacheImage(const AssetImage('assets/images/avatar.jpeg'), context);
    precacheImage(const AssetImage('assets/images/home_trophy.png'), context);
  }

  /// Load unread notification count
  Future<void> _loadUnreadNotificationCount() async {
    final count = await NotificationService().getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  /// Check if the home screen tutorial should be shown
  Future<void> _checkTutorialStatus() async {
    if (_tutorialChecked) return;
    _tutorialChecked = true;

    final hasSeenTutorial = await OnboardingService.isScreenTutorialComplete(
      ScreenTutorial.homeScreen,
    );

    if (!hasSeenTutorial && mounted) {
      // Wait for the screen to build and data to load
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    }
  }

  /// Complete and hide the tutorial
  void _completeTutorial() async {
    await OnboardingService.completeScreenTutorial(ScreenTutorial.homeScreen);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _ensureSubjectsLoaded() {
    final subjectBloc = context.read<SubjectBloc>();
    subjectBloc.add(const LoadSubjects());
  }

  void _ensureUserTestsLoaded() {
    final userTestBloc = context.read<UserTestBloc>();
    // Only trigger LoadUserTests if we don't have cached data yet
    if (!userTestBloc.hasTests) {
      userTestBloc.add(const LoadUserTests());
    }
  }

  void _notifyInitialColor() {
    if (widget.onPageColorChanged != null && mounted) {
      widget.onPageColorChanged!(_primaryBlue);
    }
  }

  Color _hexToColor(String? hexString, {Color fallback = _accentBlue}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      String hex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallback;
    }
  }

  Widget _optimizedNetworkImage({
    required String imageUrl,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    int? memCacheWidth,
    int? memCacheHeight,
    Widget Function(BuildContext, String, Object)? errorWidget,
    Widget Function(BuildContext, String)? placeholder,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth ?? (kIsWeb ? 260 : 180),
      memCacheHeight: memCacheHeight ?? (kIsWeb ? 260 : 180),
      maxWidthDiskCache: 360,
      maxHeightDiskCache: 360,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  double _calculateOverallProgress(User? user) {
    if (user == null || user.subjectProgress.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (final progress in user.subjectProgress) {
      totalProgress += progress.avgCompletion;
    }
    return (totalProgress / user.subjectProgress.length).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          SmoothScrollOverlay(
            showTopFade: false,
            showBottomFade: true,
            fadeHeight: kIsWeb ? 40 : 40.h,
            fadeColor: Colors.white,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section with padding
                  Container(
                    key: _headerKey,
                    padding:
                        EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 20.w),
                    child: _buildHeader(),
                  ),

                  SizedBox(height: kIsWeb ? 20 : 20.h),

                  if (kIsWeb)
                    // Web: Two-column layout - Left (image + leaderboard) | Right (subject grid)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left section - Trophy image & Leaderboard card + Leaderboard list
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                children: [
                                  Container(
                                    key: _leaderboardCardKey,
                                    child: _buildLeaderboardCard(),
                                  ),
                                  const SizedBox(height: 25),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Leaderboard',
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 36),
                                    child: LeaderboardWidget(compact: true),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 60),

                          // Right section - Subject detail card + icon row
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 40, 0),
                              child: Container(
                                key: _subjectGridKey,
                                child: _buildWebSubjectSection(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Mobile: Keep original single-column layout
                    Container(
                      key: _leaderboardCardKey,
                      child: _buildLeaderboardCard(),
                    ),

                    Container(
                      key: _subjectGridKey,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildSubjectGrid(),
                    ),
                  ],

                  // Space for floating navigation bar
                  SizedBox(height: kIsWeb ? 20 : 100.h),
                ],
              ),
            ),
          ),

          // Tutorial overlay
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                steps: _buildTutorialSteps(),
                onComplete: _completeTutorial,
                accentColor: _accentBlue,
                bottomPadding:
                    kIsWeb ? 0 : 100.h, // Account for bottom navigation bar
              ),
            ),
        ],
      ),
    );
  }

  /// Build tutorial steps for the home screen
  List<TutorialStep> _buildTutorialSteps() {
    return [
      TutorialStep(
        targetKey: _headerKey,
        title: 'Welcome Home!',
        description:
            'This is your dashboard showing your profile, XP points, and overall learning progress.',
        icon: Icons.home_rounded,
        tooltipPosition: TooltipPosition.bottom,
        shape: HighlightShape.roundedRect,
        highlightPadding: 8,
      ),
      TutorialStep(
        targetKey: _leaderboardCardKey,
        title: 'Leaderboard',
        description:
            'See who\'s leading the pack! Compete with other learners and climb to the top.',
        icon: Icons.emoji_events_rounded,
        tooltipPosition: TooltipPosition.bottom,
        shape: HighlightShape.roundedRect,
        highlightPadding: 4,
      ),
      TutorialStep(
        targetKey: _subjectGridKey,
        title: 'Your Subjects',
        description:
            'Tap on any subject to explore its chapters and start learning. Subjects with pending work appear first!',
        icon: Icons.grid_view_rounded,
        tooltipPosition: TooltipPosition.top,
        shape: HighlightShape.roundedRect,
        highlightPadding: 8,
      ),
    ];
  }

  Widget _buildHeader() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        String userName = 'Student';
        int totalXp = 0;
        double progress = 0.0;
        User? user;

        if (state is UserAuthenticated) {
          user = state.user;
          userName = user.firstName.isNotEmpty ? user.firstName : user.username;
          totalXp = user.totalExp;
          progress = _calculateOverallProgress(user);
        } else {
          // Try to get cached user
          final userBloc = context.read<UserBloc>();
          user = userBloc.currentUser;
          if (user != null) {
            userName =
                user.firstName.isNotEmpty ? user.firstName : user.username;
            totalXp = user.totalExp;
            progress = _calculateOverallProgress(user);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Avatar
            _buildProfileAvatar(userName),

            SizedBox(width: kIsWeb ? 5 : 12.w),

            // Hello + Progress next to avatar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $userName',
                    style: TextStyle(
                      fontSize: kIsWeb ? 24 : 24.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: kIsWeb ? 4 : 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: kIsWeb ? 18 : 18.sp,
                        color: _accentBlue,
                      ),
                      SizedBox(width: kIsWeb ? 4 : 4.w),
                      Text(
                        'Progress: ',
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // XP Badge, Notification Bell, Test Icon - all in one row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildXpBadge(totalXp),
                SizedBox(width: kIsWeb ? 12 : 12.w),
                _buildNotificationBell(),
                SizedBox(width: kIsWeb ? 12 : 12.w),
                _buildTestIcon(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileAvatar(String userName) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Tooltip(
        message: 'Profile',
        child: MouseRegion(
          cursor: widget.onProfileTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: kIsWeb ? 72 : 68.w,
              height: kIsWeb ? 72 : 68.w,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildDefaultAvatar(userName),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName) {
    final initial = userName.trim().isNotEmpty ? userName.trim()[0] : 'S';

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: kIsWeb ? 34 : 32.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildXpBadge(int totalXp) {
    return GestureDetector(
      onTap: () async {
        await VibrationService().lightVibration();
        // Navigate to rewards or XP screen
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 12 : 12.w,
          vertical: kIsWeb ? 8 : 8.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'XP',
              style: TextStyle(
                fontSize: kIsWeb ? 14 : 14.sp,
                fontWeight: FontWeight.bold,
                color: _accentBlue,
              ),
            ),
            SizedBox(width: kIsWeb ? 6 : 6.w),
            Text(
              '$totalXp',
              style: TextStyle(
                fontSize: kIsWeb ? 14 : 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: kIsWeb ? 4 : 4.w),
            // Container(
            //   padding: EdgeInsets.all(kIsWeb ? 2 : 2.w),
            //   decoration: BoxDecoration(
            //     color: _accentBlue,
            //     shape: BoxShape.circle,
            //   ),
            //   child: Icon(
            //     Icons.add,
            //     size: kIsWeb ? 12 : 12.sp,
            //     color: Colors.white,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestIcon() {
    return BlocBuilder<UserTestBloc, UserTestState>(
      builder: (context, state) {
        int pendingCount = 0;
        if (state is UserTestsLoaded) {
          pendingCount = state.pendingCount;
        } else {
          // Try to get from bloc cache
          final userTestBloc = context.read<UserTestBloc>();
          pendingCount = userTestBloc.pendingTestCount;
        }

        return GestureDetector(
          onTap: () async {
            await VibrationService().lightVibration();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TestSubjectScreen(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 12 : 12.w,
              vertical: kIsWeb ? 8 : 8.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kIsWeb ? 24 : 24.r),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: kIsWeb ? 22 : 22.sp,
                      color: _accentBlue,
                    ),
                    // Test count badge
                    if (pendingCount > 0)
                      Positioned(
                        right: kIsWeb ? -6 : -6.w,
                        top: kIsWeb ? -6 : -6.h,
                        child: Container(
                          padding: EdgeInsets.all(kIsWeb ? 2 : 2.w),
                          constraints: BoxConstraints(
                            minWidth: kIsWeb ? 16 : 16.w,
                            minHeight: kIsWeb ? 16 : 16.w,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              pendingCount > 9 ? '9+' : pendingCount.toString(),
                              style: TextStyle(
                                fontSize: kIsWeb ? 10 : 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: kIsWeb ? 8 : 8.w),
                Text(
                  'Tests',
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _accentBlue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: () async {
        await VibrationService().lightVibration();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          ),
        );
        // Refresh notification count when returning from notification screen
        _loadUnreadNotificationCount();
      },
      child: Container(
        width: kIsWeb ? 44 : 44.w,
        height: kIsWeb ? 44 : 44.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.notifications_outlined,
                size: kIsWeb ? 24 : 24.sp,
                color: _accentBlue,
              ),
            ),
            // Notification badge - only show if there are unread notifications
            if (_unreadNotificationCount > 0)
              Positioned(
                right: kIsWeb ? 0 : 0.w,
                top: kIsWeb ? 0 : 0.h,
                child: Container(
                  width: kIsWeb ? 12 : 12.w,
                  height: kIsWeb ? 12 : 12.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        // Get current user for display
        User? topUser;
        String topUserName = 'Student';
        int topUserXp = 0;

        // Try to get leaderboard data
        if (state is LeaderboardLoaded && state.users.isNotEmpty) {
          topUser = state.users.first;
          topUserName = topUser.firstName.isNotEmpty
              ? topUser.firstName
              : topUser.username;
          topUserXp = topUser.totalExp;
        } else {
          // Use current user as placeholder
          final userBloc = context.read<UserBloc>();
          topUser = userBloc.currentUser;
          if (topUser != null) {
            topUserName = topUser.firstName.isNotEmpty
                ? topUser.firstName
                : topUser.username;
            topUserXp = topUser.totalExp;
          }
        }

        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardScaleAnimation.value,
              child: Opacity(
                opacity: _cardFadeAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: kIsWeb ? 180 : null,
                  margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 0 : 15.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00167A),
                    borderRadius: BorderRadius.circular(kIsWeb ? 18 : 18.r),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/home_trophy.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 18 : 14.w,
                      vertical: kIsWeb ? 12 : 11.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/gyan_buddy_light.png',
                          width: kIsWeb ? 120 : 144.w,
                          fit: BoxFit.fitWidth,
                        ),
                        SizedBox(height: kIsWeb ? 10 : 9.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: kIsWeb ? 18 : 16.w,
                            vertical: kIsWeb ? 7 : 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: _lightBlue,
                            borderRadius:
                                BorderRadius.circular(kIsWeb ? 20 : 18.r),
                          ),
                          child: Text(
                            'The week King of Leaderboard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: kIsWeb ? 15 : 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: kIsWeb ? 10 : 14.h),
                        Row(
                          children: [
                            Container(
                              width: kIsWeb ? 40 : 42.w,
                              height: kIsWeb ? 40 : 42.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  topUserName.isNotEmpty
                                      ? topUserName[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 20 : 20.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: kIsWeb ? 14 : 12.w),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topUserName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: kIsWeb ? 22 : 18.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$topUserXp Xp',
                                    style: TextStyle(
                                      fontSize: kIsWeb ? 15 : 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.78),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectGrid() {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        if (state is SubjectLoading) {
          return _buildSubjectGridSkeleton();
        }

        if (state is SubjectError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
              child: Text(
                'Error loading subjects: ${state.message}',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: kIsWeb ? 14 : 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Get the original unsorted subjects list
        List<Subject> originalSubjects = [];
        if (state is SubjectsLoaded) {
          originalSubjects = state.subjects;
        } else {
          final subjectBloc = context.read<SubjectBloc>();
          originalSubjects = subjectBloc.cachedSubjects;
        }

        // Create a sorted copy for display: has_due_module = true comes first
        final sortedSubjects = List<Subject>.from(originalSubjects)
          ..sort((a, b) {
            if (a.hasDueModule && !b.hasDueModule) return -1;
            if (!a.hasDueModule && b.hasDueModule) return 1;
            return 0;
          });

        if (sortedSubjects.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
              child: Text(
                'No subjects available',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: kIsWeb ? 16 : 16.sp,
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: kIsWeb ? 16 : 16.w,
            mainAxisSpacing: kIsWeb ? 16 : 16.h,
            childAspectRatio: 1.1,
          ),
          itemCount: sortedSubjects.length,
          itemBuilder: (context, index) {
            final subject = sortedSubjects[index];
            // Find the original index of this subject in the unsorted list
            final originalIndex =
                originalSubjects.indexWhere((s) => s.id == subject.id);
            return _buildSubjectCard(subject, index, originalIndex);
          },
        );
      },
    );
  }

  Widget _buildSubjectCard(
      Subject subject, int displayIndex, int originalIndex) {
    final subjectColor = _hexToColor(subject.color);
    final isPressed = _pressedCardIndex == displayIndex;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressedCardIndex = displayIndex;
        });
      },
      onTapUp: (_) async {
        setState(() {
          _pressedCardIndex = -1;
        });
        await VibrationService().navigationVibration();
        if (widget.onNavigateToSubject != null) {
          // Use originalIndex for navigation to match the unsorted list in SubjectScreen
          widget.onNavigateToSubject!(originalIndex);
        }
      },
      onTapCancel: () {
        setState(() {
          _pressedCardIndex = -1;
        });
      },
      child: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          // Staggered animation delay for each card
          final delay = displayIndex * 0.1;
          final animationValue =
              (_cardAnimationController.value - delay).clamp(0.0, 1.0);

          return Transform.scale(
            scale: 0.95 + (0.05 * animationValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kIsWeb ? 20 : 40.r),
                boxShadow: [
                  // Bottom and right shadow for 3D effect
                  BoxShadow(
                    color: Colors.grey.withOpacity(isPressed ? 0.2 : 0.4),
                    blurRadius: isPressed ? 2 : 4,
                    offset: Offset(isPressed ? 1 : 3, isPressed ? 1 : 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Subject content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Subject image/icon
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kIsWeb ? 10 : 10.r),
                          ),
                          child: subject.logo.isNotEmpty
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(kIsWeb ? 10 : 10.r),
                                  child: _optimizedNetworkImage(
                                    imageUrl: subject.logo,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) {
                                      return _buildSubjectIcon(
                                          subject.name, subjectColor);
                                    },
                                    placeholder: (context, url) =>
                                        _buildSubjectIconLoading(subjectColor),
                                  ),
                                )
                              : _buildSubjectIcon(subject.name, subjectColor),
                        ),
                      ),

                      SizedBox(height: kIsWeb ? 8 : 8.h),

                      // Subject name
                      Text(
                        subject.name,
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: kIsWeb ? 8 : 8.h),
                    ],
                  ),

                  // Due badge - positioned at top right
                  if (subject.hasDueModule)
                    Positioned(
                      right: kIsWeb ? -6 : -6.w,
                      top: kIsWeb ? -6 : -6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: kIsWeb ? 8 : 8.w,
                          vertical: kIsWeb ? 4 : 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(kIsWeb ? 12 : 12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: kIsWeb ? 12 : 12.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: kIsWeb ? 4 : 4.w),
                            Text(
                              'Due',
                              style: TextStyle(
                                fontSize: kIsWeb ? 10 : 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Arrow button
                  Positioned(
                    right: kIsWeb ? -10 : -4.w,
                    bottom: kIsWeb ? -10 : -4.h,
                    child: Container(
                      width: kIsWeb ? 28 : 40.w,
                      height: kIsWeb ? 28 : 40.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1FB7EB),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1FB7EB).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        size: kIsWeb ? 26 : 34.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectIcon(String subjectName, Color subjectColor) {
    IconData iconData = _getSubjectIcon(subjectName);

    return Container(
      decoration: BoxDecoration(
        color: subjectColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: kIsWeb ? 48 : 48.sp,
          color: subjectColor,
        ),
      ),
    );
  }

  Widget _buildSubjectIconLoading(Color subjectColor) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _shimmerController.value, 0),
              end: Alignment(-0.5 + 2 * _shimmerController.value, 0),
              colors: [
                subjectColor.withOpacity(0.08),
                subjectColor.withOpacity(0.02),
                subjectColor.withOpacity(0.08),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(subjectColor.withOpacity(0.5)),
            ),
          ),
        );
      },
    );
  }

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') ||
        name.contains('algebra') ||
        name.contains('geometry')) {
      return Icons.calculate;
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
    } else if (name.contains('economics') || name.contains('business')) {
      return Icons.trending_up;
    } else if (name.contains('computer') || name.contains('programming')) {
      return Icons.computer;
    } else {
      return Icons.book;
    }
  }

  /// Web-only: builds the selected subject detail card + bottom icon row
  Widget _buildWebSubjectSection() {
    return BlocBuilder<SubjectBloc, SubjectState>(
      buildWhen: (previous, current) =>
          current is SubjectsLoaded ||
          current is SubjectLoading ||
          current is SubjectError ||
          current is ModulesLoaded ||
          current is ModulesLoading,
      builder: (context, state) {
        if (state is SubjectLoading) {
          return _buildSubjectGridSkeleton();
        }

        if (state is SubjectError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading subjects: ${state.message}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Get subjects
        List<Subject> originalSubjects = [];
        if (state is SubjectsLoaded) {
          originalSubjects = state.subjects;
        } else {
          final subjectBloc = context.read<SubjectBloc>();
          originalSubjects = subjectBloc.cachedSubjects;
        }

        final sortedSubjects = List<Subject>.from(originalSubjects)
          ..sort((a, b) {
            if (a.hasDueModule && !b.hasDueModule) return -1;
            if (!a.hasDueModule && b.hasDueModule) return 1;
            return 0;
          });

        if (sortedSubjects.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No subjects available',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        // Clamp selected index
        if (_selectedSubjectIndex >= sortedSubjects.length) {
          _selectedSubjectIndex = 0;
        }

        final selectedSubject = sortedSubjects[_selectedSubjectIndex];

        // Ensure modules are loaded for the selected subject
        final subjectBloc = context.read<SubjectBloc>();
        if (!subjectBloc.hasCachedModules(selectedSubject.id)) {
          subjectBloc.add(LoadSubjectModules(selectedSubject.id));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectedSubjectCard(
              selectedSubject,
              originalSubjects,
              subjectBloc,
            ),
            const SizedBox(height: 16),
            _buildSubjectIconRow(sortedSubjects),
          ],
        );
      },
    );
  }

  /// Web-only: large detail card for the selected subject
  Widget _buildSelectedSubjectCard(
    Subject subject,
    List<Subject> originalSubjects,
    SubjectBloc subjectBloc,
  ) {
    final subjectColor = _hexToColor(subject.color);
    final originalIndex =
        originalSubjects.indexWhere((s) => s.id == subject.id);

    // Get cached modules for this subject
    final modules = subjectBloc.getCachedModules(subject.id).reversed.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: subject name + due badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LEVEL 1',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (subject.hasDueModule)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Due',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Subject image centered
          Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: subject.logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _optimizedNetworkImage(
                        imageUrl: subject.logo,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) {
                          return _buildSubjectIcon(subject.name, subjectColor);
                        },
                      ),
                    )
                  : _buildSubjectIcon(subject.name, subjectColor),
            ),
          ),

          const SizedBox(height: 20),

          // Chapter list
          if (modules.isNotEmpty) ...[
            Text(
              'Chapters',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...modules.take(2).map((module) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Chapter logo or icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: module.logo != null && module.logo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _optimizedNetworkImage(
                                  imageUrl: module.logo!,
                                  fit: BoxFit.contain,
                                  memCacheWidth: 96,
                                  memCacheHeight: 96,
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.menu_book_rounded,
                                    size: 18,
                                    color: subjectColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                                color: subjectColor,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          module.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status indicator
                      Icon(
                        module.userStatus.icon,
                        size: 18,
                        color: module.userStatus.color,
                      ),
                    ],
                  ),
                )),
            if (modules.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${modules.length - 2} more chapters',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ] else ...[
            // Show loading indicator for modules
            BlocBuilder<SubjectBloc, SubjectState>(
              buildWhen: (_, current) =>
                  current is ModulesLoading || current is ModulesLoaded,
              builder: (context, modState) {
                if (modState is ModulesLoading &&
                    modState.subjectId == subject.id) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],

          const SizedBox(height: 20),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.onNavigateToSubject != null) {
                  widget.onNavigateToSubject!(
                      originalIndex >= 0 ? originalIndex : 0);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web-only: horizontal row of small subject icons at the bottom
  Widget _buildSubjectIconRow(List<Subject> subjects) {
    return SizedBox(
      height: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    constraints.maxWidth > 16 ? constraints.maxWidth - 16 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(subjects.length, (index) {
                  final subject = subjects[index];
                  final isSelected = index == _selectedSubjectIndex;
                  final subjectColor = _hexToColor(subject.color);

                  return GestureDetector(
                    onTap: () {
                      if (_selectedSubjectIndex != index) {
                        setState(() {
                          _selectedSubjectIndex = index;
                        });
                        // Trigger module load for the newly selected subject
                        final subjectBloc = context.read<SubjectBloc>();
                        if (!subjectBloc.hasCachedModules(subject.id)) {
                          subjectBloc.add(LoadSubjectModules(subject.id));
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? subjectColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _accentBlue : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _accentBlue.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: subject.logo.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: _optimizedNetworkImage(
                                  imageUrl: subject.logo,
                                  fit: BoxFit.contain,
                                  memCacheWidth: 120,
                                  memCacheHeight: 120,
                                  errorWidget: (_, __, ___) => Icon(
                                    _getSubjectIcon(subject.name),
                                    size: 24,
                                    color: subjectColor,
                                  ),
                                ),
                              )
                            : Icon(
                                _getSubjectIcon(subject.name),
                                size: 24,
                                color: subjectColor,
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: kIsWeb ? 16 : 16.w,
        mainAxisSpacing: kIsWeb ? 16 : 16.h,
        childAspectRatio: 1.1,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _buildSubjectCardSkeleton();
      },
    );
  }

  Widget _buildSubjectCardSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
                      gradient: LinearGradient(
                        begin:
                            Alignment(-1.0 + 2 * _shimmerController.value, 0),
                        end: Alignment(-0.5 + 2 * _shimmerController.value, 0),
                        colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade50,
                          Colors.grey.shade200,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: kIsWeb ? 12 : 12.h),
                Container(
                  height: kIsWeb ? 20 : 20.h,
                  width: kIsWeb ? 80 : 80.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kIsWeb ? 4 : 4.r),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
