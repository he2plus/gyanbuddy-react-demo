import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/shimmer_image_placeholder.dart';
import '../../blocs/mission/mission_bloc.dart';
import '../../models/mission_model.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/confetti_celebration.dart';
import 'mission_splash_screen.dart';

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

class MissionSubjectScreen extends StatefulWidget {
  final List<Mission> missions;
  final DateTime selectedDate;

  const MissionSubjectScreen({
    super.key,
    required this.missions,
    required this.selectedDate,
  });

  @override
  State<MissionSubjectScreen> createState() => _MissionSubjectScreenState();
}

class _MissionSubjectScreenState extends State<MissionSubjectScreen>
    with TickerProviderStateMixin {
  // Animation controllers for floating circles
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Card animation controllers
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<double>> _cardFadeAnimations;

  // Base color for the screen
  final Color _baseColor = const Color(0xFF6989FF);

  // Track pressed card index for visual feedback
  int? _pressedCardIndex;

  // Track the number of cards for animation controller management
  int _previousCardCount = 0;

  // Track locally completed mission IDs for immediate UI update
  final Set<String> _locallyCompletedMissionIds = {};

  // Track the just-completed mission ID for animation
  String? _justCompletedMissionId;

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
    _initializeCardAnimations(widget.missions);
    _initializeCompletionAnimations();
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

    _completionCheckOpacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _completionCheckController!,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    // Full-screen success overlay animation (longer duration with fade out)
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

  void _triggerCompletionAnimation(String missionId) {
    setState(() {
      _justCompletedMissionId = missionId;
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
          _justCompletedMissionId = null;
        });
      }
    });
  }

  // Get missions from bloc state, filtered by selected date
  List<Mission> _getMissionsFromBloc(MissionState state) {
    if (state is MissionLoaded) {
      return state.missions
          .where((mission) =>
              mission.missionDate.year == widget.selectedDate.year &&
              mission.missionDate.month == widget.selectedDate.month &&
              mission.missionDate.day == widget.selectedDate.day)
          .toList();
    }
    // Fallback to widget.missions if bloc state is not loaded
    return widget.missions;
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
  }

  void _initializeCardAnimations(List<Mission> missions) {
    final uniqueSubjectMissions = _getUniqueSubjectMissionsFromList(missions);
    final cardCount = uniqueSubjectMissions.length;

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
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  // Helper to get unique subject missions from a list
  List<Mission> _getUniqueSubjectMissionsFromList(List<Mission> missions) {
    final Map<String, Mission> uniqueSubjects = {};
    for (final mission in missions) {
      final key = mission.subjectId ?? mission.title;
      debugPrint(
          'Mission: ${mission.title}, subjectId: ${mission.subjectId}, subjectName: ${mission.subjectName}, key: $key');
      if (!uniqueSubjects.containsKey(key)) {
        uniqueSubjects[key] = mission;
      }
    }
    debugPrint(
        'Total missions: ${missions.length}, Unique subjects: ${uniqueSubjects.length}');
    return uniqueSubjects.values.toList();
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
    super.dispose();
  }

  // Get unique subjects from missions (uses current missions from bloc)
  List<Mission> _getUniqueSubjectMissions(List<Mission> missions) {
    return _getUniqueSubjectMissionsFromList(missions);
  }

  // Get all missions for a specific subject
  List<Mission> _getMissionsForSubject(
      List<Mission> missions, String? subjectId, String title) {
    return missions.where((m) {
      if (subjectId != null) {
        return m.subjectId == subjectId;
      }
      return m.title == title;
    }).toList();
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

    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        // Get missions from bloc state, filtered by selected date
        final currentMissions = _getMissionsFromBloc(state);
        final uniqueSubjectMissions =
            _getUniqueSubjectMissions(currentMissions);

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
                    // Date info
                    _buildDateInfo(currentMissions),
                    // Subject cards grid
                    Expanded(
                      child: _buildSubjectCards(
                          currentMissions, uniqueSubjectMissions),
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
              if (_justCompletedMissionId != null &&
                  _successOverlayController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _successOverlayController!,
                      builder: (context, child) {
                        final scale =
                            _successOverlayScaleAnimation?.value ?? 0.0;
                        final opacity =
                            _successOverlayOpacityAnimation?.value ?? 0.0;

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
                'Select Subject',
                style: TextStyle(
                  fontSize: kIsWeb ? 25 : 24,
                  fontWeight: FontWeight.w800,
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

  Widget _buildDateInfo(List<Mission> missions) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final date = widget.selectedDate;
    final dayName = dayNames[date.weekday - 1];
    final monthName = monthNames[date.month - 1];

    // Count available (non-completed) missions, accounting for locally completed ones
    final availableMissions = missions
        .where((m) =>
            !m.userCompleted && !_locallyCompletedMissionIds.contains(m.id))
        .toList();
    final missionCountText = availableMissions.isEmpty
        ? 'All missions completed'
        : '${availableMissions.length} mission${availableMissions.length > 1 ? 's' : ''} available';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 80 : 40.w,
        vertical: kIsWeb ? 20 : 8.h,
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
                Icons.calendar_today,
                color: _baseColor,
                size: kIsWeb ? 24 : 24.sp,
              ),
            ),
            SizedBox(width: kIsWeb ? 16 : 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName, ${date.day} $monthName ${date.year}',
                  style: TextStyle(
                    fontSize: kIsWeb ? 16 : 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: kIsWeb ? 4 : 4.h),
                Text(
                  missionCountText,
                  style: TextStyle(
                    fontSize: kIsWeb ? 13 : 13.sp,
                    color: availableMissions.isEmpty
                        ? Colors.green[600]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCards(
      List<Mission> allMissions, List<Mission> uniqueSubjectMissions) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 80 : 40.w,
        vertical: kIsWeb ? 100 : 16.h,
      ),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: kIsWeb ? 6 : 4,
          crossAxisSpacing: kIsWeb ? 25 : 12.w,
          mainAxisSpacing: kIsWeb ? 12 : 12.h,
          childAspectRatio: kIsWeb ? 0.95 : 1.0,
        ),
        itemCount: uniqueSubjectMissions.length,
        itemBuilder: (context, index) {
          final mission = uniqueSubjectMissions[index];

          // Ensure we have enough animation controllers
          if (index >= _cardControllers.length) {
            return _buildSubjectCard(allMissions, mission, index, null, null);
          }

          return AnimatedBuilder(
            animation: _cardControllers[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardScaleAnimations[index].value,
                child: Opacity(
                  opacity: _cardFadeAnimations[index].value,
                  child: _buildSubjectCard(
                    allMissions,
                    mission,
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

  Widget _buildSubjectCard(
    List<Mission> allMissions,
    Mission mission,
    int index,
    Animation<double>? scaleAnimation,
    Animation<double>? fadeAnimation,
  ) {
    final subjectColor =
        _hexToColor(mission.subjectColor, fallback: _getSubjectColor(index));
    final subjectName = mission.subjectName ?? mission.title;
    final subjectLogo = mission.subjectLogo;
    final isPressed = _pressedCardIndex == index;
    final missionsForSubject =
        _getMissionsForSubject(allMissions, mission.subjectId, mission.title);
    final missionCount = missionsForSubject.length;
    // Count completed missions including locally completed ones
    final completedCount = missionsForSubject
        .where((m) =>
            m.userCompleted || _locallyCompletedMissionIds.contains(m.id))
        .length;
    final isAllCompleted = missionCount == completedCount && missionCount > 0;

    // Check if this card should show the completion animation (for the tick)
    final showCompletionAnimation = _shouldShowCompletionAnimation(mission);
    // Check if this card just had all its missions completed
    final showFullCompletionCelebration =
        showCompletionAnimation && isAllCompleted;

    Widget cardContent = GestureDetector(
      onTapDown: isAllCompleted
          ? null
          : (_) {
              setState(() => _pressedCardIndex = index);
            },
      onTapUp: isAllCompleted
          ? null
          : (_) async {
              setState(() => _pressedCardIndex = null);
              // await SoundService().playButtonClick();
              await VibrationService().selectionVibration();
              _navigateToMissionSplash(mission);
            },
      onTapCancel: isAllCompleted
          ? null
          : () {
              setState(() => _pressedCardIndex = null);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isAllCompleted
                ? (showFullCompletionCelebration
                    ? Colors.green.withOpacity(0.05)
                    : Colors.grey[100])
                : (showCompletionAnimation
                    ? Colors.green.withOpacity(0.03)
                    : Colors.white),
            borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
            border: Border.all(
              color: isAllCompleted
                  ? (showFullCompletionCelebration
                      ? Colors.green
                      : Colors.grey[400]!)
                  : (showCompletionAnimation
                      ? Colors.green
                      : (isPressed
                          ? subjectColor
                          : subjectColor.withOpacity(0.3))),
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
                blurRadius:
                    showCompletionAnimation ? 20 : (isPressed ? 15 : 10),
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
                              borderRadius:
                                  BorderRadius.circular(kIsWeb ? 18 : 18.r),
                              child: CachedNetworkImage(
                                imageUrl: subjectLogo,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    ShimmerImagePlaceholder(
                                  width: kIsWeb ? 64 : 64.w,
                                  height: kIsWeb ? 64 : 64.h,
                                  borderRadius: kIsWeb ? 18 : 18.r,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  _getSubjectIcon(subjectName),
                                  color: subjectColor,
                                  size: kIsWeb ? 32 : 32.sp,
                                ),
                              ),
                            )
                          : Icon(
                              _getSubjectIcon(subjectName),
                              color: subjectColor,
                              size: kIsWeb ? 32 : 32.sp,
                            ),
                    ),
                    SizedBox(height: kIsWeb ? 14 : 14.h),
                    // Subject name
                    Text(
                      subjectName,
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
                    // Mission count
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
                                : Icons.card_giftcard,
                            size: kIsWeb ? 14 : 14.sp,
                            color: isAllCompleted ? Colors.green : subjectColor,
                          ),
                          SizedBox(width: kIsWeb ? 4 : 4.w),
                          Text(
                            isAllCompleted
                                ? 'Completed'
                                : '$missionCount mission${missionCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: kIsWeb ? 11 : 11.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isAllCompleted ? Colors.green : subjectColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Completion badge - animated when just completed (shows for any mission completion, not just all)
              if (isAllCompleted || showCompletionAnimation)
                Positioned(
                  top: kIsWeb ? 10 : 10.h,
                  right: kIsWeb ? 10 : 10.w,
                  child: showCompletionAnimation
                      ? AnimatedBuilder(
                          animation: _completionCheckController!,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  _completionCheckScaleAnimation?.value ?? 1.0,
                              child: Opacity(
                                opacity:
                                    _completionCheckOpacityAnimation?.value ??
                                        1.0,
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
              // Celebration shimmer overlay when just completed
              if (showCompletionAnimation)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.withOpacity(0.0),
                            Colors.green.withOpacity(0.05),
                            Colors.white.withOpacity(0.3),
                            Colors.green.withOpacity(0.05),
                            Colors.green.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                      ),
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
        particleCount: showFullCompletionCelebration
            ? 50
            : 30, // More confetti for full completion
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
      const Color(0xFF6989FF), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFFFB74D), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFFE91E63), // Pink
    ];
    return colors[index % colors.length];
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
    } else if (name.contains('biology') || name.contains('bio')) {
      return Icons.biotech;
    } else if (name.contains('art') || name.contains('draw')) {
      return Icons.palette;
    } else if (name.contains('music')) {
      return Icons.music_note;
    } else {
      return Icons.book;
    }
  }

  Future<void> _navigateToMissionSplash(Mission mission) async {
    // Connected zoom for diving into mission content
    final completedMissionId = await Navigator.push<String>(
      context,
      ConnectedPageTransitions.connectedZoom(
          page: MissionSplashScreen(mission: mission)),
    );

    // If a mission was completed, update local state and trigger celebration animation
    if (completedMissionId != null && mounted) {
      setState(() {
        _locallyCompletedMissionIds.add(completedMissionId);
      });

      // Trigger the completion celebration animation
      _triggerCompletionAnimation(completedMissionId);
    }

    // Refresh missions after returning from the splash/detail screen
    if (mounted) {
      context.read<MissionBloc>().add(RefreshMissions(
            month: widget.selectedDate.month,
            year: widget.selectedDate.year,
          ));
    }
  }

  // Check if a card should show the completion animation
  bool _shouldShowCompletionAnimation(Mission mission) {
    if (_justCompletedMissionId == null) return false;
    // Check if this mission or any mission for this subject was just completed
    return mission.id == _justCompletedMissionId ||
        mission.subjectId ==
            _getSubjectIdFromMissionId(_justCompletedMissionId!);
  }

  // Helper to get subject ID from mission ID
  String? _getSubjectIdFromMissionId(String missionId) {
    // Find the mission with this ID in our list
    for (final mission in widget.missions) {
      if (mission.id == missionId) {
        return mission.subjectId;
      }
    }
    return null;
  }
}
