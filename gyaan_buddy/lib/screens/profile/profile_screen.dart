import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../blocs/user/user_bloc.dart';
import '../../utils/web_size_utils.dart';
import '../../models/user_model.dart';
import '../../models/subject_progress_model.dart';
import '../../utils/animation_utils.dart';
import '../../services/vibration_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/vibration_button.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/smooth_scroll_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  double soundVolume = 1.0;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  String appVersion = '1.0.0';
  String buildNumber = '203';

  @override
  void initState() {
    super.initState();
    // Initialize vibration state from VibrationService
    vibrationEnabled = VibrationService().isEnabled;
    // Initialize sound state from SoundService
    soundEnabled = SoundService().isSoundEnabled;
    soundVolume = SoundService().volume;

    // Initialize progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Load package info for version display
    _loadPackageInfo();

    // Ensure we load current user when profile screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load vibration setting from SharedPreferences
      final vibrationService = VibrationService();
      // Load sound setting from SharedPreferences
      final soundService = SoundService();
      setState(() {
        vibrationEnabled = vibrationService.isEnabled;
        soundEnabled = soundService.isSoundEnabled;
        soundVolume = soundService.volume;
      });

      // Play profile loading sound
      soundService.playProfileLoading();

      // Always fetch fresh profile data when screen opens (bypass cache)
      context.read<UserBloc>().add(const LoadCurrentUser(forceRefresh: true));
    });
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appVersion = packageInfo.version;
          buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      // If package info fails to load, keep default values
      print('Error loading package info: $e');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // Calculate rewards progress as a percentage of the circle (0.0 to 1.0)
  double _calculateRewardsProgress(User user) {
    // Orange area = rewards / maxExp for that level
    if (user.level == null || user.level!.maxExp == 0) return 0.0;

    return (user.rewards / user.level!.maxExp).clamp(0.0, 1.0);
  }

  // Calculate actual XP progress as a percentage of the circle (0.0 to 1.0)
  double _calculateXPProgress(User user) {
    // Blue area = actualExp / maxExp for that level
    // Since totalExp = rewards + actualExp, then actualExp = totalExp - rewards
    if (user.level == null || user.level!.maxExp == 0) return 0.0;

    final actualExp = user.totalExp - user.rewards;
    return (actualExp / user.level!.maxExp).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is UserAuthenticated) {
            // Start progress animation when user data is loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _progressController.forward();
            });
            return AnimationUtils.staggeredList(
              children: [_buildProfileContent(state.user)],
            );
          } else if (state is UserUnauthenticated) {
            // User is not authenticated, show appropriate message
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: kIsWeb ? 64 : 64.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(height: kIsWeb ? 16 : 16.h),
                    Text(
                      'Please log in to view your profile',
                      style: TextStyle(
                        fontSize: kIsWeb ? 16 : 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is LeaderboardLoading ||
              state is LeaderboardLoaded ||
              state is LeaderboardError) {
            // If we're in a leaderboard state, don't automatically reset
            // This allows leaderboard screen to work properly when navigated to
            // Only reset if we're actually on the profile screen and not navigating away
            final cachedUser = context.read<UserBloc>().currentUser;
            if (cachedUser != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _progressController.forward();
              });
              return AnimationUtils.staggeredList(
                children: [_buildProfileContent(cachedUser)],
              );
            }
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            // For any other state (including UserInitial), try to load current user
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<UserBloc>().add(const LoadCurrentUser());
            });
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(User user) {
    return AnimatedScreenLayout(
      appBar: Container(
        padding: EdgeInsets.only(
          top: kIsWeb ? 16 : MediaQuery.of(context).padding.top + 20.h,
          left: kIsWeb ? 20 : 20.w,
          right: kIsWeb ? 20 : 20.w,
          bottom: kIsWeb ? 16 : 20.h,
        ),
        child: Row(
          children: [
            AnimationUtils.animatedButton(
              onPressed: () async {
                await VibrationService().lightVibration();
                // Profile picture tap action
              },
              child: Container(
                width: kIsWeb ? 80 : 80.w,
                height: kIsWeb ? 80 : 80.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: kIsWeb ? 2 : 2.r,
                      blurRadius: kIsWeb ? 8 : 8.r,
                      offset: Offset(0, kIsWeb ? 4 : 4.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.firstName.isNotEmpty
                        ? user.firstName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: kIsWeb ? 32 : 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: kIsWeb ? 20 : 20.w),
            Expanded(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName : user.username,
                style: TextStyle(
                  fontSize: kIsWeb ? 24 : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: !kIsWeb,
        bottom: !kIsWeb,
        child: SmoothScrollOverlay(
          showTopFade: true,
          showBottomFade: true,
          fadeHeight: kIsWeb ? 40 : 40.h,
          fadeColor: Colors.white,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 20.w),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: kIsWeb ? 30 : 30.h),

              // Stats Card with animations
              AnimationUtils.animatedCard(
                index: 0,
                child: _buildAnimatedStatsCard(user),
              ),
              SizedBox(height: kIsWeb ? 30 : 30.h),

              // Subject Progress Section with animations
              if (user.subjectProgress.isNotEmpty) ...[
                AnimationUtils.animatedCard(
                  index: 1,
                  child: _buildAnimatedSubjectProgressSection(user),
                ),
                SizedBox(height: kIsWeb ? 30 : 30.h),
              ],

              // Settings Section
              AnimationUtils.animatedCard(
                index: user.subjectProgress.isNotEmpty ? 2 : 1,
                child: _buildSettingsSection(),
              ),
              SizedBox(height: kIsWeb ? 20 : 20.h),

              // Support Section
              AnimationUtils.animatedCard(
                index: 2,
                child: _buildSupportSection(),
              ),
              SizedBox(height: kIsWeb ? 20 : 20.h),

              // Logout Section
              AnimationUtils.animatedCard(
                index: 3,
                child: _buildLogoutSection(),
              ),
              SizedBox(height: kIsWeb ? 30 : 30.h),

              // Version Info
              Center(
                child: Text(
                  'Build Version $appVersion Build $buildNumber',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: kIsWeb ? 12 : 12.sp,
                  ),
                ),
              ),
              SizedBox(height: kIsWeb ? 20 : 100.h), // Space for floating nav bar
            ],
          ),
        ),
        ),
      ),
      animationDuration: const Duration(milliseconds: 600),
      animationCurve: Curves.easeOutCubic,
      enableStaggeredAnimation: true,
      staggerDelay: const Duration(milliseconds: 100),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: kIsWeb ? 14 : 14.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: kIsWeb ? 4 : 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: kIsWeb ? 18 : 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Animated stat item with counting animation
  Widget _buildAnimatedStatItem(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: kIsWeb ? 14 : 14.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: kIsWeb ? 4 : 4.h),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final animatedValue = (value * _progressAnimation.value).toInt();
            return Text(
              animatedValue.toString(),
              style: TextStyle(
                fontSize: kIsWeb ? 18 : 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }

  // Stats card with animated values and progress chart
  Widget _buildAnimatedStatsCard(User user) {
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: kIsWeb ? 1 : 1.r,
            blurRadius: kIsWeb ? 10 : 10.r,
            offset: Offset(0, kIsWeb ? 2 : 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - Stats with counting animation
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedStatItem('Rewards', user.rewards, const Color(0xFFFF8A65)),
                SizedBox(height: kIsWeb ? 15 : 15.h),
                _buildAnimatedStatItem('XP', user.totalExp, const Color(0xFF2196F3)),
                SizedBox(height: kIsWeb ? 15 : 15.h),
                _buildAnimatedStatItem('Level', user.levelNumber, Colors.grey),
              ],
            ),
          ),
          SizedBox(width: kIsWeb ? 20 : 20.w),
          // Right side - Animated Progress Chart
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: kIsWeb ? 80 : 120.w,
                  height: kIsWeb ? 80 : 120.w,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: MultiProgressPainter(
                          xpProgress: _calculateXPProgress(user) *
                              _progressAnimation.value,
                          rewardsProgress:
                              _calculateRewardsProgress(user) *
                                  _progressAnimation.value,
                          strokeWidth: kIsWeb ? 8 : 8.w,
                        ),
                      );
                    },
                  ),
                ),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    // Total progress = totalExp / maxExp for that level
                    final totalProgress =
                        user.level != null && user.level!.maxExp > 0
                            ? (user.totalExp / user.level!.maxExp) *
                                _progressAnimation.value
                            : 0.0;
                    return Text(
                      '${user.totalExp} XP',
                      style: TextStyle(
                        fontSize: kIsWeb ? 18 : 14.sp,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.fade,
                        color: Colors.black87,
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
  }

  // Subject progress section with staggered animations
  Widget _buildAnimatedSubjectProgressSection(User user) {
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: kIsWeb ? 1 : 1.r,
            blurRadius: kIsWeb ? 10 : 10.r,
            offset: Offset(0, kIsWeb ? 2 : 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Progress',
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: kIsWeb ? 20 : 20.h),
          ...user.subjectProgress.asMap().entries.map((entry) => 
            _buildAnimatedSubjectProgressBar(entry.value, entry.key)
          ),
        ],
      ),
    );
  }

  // Animated subject progress bar with staggered delay
  Widget _buildAnimatedSubjectProgressBar(SubjectProgress progress, int index) {
    final color = progress.colorValue ?? Colors.blue;
    // Stagger the animation for each subject
    final staggerDelay = index * 0.15;
    
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16 : 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  progress.subjectName,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Animated percentage
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  final delayedProgress = ((_progressAnimation.value - staggerDelay) / (1 - staggerDelay)).clamp(0.0, 1.0);
                  final animatedPercentage = progress.chapterCompletionRate * delayedProgress;
                  return Text(
                    '${animatedPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: kIsWeb ? 14 : 14.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              // Apply staggered delay to progress bar
              final delayedProgress = ((_progressAnimation.value - staggerDelay) / (1 - staggerDelay)).clamp(0.0, 1.0);
              
              return Stack(
                children: [
                  // Background bar
                  Container(
                    height: kIsWeb ? 8 : 10.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(kIsWeb ? 4 : 5.r),
                    ),
                  ),
                  // Animated progress bar with spring effect
                  FractionallySizedBox(
                    widthFactor: progress.progressValue * delayedProgress,
                    child: Container(
                      height: kIsWeb ? 8 : 10.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(kIsWeb ? 4 : 5.r),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3 * delayedProgress),
                            blurRadius: kIsWeb ? 4 : 4.r,
                            offset: Offset(0, kIsWeb ? 2 : 2.h),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: kIsWeb ? 4 : 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.chaptersCompleted} / ${progress.totalChaptersInAttemptedModules} chapters completed',
                style: TextStyle(
                  fontSize: kIsWeb ? 11 : 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${progress.questionsAttempted} questions attempted',
                style: TextStyle(
                  fontSize: kIsWeb ? 11 : 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressSection(User user) {
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: kIsWeb ? 1 : 1.r,
            blurRadius: kIsWeb ? 10 : 10.r,
            offset: Offset(0, kIsWeb ? 2 : 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Progress',
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: kIsWeb ? 20 : 20.h),
          ...user.subjectProgress.map((progress) => 
            _buildSubjectProgressBar(progress)
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressBar(SubjectProgress progress) {
    final color = progress.colorValue ?? Colors.blue;
    
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16 : 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  progress.subjectName,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.chapterCompletionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: kIsWeb ? 14 : 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Background bar
                  Container(
                    height: kIsWeb ? 8 : 10.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(kIsWeb ? 4 : 5.r),
                    ),
                  ),
                  // Progress bar
                  FractionallySizedBox(
                    widthFactor: progress.progressValue * _progressAnimation.value,
                    child: Container(
                      height: kIsWeb ? 8 : 10.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(kIsWeb ? 4 : 5.r),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: kIsWeb ? 4 : 4.r,
                            offset: Offset(0, kIsWeb ? 2 : 2.h),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: kIsWeb ? 4 : 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.chaptersCompleted} / ${progress.totalChaptersInAttemptedModules} chapters completed',
                style: TextStyle(
                  fontSize: kIsWeb ? 11 : 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${progress.questionsAttempted} questions attempted',
                style: TextStyle(
                  fontSize: kIsWeb ? 11 : 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingItem(
          icon: Icons.notifications,
          title: 'Notifications',
          hasToggle: false,
          onTap: () async {
            await VibrationService().navigationVibration();
            Navigator.of(context).pushNamed('/notifications');
          },
        ),
        SizedBox(height: kIsWeb ? 15 : 15.h),
        Visibility(
          child: _buildSettingItem(
            icon: Icons.volume_up,
            title: 'Sound',
            hasToggle: true,
            toggleValue: soundEnabled,
            onToggleChanged: (value) async {
              setState(() {
                soundEnabled = value;
              });
              // Update SoundService with the new setting
              await SoundService().toggleSound();
              // Play a test sound to confirm the setting
              // if (value) {
              //   await SoundService().playButtonClick();
              // }
            },
          ),
          visible: true,
        ),
        SizedBox(height: kIsWeb ? 15 : 15.h),

        _buildSettingItem(
          icon: Icons.vibration,
          title: 'Vibration',
          hasToggle: true,
          toggleValue: vibrationEnabled,
          onToggleChanged: (value) {
            setState(() {
              vibrationEnabled = value;
            });
            // Update VibrationService with the new setting
            VibrationService().setEnabled(value);
          },
        ),
        Divider(height: kIsWeb ? 30 : 30.h),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildSettingItem(
          icon: Icons.help_outline,
          title: 'Help',
          hasToggle: false,
          onTap: () {
            // Handle help tap
          },
        ),
        SizedBox(height: kIsWeb ? 15 : 15.h),
        _buildSettingItem(
          icon: Icons.favorite_outline,
          title: 'Credits',
          hasToggle: false,
          onTap: () async {
            await VibrationService().navigationVibration();
            Navigator.of(context).pushNamed('/credits');
          },
        ),
        SizedBox(height: kIsWeb ? 15 : 15.h),
        _buildSettingItem(
          icon: Icons.flag,
          title: 'Report',
          hasToggle: false,
          onTap: () {
            // Handle report tap
          },
        ),
        Divider(height: kIsWeb ? 30 : 30.h),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return _buildSettingItem(
      icon: Icons.logout,
      title: 'Log Out',
      hasToggle: false,
      textColor: Colors.grey,
      onTap: () async {
        await VibrationService().lightVibration();
        _showLogoutDialog();
      },
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required bool hasToggle,
    bool? toggleValue,
    Function(bool)? onToggleChanged,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    if (onTap == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: kIsWeb ? 8 : 8.h, 
          horizontal: kIsWeb ? 12 : 12.w,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? Colors.grey.shade600,
              size: kIsWeb ? 24 : 24.sp,
            ),
            SizedBox(width: kIsWeb ? 15 : 15.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 16.sp,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            if (hasToggle)
              Switch(
                value: toggleValue ?? false,
                onChanged: onToggleChanged,
                activeColor: Colors.green,
              ),
          ],
        ),
      );
    }

    return AnimationUtils.animatedButton(
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: kIsWeb ? 8 : 8.h, 
          horizontal: kIsWeb ? 12 : 12.w,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? Colors.grey.shade600,
              size: kIsWeb ? 24 : 24.sp,
            ),
            SizedBox(width: kIsWeb ? 15 : 15.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 16.sp,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            if (hasToggle)
              Switch(
                value: toggleValue ?? false,
                onChanged: onToggleChanged,
                activeColor: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            VibrationTextButton(
              onPressed: () async {
                await VibrationService().navigationVibration();
                Navigator.of(context).pop();
              },
              vibrationType: VibrationType.navigation,
              child: Text('Cancel'),
            ),
            VibrationTextButton(
              onPressed: () async {
                await VibrationService().errorVibration();
                Navigator.of(context).pop();
                context.read<UserBloc>().add(const LogoutUser());
                Navigator.of(context).pushReplacementNamed('/login');
              },
              vibrationType: VibrationType.error,
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for multi-colored progress bar
class MultiProgressPainter extends CustomPainter {
  final double xpProgress;
  final double rewardsProgress;
  final double strokeWidth;

  MultiProgressPainter({
    required this.xpProgress,
    required this.rewardsProgress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle (grey) - this will show for the remaining arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Calculate total progress and ensure it doesn't exceed 100%
    final totalProgress = (xpProgress + rewardsProgress).clamp(0.0, 1.0);

    // If total progress is 0, don't draw any arcs
    if (totalProgress <= 0) return;

    // Handle cases where one value is 0
    double adjustedXPProgress;
    double adjustedRewardsProgress;

    if (xpProgress == 0 && rewardsProgress > 0) {
      // Only rewards
      adjustedXPProgress = 0.0;
      adjustedRewardsProgress = rewardsProgress.clamp(0.0, 1.0);
    } else if (rewardsProgress == 0 && xpProgress > 0) {
      // Only XP
      adjustedXPProgress = xpProgress.clamp(0.0, 1.0);
      adjustedRewardsProgress = 0.0;
    } else if (xpProgress > 0 && rewardsProgress > 0) {
      // Both values present - calculate proportional segments
      final xpRatio = xpProgress / (xpProgress + rewardsProgress);
      final rewardsRatio = rewardsProgress / (xpProgress + rewardsProgress);

      adjustedXPProgress = xpRatio * totalProgress;
      adjustedRewardsProgress = rewardsRatio * totalProgress;
    } else {
      // Both are 0
      adjustedXPProgress = 0.0;
      adjustedRewardsProgress = 0.0;
    }

    // XP Progress (Blue)
    if (adjustedXPProgress > 0) {
      final xpPaint = Paint()
        ..color = const Color(0xFF2196F3) // Blue color for XP
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Clamp the progress to ensure it never reaches 100% (full circle)
      // Use a more conservative clamp to ensure grey portion is always visible
      final clampedProgress = adjustedXPProgress.clamp(0.0, 0.95);
      final xpSweepAngle = 2 * 3.14159 * clampedProgress; // Convert to radians

      // Additional safety: ensure sweep angle doesn't exceed 95% of full circle
      final safeSweepAngle = xpSweepAngle.clamp(0.0, 2 * 3.14159 * 0.95);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start from top (-90 degrees)
        safeSweepAngle,
        false,
        xpPaint,
      );
    }

    // Rewards Progress (Orange) - starts where XP ends
    if (adjustedRewardsProgress > 0) {
      final rewardsPaint = Paint()
        ..color = const Color(0xFFFF8A65) // Orange color for rewards
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final xpSweepAngle = 2 * 3.14159 * adjustedXPProgress;
      final rewardsSweepAngle = 2 * 3.14159 * adjustedRewardsProgress;
      final startAngle = -3.14159 / 2 + xpSweepAngle; // Start where XP ends

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        rewardsSweepAngle,
        false,
        rewardsPaint,
      );
    }
  }

  @override
  bool shouldRepaint(MultiProgressPainter oldDelegate) {
    return oldDelegate.xpProgress != xpProgress ||
        oldDelegate.rewardsProgress != rewardsProgress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
