import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/mission/mission_bloc.dart';
import '../../utils/web_size_utils.dart';
import '../../blocs/mission/mission_content_bloc.dart';
import '../../models/mission_model.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../services/mission_api_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/smooth_scroll_wrapper.dart';
import '../../widgets/tutorial_overlay.dart';
import 'mission_subject_screen.dart';

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

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with TickerProviderStateMixin {
  late DateTime _currentDate;
  late DateTime _selectedDate;
  final ScrollController _missionScrollController = ScrollController();

  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Calendar and progress section animation controllers
  late AnimationController _calendarController;
  late AnimationController _progressController;
  late AnimationController _buttonController;
  late Animation<double> _calendarFadeAnimation;
  late Animation<Offset> _calendarSlideAnimation;
  late Animation<double> _progressFadeAnimation;
  late Animation<Offset> _progressSlideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;

  // Base color for mission screen (using blue as default)
  final Color _baseColor = Colors.blue;

  // Tutorial state
  bool _showTutorial = false;
  bool _tutorialChecked = false;
  bool _didPrecacheAssets = false;

  // GlobalKeys for tutorial highlights
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _startButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize with current month and today's date
    final now = DateTime.now();
    _currentDate =
        DateTime(now.year, now.month, 1); // First day of current month
    _selectedDate = DateTime(now.year, now.month, now.day); // Today's date

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

    // Load missions when the screen initializes
    context.read<MissionBloc>().add(LoadMissions(
          month: _currentDate.month,
          year: _currentDate.year,
        ));

    // Check if tutorial should be shown
    _checkTutorialStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheAssets) return;
    _didPrecacheAssets = true;
    precacheImage(const AssetImage('assets/images/boy.png'), context);
  }

  /// Check if the mission screen tutorial should be shown
  Future<void> _checkTutorialStatus() async {
    if (_tutorialChecked) return;
    _tutorialChecked = true;

    final hasSeenTutorial = await OnboardingService.isScreenTutorialComplete(
      ScreenTutorial.missionScreen,
    );

    if (!hasSeenTutorial && mounted) {
      // Wait for the screen to build and data to load
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() {
          _showTutorial = true;
        });
      }
    }
  }

  /// Complete and hide the tutorial
  void _completeTutorial() async {
    await OnboardingService.completeScreenTutorial(
        ScreenTutorial.missionScreen);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _missionScrollController.dispose();
    super.dispose();
  }

  // Helper function to create light/pastel versions of color for gradients
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white,
      // Very subtle tint
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white,
      // Subtle tint
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      // Light tint
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white,
      // Medium light tint
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
      // Pastel color
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      // Fade back
      Colors.white,
      // Blend back to white
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
  Widget build(BuildContext context) {
    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        final topGradientColors = _getGradientColors(_baseColor);
        final bottomGradientColors = _getBottomGradientColors(_baseColor);

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
                height: kIsWeb ? 200 : 0.25.sh, // 1/4 of screen height
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
                height: kIsWeb ? 250 : 0.33.sh, // 1/3 of screen height
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
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // Large circle in top right
                    AnimatedBuilder(
                      animation: _circle1Animation,
                      builder: (context, child) {
                        return Positioned(
                          top: (kIsWeb ? -100.0 : -100.h) +
                              _circle1Animation.value,
                          right: kIsWeb ? -100.0 : -100.w,
                          child: Container(
                            width: kIsWeb ? 300 : 300.w,
                            height: kIsWeb ? 300 : 300.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _baseColor.withOpacity(0.15),
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
                          top: (kIsWeb ? 200.0 : 240.h) +
                              _circle2Animation.value,
                          left: kIsWeb ? 40.0 : 40.w,
                          child: Container(
                            width: kIsWeb ? 120 : 120.w,
                            height: kIsWeb ? 120 : 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _baseColor.withOpacity(0.25),
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
                          bottom: (kIsWeb ? 200.0 : 240.h) -
                              _circle3Animation.value,
                          right: kIsWeb ? 20.0 : 20.w,
                          child: Container(
                            width: kIsWeb ? 50 : 50.w,
                            height: kIsWeb ? 50 : 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _baseColor.withOpacity(0.25),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Animated content
            AnimatedScreenLayout(
              appBar: Padding(
                padding: EdgeInsets.all(kIsWeb ? 16 : 20.0),
                child: _buildMissionHeader(),
              ),
              body: Container(
                constraints: BoxConstraints(
                  maxWidth: kIsWeb ? 500 : double.infinity,
                ),
                child: SmoothScrollOverlay(
                  showTopFade: false,
                  showBottomFade: false,
                  fadeHeight: kIsWeb ? 40 : 40.h,
                  fadeColor: Colors.white,
                  child: Scrollbar(
                    controller: _missionScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _missionScrollController,
                      physics: const BouncingScrollPhysics(),
                      padding:
                          EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: kIsWeb ? 16 : 24),

                          // Calendar Section
                          Container(
                            key: _calendarKey,
                            child: _buildCalendarSection(state),
                          ),

                          SizedBox(height: kIsWeb ? 16 : 24),

                          // Progress Section
                          Container(
                            key: _progressKey,
                            child: _buildProgressSection(state),
                          ),

                          SizedBox(height: kIsWeb ? 24 : 40),

                          // Start Button
                          Container(
                            key: _startButtonKey,
                            child: _buildStartButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              animationDuration: const Duration(milliseconds: 600),
              animationCurve: Curves.easeOutCubic,
              enableStaggeredAnimation: true,
              staggerDelay: const Duration(milliseconds: 100),
            ),

            // Tutorial overlay - disabled for now
            // if (_showTutorial)
            //   Positioned.fill(
            //     child: TutorialOverlay(
            //       steps: _buildTutorialSteps(),
            //       onComplete: _completeTutorial,
            //       accentColor: _baseColor,
            //       bottomPadding: kIsWeb ? 0 : 100.h, // Account for bottom navigation bar
            //     ),
            //   ),
          ],
        );
      },
    );
  }

  /// Build tutorial steps for the mission screen
  List<TutorialStep> _buildTutorialSteps() {
    return [
      TutorialStep(
        targetKey: _calendarKey,
        title: 'Mission Calendar',
        description:
            'View your daily missions here. Dates with 🎁 icons have missions to complete. Green ✓ means all missions for that day are done!',
        icon: Icons.calendar_month_rounded,
        tooltipPosition: TooltipPosition.center,
        shape: HighlightShape.roundedRect,
        highlightPadding: 8,
      ),
      TutorialStep(
        targetKey: _progressKey,
        title: 'Monthly Progress',
        description:
            'Track your mission completion progress for the current month. Complete more missions to fill the bar!',
        icon: Icons.trending_up_rounded,
        tooltipPosition: TooltipPosition.center,
        shape: HighlightShape.roundedRect,
        highlightPadding: 8,
      ),
      TutorialStep(
        targetKey: _startButtonKey,
        title: 'Start Your Mission',
        description:
            'Select today\'s date and tap here to begin your mission. Complete missions to earn rewards!',
        icon: Icons.play_circle_rounded,
        tooltipPosition: TooltipPosition.center,
        shape: HighlightShape.roundedRect,
        highlightPadding: 8,
      ),
    ];
  }

  Widget _buildMissionHeader() {
    return Center(
      child: Text(
        'Mission',
        style: TextStyle(
          fontSize: kIsWeb ? 20 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildCalendarSection(MissionState state) {
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Navigation
          _buildMonthNavigation(),

          SizedBox(height: kIsWeb ? 16 : 20),

          // Days of Week
          _buildDaysOfWeek(),

          SizedBox(height: kIsWeb ? 12 : 16),

          // Calendar Grid
          _buildCalendarGrid(state),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthNames = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous month button
        IconButton(
          onPressed: () async {
            // await SoundService().playButtonClick();
            await VibrationService().navigationVibration();
            _changeMonth(-1);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.blue,
            size: kIsWeb ? 18 : 20,
          ),
        ),
        Text(
          '${monthNames[_currentDate.month - 1]} ${_currentDate.year}',
          style: TextStyle(
            fontSize: kIsWeb ? 18 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        // Next month button
        IconButton(
          onPressed: () async {
            // await SoundService().playButtonClick();
            await VibrationService().navigationVibration();
            _changeMonth(1);
          },
          icon: Icon(
            Icons.arrow_forward_ios,
            color: Colors.blue,
            size: kIsWeb ? 18 : 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek() {
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((day) => Text(
                day,
                style: TextStyle(
                  fontSize: kIsWeb ? 14 : 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(MissionState state) {
    final year = _currentDate.year;
    final month = _currentDate.month;

    // Get the first day of the month
    final firstDayOfMonth = DateTime(year, month, 1);
    // Get the last day of the month
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // Get the day of week for the first day (0 = Sunday, 1 = Monday, etc.)
    final firstDayWeekday =
        firstDayOfMonth.weekday % 7; // Convert to Sunday = 0

    final calendarData = <List<int>>[];
    final currentWeek = <int>[];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayWeekday; i++) {
      currentWeek.add(0); // 0 indicates empty cell
    }

    // Add all days of the current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      currentWeek.add(day);

      if (currentWeek.length == 7) {
        calendarData.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    // Add the last week if it's not complete
    if (currentWeek.isNotEmpty) {
      // Fill remaining days with empty cells
      while (currentWeek.length < 7) {
        currentWeek.add(0);
      }
      calendarData.add(List.from(currentWeek));
    }

    return Column(
      children: calendarData
          .map((week) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: week
                    .map((day) => Expanded(
                          child: _buildCalendarDay(day, year, month, state),
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarDay(int day, int year, int month, MissionState state) {
    // Handle empty cells (padding days from next month)
    if (day == 0) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: EdgeInsets.all(kIsWeb ? 1 : 2),
        ),
      );
    }

    // Determine if this day belongs to the current month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final isCurrentMonth = day >= 1 && day <= daysInMonth;
    final isSelected = day == _selectedDate.day &&
        month == _selectedDate.month &&
        year == _selectedDate.year; // Selected date

    // Check if this is today's date
    final now = DateTime.now();
    final isToday = day == now.day && month == now.month && year == now.year;

    // Check if this date has missions from the API
    bool hasTarget = false;
    bool allMissionsCompleted = false;
    if (state is MissionLoaded) {
      final date = DateTime(year, month, day);
      final missionsOnDate = state.missions
          .where((mission) =>
              mission.missionDate.year == date.year &&
              mission.missionDate.month == date.month &&
              mission.missionDate.day == date.day)
          .toList();

      hasTarget = missionsOnDate.isNotEmpty;
      // Show tick only if ALL missions for this day are completed
      allMissionsCompleted = missionsOnDate.isNotEmpty &&
          missionsOnDate.every((mission) => mission.userCompleted);
    }

    final isOutsideMonth = !isCurrentMonth;

    return GestureDetector(
      onTap: isCurrentMonth
          ? () async {
              await VibrationService().selectionVibration();
              setState(() {
                _selectedDate = DateTime(year, month, day);
              });
            }
          : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: EdgeInsets.all(kIsWeb ? 1 : 2),
          decoration: BoxDecoration(
            color: isToday ? Colors.blue.withOpacity(0.1) : null,
            border:
                isSelected ? Border.all(color: Colors.blue, width: 2) : null,
            borderRadius: BorderRadius.circular(kIsWeb ? 6 : 8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: kIsWeb ? 13 : 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isOutsideMonth
                      ? Colors.grey[300]
                      : isToday
                          ? Colors.blue
                          : isCurrentMonth
                              ? Colors.black
                              : Colors.grey[400],
                ),
              ),
              if (hasTarget && isCurrentMonth)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: kIsWeb ? 16 : 20,
                    height: kIsWeb ? 16 : 20,
                    decoration: BoxDecoration(
                      color:
                          allMissionsCompleted ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 10),
                      boxShadow: [
                        BoxShadow(
                          color: (allMissionsCompleted
                                  ? Colors.green
                                  : Colors.orange)
                              .withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      allMissionsCompleted
                          ? Icons.check_circle
                          : Icons.card_giftcard,
                      color: Colors.white,
                      size: kIsWeb ? 10 : 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(MissionState state) {
    int completedMissions = 0;
    int totalMissions = 0;

    if (state is MissionLoaded) {
      // Filter missions for the current displayed month
      final currentMonthMissions = state.missions
          .where((mission) =>
              mission.missionDate.year == _currentDate.year &&
              mission.missionDate.month == _currentDate.month)
          .toList();

      totalMissions = currentMonthMissions.length;
      completedMissions =
          currentMonthMissions.where((m) => m.userCompleted).length;
    }

    final progress =
        totalMissions > 0 ? completedMissions / totalMissions : 0.0;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: kIsWeb ? 16 : 20,
            ),
            Text(
              textAlign: TextAlign.center,
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: kIsWeb ? 12 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: kIsWeb ? 30 : 40),
              width: double.infinity,
              height: kIsWeb ? 6 : 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(kIsWeb ? 3 : 4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(kIsWeb ? 3 : 4),
                  ),
                ),
              ),
            )
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: kIsWeb ? 60 : 80,
              height: kIsWeb ? 60 : 80,
              color: Colors.transparent,
              child: Image.asset(
                'assets/images/boy.png',
                width: kIsWeb ? 60 : 80,
                height: kIsWeb ? 60 : 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        bool hasMissionForSelectedDate = false;
        bool canStartMission = false;
        List<Mission> missionsOnSelectedDate = [];
        String buttonText = 'No Mission Available';

        if (state is MissionLoaded) {
          missionsOnSelectedDate = state.missions
              .where((mission) =>
                  mission.missionDate.year == _selectedDate.year &&
                  mission.missionDate.month == _selectedDate.month &&
                  mission.missionDate.day == _selectedDate.day)
              .toList();

          hasMissionForSelectedDate = missionsOnSelectedDate.isNotEmpty;
          if (hasMissionForSelectedDate) {
            // Check if today's date equals selected date
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final selectedDateOnly = DateTime(
                _selectedDate.year, _selectedDate.month, _selectedDate.day);
            final isTodaySelected = today.isAtSameMomentAs(selectedDateOnly);

            // Check if all missions are completed
            final allCompleted =
                missionsOnSelectedDate.every((m) => m.userCompleted);

            // Can start only if: mission exists, today's date equals selected date, and not all completed
            canStartMission =
                hasMissionForSelectedDate && isTodaySelected && !allCompleted;

            // Set appropriate button text based on conditions
            if (!isTodaySelected) {
              buttonText = 'Start Mission';
            } else if (allCompleted) {
              buttonText = 'All Missions Completed';
            } else {
              buttonText = 'Start Mission';
            }
          }
        }

        return Container(
          width: double.infinity,
          height: kIsWeb ? 48 : 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12),
            border: Border(
              bottom: BorderSide(
                color: canStartMission ? _hexToColor("365DEA") : Colors.grey,
                width: 3,
              ),
            ),
          ),
          child: ElevatedButton(
            onPressed: canStartMission
                ? () async {
                    if (missionsOnSelectedDate.isEmpty) {
                      return;
                    }
                    // await SoundService().playButtonClick();
                    await VibrationService().successVibration();

                    // Always navigate to mission subject screen
                    _navigateToMissionSubject(missionsOnSelectedDate);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canStartMission ? _hexToColor("6989FF") : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: kIsWeb ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _changeMonth(int direction) {
    setState(() {
      // Calculate new month and year
      int newMonth = _currentDate.month + direction;
      int newYear = _currentDate.year;

      // Handle month overflow/underflow
      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      // Update current date to first day of the new month
      _currentDate = DateTime(newYear, newMonth, 1);

      // Reset selected date to first day of the new month
      _selectedDate = DateTime(newYear, newMonth, 1);
    });

    // Reload missions for the new month
    context.read<MissionBloc>().add(LoadMissions(
          month: _currentDate.month,
          year: _currentDate.year,
        ));
  }

  Future<void> _navigateToMissionSubject(List<Mission> missions) async {
    // Use shared axis for lateral navigation between mission types
    await Navigator.push(
      context,
      ConnectedPageTransitions.sharedAxisHorizontal(
        page: MissionSubjectScreen(
          missions: missions,
          selectedDate: _selectedDate,
        ),
      ),
    );
    // Refresh missions after returning from the subject screen
    if (mounted) {
      context.read<MissionBloc>().add(RefreshMissions(
            month: _currentDate.month,
            year: _currentDate.year,
          ));
    }
  }
}
