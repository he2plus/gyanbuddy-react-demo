import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/mission_model.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../services/screen_security_service.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/confetti_celebration.dart';
import '../../widgets/shock_animation.dart';
import '../../services/mission_api_service.dart';
import '../../blocs/index.dart';
import '../../models/question_type.dart';

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

// Triangle painter for tooltip arrow
class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MissionQuestionScreen extends StatefulWidget {
  final Mission mission;
  final List<MissionQuestionData> questions;

  const MissionQuestionScreen({
    super.key,
    required this.mission,
    required this.questions,
  });

  @override
  State<MissionQuestionScreen> createState() => _MissionQuestionScreenState();
}

class _MissionQuestionScreenState extends State<MissionQuestionScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  Set<int> _selectedAnswerIndices = {}; // For multiple select MCQ
  String _shortAnswerText = ''; // For short answer questions
  final TextEditingController _shortAnswerController = TextEditingController();
  Map<int, int> _rearrangeOrder = {}; // For rearrange questions
  int _nextRearrangeOrder = 1;
  bool _showSuccess = false;
  bool _showIncorrect = false;
  bool _showTooltip = false;
  int _tries = 0;
  Set<int> _disabledOptionIndices = {};
  List<int> _shuffledIndices =
      []; // Shuffled option indices for randomized display
  final MissionApiService _missionApiService = MissionApiService();
  bool _isProcessingContinue = false;

  // Button press states
  bool _isWhyButtonPressed = false;
  bool _isContinueButtonPressed = false;
  bool _isTryAgainButtonPressed = false;
  bool _isCheckButtonPressed = false;

  // Animation states for celebration and shock effects
  bool _showConfetti = false;
  bool _showShock = false;

  // Animation controllers for staggered option animations
  late List<AnimationController> _optionControllers;
  late List<Animation<Offset>> _optionSlideAnimations;
  late List<Animation<double>> _optionFadeAnimations;

  // Animation controller for question text (slides from left to right)
  late AnimationController _questionController;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _questionFadeAnimation;

  int _previousQuestionIndex = -1;

  // Get current question
  MissionQuestionData get _currentQuestion {
    if (_currentQuestionIndex < widget.questions.length) {
      return widget.questions[_currentQuestionIndex];
    }
    return widget.questions.first;
  }

  int get _earnedXpForCurrentAttempt {
    if (_tries <= 1) return 2;
    if (_tries == 2) return 1;
    return 0;
  }

  // Get answers from current question
  List<String> get _answers {
    return _currentQuestion.options.map((option) => option.optionText).toList();
  }

  // Get correct answer indices
  List<int> get _correctAnswerIndices {
    return _currentQuestion.options
        .asMap()
        .entries
        .where((entry) => entry.value.isCorrect)
        .map((entry) => entry.key)
        .toList();
  }

  // Get correct answer index (for single select)
  int get _correctAnswerIndex {
    final correctOptionIndex =
        _currentQuestion.options.indexWhere((option) => option.isCorrect);
    return correctOptionIndex >= 0 ? correctOptionIndex : 0;
  }

  List<int> get _correctRearrangeOptionIndices {
    final indexedOptions = _currentQuestion.options.asMap().entries.toList()
      ..sort((a, b) {
        final orderCompare = a.value.order.compareTo(b.value.order);
        if (orderCompare != 0) return orderCompare;
        return a.key.compareTo(b.key);
      });
    return indexedOptions.map((entry) => entry.key).toList();
  }

  Map<int, int> get _correctRearrangeDisplayOrders {
    final displayOrders = <int, int>{};
    final correctIndices = _correctRearrangeOptionIndices;
    for (var i = 0; i < correctIndices.length; i++) {
      displayOrders[correctIndices[i]] = i + 1;
    }
    return displayOrders;
  }

  List<String> get _selectedRearrangeOptionIds {
    final sortedEntries = _rearrangeOrder.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sortedEntries
        .where((entry) => entry.key < _currentQuestion.options.length)
        .map((entry) => _currentQuestion.options[entry.key].id)
        .toList();
  }

  List<String> get _correctRearrangeOptionIds {
    return _correctRearrangeOptionIndices
        .map((index) => _currentQuestion.options[index].id)
        .toList();
  }

  bool get _isRearrangeAnswerCorrect {
    if (_rearrangeOrder.length != _currentQuestion.options.length) {
      return false;
    }
    return listEquals(
      _selectedRearrangeOptionIds,
      _correctRearrangeOptionIds,
    );
  }

  // Get question text
  String get _questionText {
    return _currentQuestion.questionText;
  }

  // Get hint (falls back to explanation if no hint available)
  String get _hint {
    // Prefer hint field, fallback to explanation, then default message
    if (_currentQuestion.hint != null && _currentQuestion.hint!.isNotEmpty) {
      return _currentQuestion.hint!;
    }
    return _currentQuestion.explanation ??
        'Answer the question correctly to proceed.';
  }

  /// Check if the current question has a hint available
  bool get _hasHint => _currentQuestion.hasHint;

  // Calculate progress
  double get _progress {
    return _currentQuestionIndex / widget.questions.length;
  }

  // Get current color based on state
  Color get _currentColor {
    if (_showSuccess) {
      return _hexToColor("31C85D");
    } else if (_showIncorrect) {
      return _hexToColor("EFD895");
    } else {
      return _hexToColor("6A8AFF");
    }
  }

  // Get bottom gradient colors
  List<Color> _getBottomGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
    ];
  }

  // Check if answer is selected
  bool get _hasAnswerSelected {
    if (_currentQuestion.isShortAnswer) {
      return _shortAnswerText.isNotEmpty;
    } else if (_currentQuestion.isMcqMultiple) {
      return _selectedAnswerIndices.isNotEmpty;
    } else if (_currentQuestion.isRearrange) {
      return _rearrangeOrder.length == _answers.length;
    } else {
      return _selectedAnswerIndex != null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Enable screen security to prevent screenshots and recordings
    ScreenSecurityService().enableSecureMode();
    print(
        '🔵 MissionQuestionScreen: Initialized with ${widget.questions.length} questions');

    // Initialize question animation controller (slides from left to right)
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOutCubic,
    ));

    _questionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOut,
    ));

    // Initialize option animation controllers (max 6 options)
    _optionControllers = List.generate(
        6,
        (index) => AnimationController(
              duration: const Duration(milliseconds: 400),
              vsync: this,
            ));

    _optionSlideAnimations = _optionControllers
        .map(
          (controller) =>
              Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutCubic,
          )),
        )
        .toList();

    _optionFadeAnimations = _optionControllers
        .map(
          (controller) =>
              Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeOut,
          )),
        )
        .toList();

    // Shuffle options for randomized display
    _shuffleOptions();

    // On web (CanvasKit), set controllers to completed state immediately
    // to avoid blank screen caused by FadeTransition starting at opacity 0
    if (kIsWeb) {
      _questionController.value = 1.0;
      for (var controller in _optionControllers) {
        controller.value = 1.0;
      }
    } else {
      _startOptionAnimations();
    }
  }

  void _startOptionAnimations() {
    // Play question whoosh sound for transition
    // SoundService().playQuestionWhoosh();

    // On web (CanvasKit), skip reset-and-animate to avoid blank content
    if (kIsWeb) {
      _questionController.value = 1.0;
      for (var controller in _optionControllers) {
        controller.value = 1.0;
      }
      return;
    }

    // Reset and start question animation (slides from left)
    _questionController.reset();
    _questionController.forward();

    // Reset all option controllers
    for (var controller in _optionControllers) {
      controller.reset();
    }

    // Start option animations with staggered delay (after question appears)
    final optionCount = _answers.length.clamp(0, 6);
    for (int i = 0; i < optionCount; i++) {
      Future.delayed(Duration(milliseconds: 200 + (100 * i)), () {
        if (mounted && i < _optionControllers.length) {
          _optionControllers[i].forward();
        }
      });
    }
  }

  // Shuffle option indices for randomized display order
  void _shuffleOptions() {
    final optionCount = _currentQuestion.options.length;
    _shuffledIndices = List.generate(optionCount, (index) => index);
    _shuffledIndices.shuffle(Random());
  }

  @override
  void dispose() {
    // Disable screen security when leaving the screen
    ScreenSecurityService().disableSecureMode();
    _shortAnswerController.dispose();
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _currentColor;
    final bottomGradientColors = _getBottomGradientColors(currentColor);
    final showGradient = _hasAnswerSelected || _showSuccess || _showIncorrect;

    // Check if question changed and restart animations
    final questionChanged = _previousQuestionIndex != _currentQuestionIndex;

    if (questionChanged) {
      _previousQuestionIndex = _currentQuestionIndex;
      // Schedule animation start after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startOptionAnimations();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: ConfettiCelebration(
        isPlaying: _showConfetti,
        particleCount: 60,
        child: ShockAnimation(
          isPlaying: _showShock,
          intensity: 1.2,
          onComplete: () {
            if (mounted) {
              setState(() {
                _showShock = false;
              });
            }
          },
          child: Stack(
            children: [
              // Bottom gradient
              if (showGradient)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: kIsWeb ? 200 : 0.25.sh,
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
              SafeArea(
                top: !kIsWeb,
                bottom: !kIsWeb,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Full-width header
                        _buildHeader(),
                        Divider(height: kIsWeb ? 1 : 1.h),
                        // Content constrained to 600px
                        Expanded(
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(
                                  maxWidth: kIsWeb ? 600 : double.infinity),
                              child: Column(
                                children: [
                                  // Question Area
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: kIsWeb ? 4 : 4.w),
                                      child: Stack(
                                        children: [
                                          // Hint button
                                          Positioned(
                                            top: kIsWeb ? 8 : 8.h,
                                            right: kIsWeb ? 16 : 16.w,
                                            child: IgnorePointer(
                                              ignoring: _tries == 0,
                                              child:
                                                  AnimationUtils.animatedButton(
                                                onPressed: () {
                                                  // Play hint usage sound
                                                  // SoundService().playHintUsage();
                                                  setState(() {
                                                    _showTooltip =
                                                        !_showTooltip;
                                                  });
                                                },
                                                child: Opacity(
                                                  opacity:
                                                      _tries == 0 ? 0.5 : 1.0,
                                                  child: Image.asset(
                                                    'assets/images/lamp.png',
                                                    width: kIsWeb ? 24 : 28.w,
                                                    height: kIsWeb ? 24 : 28.h,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        _showTooltip
                                                            ? Icons.lightbulb
                                                            : Icons
                                                                .lightbulb_outline,
                                                        color: _tries == 0
                                                            ? Colors.grey
                                                            : Colors.orange,
                                                        size:
                                                            kIsWeb ? 18 : 20.sp,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              SizedBox(
                                                  height: kIsWeb ? 40 : 44.h),

                                              // Chapter name badge
                                              if (_currentQuestion
                                                          .chapterName !=
                                                      null &&
                                                  _currentQuestion
                                                      .chapterName!.isNotEmpty)
                                                AnimatedBuilder(
                                                  animation:
                                                      _questionController,
                                                  builder: (context, child) {
                                                    return FadeTransition(
                                                      opacity:
                                                          _questionFadeAnimation,
                                                      child: SlideTransition(
                                                        position:
                                                            _questionSlideAnimation,
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: kIsWeb
                                                                ? 16
                                                                : 16.w,
                                                          ),
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal: kIsWeb
                                                                  ? 12
                                                                  : 14.w,
                                                              vertical: kIsWeb
                                                                  ? 6
                                                                  : 8.h,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: _hexToColor(widget
                                                                          .mission
                                                                          .subjectColor ??
                                                                      "6A8AFF")
                                                                  .withOpacity(
                                                                      0.15),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          kIsWeb
                                                                              ? 8
                                                                              : 10.r),
                                                              border:
                                                                  Border.all(
                                                                color: _hexToColor(widget
                                                                            .mission
                                                                            .subjectColor ??
                                                                        "6A8AFF")
                                                                    .withOpacity(
                                                                        0.3),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .menu_book_rounded,
                                                                  size: kIsWeb
                                                                      ? 14
                                                                      : 16.sp,
                                                                  color: _hexToColor(widget
                                                                          .mission
                                                                          .subjectColor ??
                                                                      "6A8AFF"),
                                                                ),
                                                                SizedBox(
                                                                    width: kIsWeb
                                                                        ? 6
                                                                        : 8.w),
                                                                Text(
                                                                  _currentQuestion
                                                                      .chapterName!,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: kIsWeb
                                                                        ? 12
                                                                        : 13.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: _hexToColor(widget
                                                                            .mission
                                                                            .subjectColor ??
                                                                        "6A8AFF"),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),

                                              if (_currentQuestion
                                                          .chapterName !=
                                                      null &&
                                                  _currentQuestion
                                                      .chapterName!.isNotEmpty)
                                                SizedBox(
                                                    height: kIsWeb ? 8 : 10.h),

                                              // Question type badge
                                              AnimatedBuilder(
                                                animation: _questionController,
                                                builder: (context, child) {
                                                  return FadeTransition(
                                                    opacity:
                                                        _questionFadeAnimation,
                                                    child: SlideTransition(
                                                      position:
                                                          _questionSlideAnimation,
                                                      child: Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: kIsWeb
                                                              ? 16
                                                              : 16.w,
                                                        ),
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: kIsWeb
                                                                ? 12
                                                                : 14.w,
                                                            vertical: kIsWeb
                                                                ? 6
                                                                : 8.h,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _currentColor
                                                                .withOpacity(
                                                                    0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(kIsWeb
                                                                        ? 8
                                                                        : 10.r),
                                                            border: Border.all(
                                                              color: _currentColor
                                                                  .withOpacity(
                                                                      0.3),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.quiz,
                                                                size: kIsWeb
                                                                    ? 14
                                                                    : 16.sp,
                                                                color:
                                                                    _currentColor,
                                                              ),
                                                              SizedBox(
                                                                  width: kIsWeb
                                                                      ? 6
                                                                      : 8.w),
                                                              Text(
                                                                QuestionType.fromString(
                                                                        _currentQuestion
                                                                            .questionType)
                                                                    .displayName,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: kIsWeb
                                                                      ? 12
                                                                      : 13.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      _currentColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                              SizedBox(
                                                  height: kIsWeb ? 8 : 10.h),

                                              // Question text with slide-in animation from left
                                              AnimatedBuilder(
                                                animation: _questionController,
                                                builder: (context, child) {
                                                  return FadeTransition(
                                                    opacity:
                                                        _questionFadeAnimation,
                                                    child: SlideTransition(
                                                      position:
                                                          _questionSlideAnimation,
                                                      child: Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: kIsWeb
                                                              ? 16
                                                              : 16.w,
                                                          vertical:
                                                              kIsWeb ? 8 : 8.h,
                                                        ),
                                                        child: Text(
                                                          _questionText,
                                                          style: TextStyle(
                                                            fontSize: kIsWeb
                                                                ? 16
                                                                : 18.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.black,
                                                            height: 1.4,
                                                            overflow:
                                                                TextOverflow
                                                                    .fade,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                              // Question Image
                                              if (_currentQuestion.image !=
                                                      null &&
                                                  _currentQuestion
                                                      .image!.isNotEmpty)
                                                AnimatedBuilder(
                                                  animation:
                                                      _questionController,
                                                  builder: (context, child) {
                                                    return FadeTransition(
                                                      opacity:
                                                          _questionFadeAnimation,
                                                      child: SlideTransition(
                                                        position:
                                                            _questionSlideAnimation,
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: kIsWeb
                                                                      ? 12
                                                                      : 12.h),
                                                          child:
                                                              _buildQuestionImage(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),

                                              SizedBox(
                                                  height: kIsWeb ? 16 : 16.h),

                                              // Answer Options
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          kIsWeb ? 12 : 12.w),
                                                  child: _currentQuestion
                                                          .isShortAnswer
                                                      ? _buildShortAnswerInput()
                                                      : _currentQuestion
                                                              .isRearrange
                                                          ? _buildRearrangeOptions()
                                                          : _buildAnswerOptions(),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Hint Tooltip - attached below the hint image
                                          if (_showTooltip)
                                            Positioned(
                                              top: kIsWeb ? 40 : 44.h,
                                              right: kIsWeb ? 4 : 4.w,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: kIsWeb
                                                      ? 280
                                                      : 1.sw * 0.75,
                                                  maxHeight:
                                                      kIsWeb ? 250 : 1.sh * 0.4,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    // Arrow pointer pointing to hint button
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          right: kIsWeb
                                                              ? 18
                                                              : 20.w),
                                                      child: CustomPaint(
                                                        size: Size(
                                                            kIsWeb ? 16 : 18.w,
                                                            kIsWeb ? 10 : 12.h),
                                                        painter:
                                                            _TrianglePainter(
                                                          color: Colors
                                                              .orange[100]!,
                                                          borderColor:
                                                              Colors.orange,
                                                        ),
                                                      ),
                                                    ),
                                                    // Main tooltip container
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                          kIsWeb ? 14 : 16.w),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.orange[100],
                                                        borderRadius:
                                                            BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  kIsWeb
                                                                      ? 12
                                                                      : 14.r),
                                                          topRight:
                                                              Radius.circular(
                                                                  kIsWeb
                                                                      ? 4
                                                                      : 6.r),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  kIsWeb
                                                                      ? 12
                                                                      : 14.r),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  kIsWeb
                                                                      ? 12
                                                                      : 14.r),
                                                        ),
                                                        border: Border.all(
                                                            color:
                                                                Colors.orange,
                                                            width: 1.5),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.15),
                                                            spreadRadius: 1,
                                                            blurRadius: kIsWeb
                                                                ? 10
                                                                : 12.r,
                                                            offset: Offset(
                                                                0,
                                                                kIsWeb
                                                                    ? 4
                                                                    : 6.h),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                '💡 Hint:',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: kIsWeb
                                                                      ? 14
                                                                      : 16.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                          .orange[
                                                                      800],
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _showTooltip =
                                                                        false;
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding: EdgeInsets
                                                                      .all(kIsWeb
                                                                          ? 4
                                                                          : 4.w),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .withOpacity(
                                                                            0.3),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child: Icon(
                                                                    Icons.close,
                                                                    size: kIsWeb
                                                                        ? 16
                                                                        : 18.sp,
                                                                    color: Colors
                                                                            .orange[
                                                                        800],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: kIsWeb
                                                                  ? 8
                                                                  : 10.h),
                                                          Flexible(
                                                            child: Text(
                                                              _hint,
                                                              style: TextStyle(
                                                                fontSize: kIsWeb
                                                                    ? 13
                                                                    : 14.sp,
                                                                color: Colors
                                                                    .black87,
                                                                height: 1.4,
                                                              ),
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .visible,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Bottom Button placeholder to reserve space
                                  SizedBox(height: kIsWeb ? 80 : 0.13.sh),
                                ],
                              ),
                            ),
                          ),
                        ), // closes Expanded
                      ], // closes Column children
                    ), // closes Column
                    // Full-width bottom button container
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: kIsWeb ? 80 : 0.13.sh,
                        decoration: BoxDecoration(
                          color: _currentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(kIsWeb ? 24 : 30.r),
                            topRight: Radius.circular(kIsWeb ? 24 : 30.r),
                          ),
                        ),
                        child: _buildBottomButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _hexToColor("FFFCFC"),
      padding: EdgeInsets.symmetric(
        vertical: kIsWeb ? 12 : 16.w,
        horizontal: kIsWeb ? 12 : 16.w,
      ),
      child: Row(
        children: [
          // Close Button
          AnimationUtils.animatedButton(
            onPressed: () async {
              await VibrationService().navigationVibration();
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(kIsWeb ? 6 : 8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.black,
                size: kIsWeb ? 18 : 20.sp,
              ),
            ),
          ),

          SizedBox(width: kIsWeb ? 12 : 16.w),

          // Progress Bar
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 10 : 10.w),
              child: AnimatedProgressBar(
                progress: _progress,
                height: kIsWeb ? 18 : 14.h,
                backgroundColor: Colors.grey[300]!,
                progressColor: Colors.green,
                duration: const Duration(milliseconds: 800),
                borderRadius: BorderRadius.circular(kIsWeb ? 8 : 6.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: kIsWeb ? 220 : 300.h,
        minHeight: kIsWeb ? 120 : 150.h,
      ),
      margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 16 : 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: kIsWeb ? 4 : 4.r,
            offset: Offset(0, kIsWeb ? 2 : 2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
        child: Image.network(
          _currentQuestion.image!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: kIsWeb ? 160 : 200.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                    SizedBox(height: kIsWeb ? 8 : 8.h),
                    Text(
                      'Loading image...',
                      style: TextStyle(
                        fontSize: kIsWeb ? 11 : 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: kIsWeb ? 160 : 200.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: kIsWeb ? 40 : 48.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: kIsWeb ? 8 : 8.h),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      fontSize: kIsWeb ? 11 : 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    final isMultipleSelect = _currentQuestion.isMcqMultiple;
    // Show correct answer after 2 wrong attempts
    final showCorrectAnswer = _showIncorrect && _tries >= 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_shuffledIndices.length, (displayIndex) {
        // Get the actual option index from shuffled indices
        final actualIndex = _shuffledIndices[displayIndex];
        final isSelected = isMultipleSelect
            ? _selectedAnswerIndices.contains(actualIndex)
            : _selectedAnswerIndex == actualIndex;
        final isCorrect = _correctAnswerIndices.contains(actualIndex);
        final isDisabled = _disabledOptionIndices.contains(actualIndex);
        // Highlight correct answer after 2 wrong attempts
        final highlightAsCorrect =
            (showCorrectAnswer || _showSuccess) && isCorrect;

        // Use staggered slide animation for each option
        Widget optionWidget = AnimationUtils.animatedButton(
          onPressed: () {
            // Block selection when showing incorrect - user must click Continue first
            if (isDisabled || _showIncorrect) return;
            // Handle async operations without making the callback async
            // SoundService().playAnswerSelect().then((_) {
            setState(() {
              if (isMultipleSelect) {
                // Toggle selection for multiple select
                if (_selectedAnswerIndices.contains(actualIndex)) {
                  _selectedAnswerIndices.remove(actualIndex);
                } else {
                  _selectedAnswerIndices.add(actualIndex);
                }
              } else {
                // Single select - store the actual index
                _selectedAnswerIndex = actualIndex;
              }
            });
            // });
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: kIsWeb ? 10 : 12.h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 16 : 16.w,
                vertical: kIsWeb ? 14 : 16.h,
              ),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey[100]
                    : (highlightAsCorrect
                        ? Colors.green[50]
                        : (isSelected ? Colors.blue[50] : Colors.white)),
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 14.r),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey[400]!
                      : (highlightAsCorrect
                          ? Colors.green
                          : (isSelected ? Colors.blue : Colors.grey[300]!)),
                  width: (isSelected || highlightAsCorrect) ? 2 : 1,
                ),
                boxShadow: (isSelected || highlightAsCorrect) && !isDisabled
                    ? [
                        BoxShadow(
                          color:
                              (highlightAsCorrect ? Colors.green : Colors.blue)
                                  .withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Option letter indicator
                  Container(
                    width: kIsWeb ? 28 : 32.w,
                    height: kIsWeb ? 28 : 32.h,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey[300]
                          : (highlightAsCorrect
                              ? Colors.green
                              : (isSelected ? Colors.blue : Colors.grey[200])),
                      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                    ),
                    child: Center(
                      child: isDisabled
                          ? Icon(
                              Icons.block,
                              color: Colors.white,
                              size: kIsWeb ? 14 : 16.sp,
                            )
                          : (highlightAsCorrect
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: kIsWeb ? 16 : 18.sp,
                                )
                              : (isMultipleSelect && isSelected && !_showSuccess
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: kIsWeb ? 16 : 18.sp,
                                    )
                                  : Text(
                                      String.fromCharCode(
                                          65 + displayIndex), // A, B, C, D...
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 14 : 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                    ))),
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 12 : 14.w),
                  // Answer Text
                  Expanded(
                    child: Text(
                      _answers[actualIndex],
                      style: TextStyle(
                        fontSize: kIsWeb ? 15 : 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDisabled
                            ? Colors.grey[500]
                            : (highlightAsCorrect
                                ? Colors.green[700]
                                : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Wrap with staggered animation if controller exists
        if (displayIndex < _optionControllers.length) {
          return AnimatedBuilder(
            animation: _optionControllers[displayIndex],
            builder: (context, child) {
              return FadeTransition(
                opacity: _optionFadeAnimations[displayIndex],
                child: SlideTransition(
                  position: _optionSlideAnimations[displayIndex],
                  child: optionWidget,
                ),
              );
            },
          );
        }
        return optionWidget;
      }),
    );
  }

  Widget _buildShortAnswerInput() {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 16 : 16.w),
      child: TextField(
        controller: _shortAnswerController,
        enabled: !_showIncorrect,
        onChanged: (value) {
          setState(() {
            _shortAnswerText = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Type your answer here...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kIsWeb ? 10 : 12.r),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 14 : 16.w, vertical: kIsWeb ? 14 : 16.h),
        ),
        style: TextStyle(
          fontSize: kIsWeb ? 14 : 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildRearrangeOptions() {
    // Show correct order after 2 wrong attempts
    final showCorrectOrder = _showIncorrect && _tries >= 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_shuffledIndices.length, (displayIndex) {
        // Get the actual option index from shuffled indices
        final actualIndex = _shuffledIndices[displayIndex];
        final userOrder = _rearrangeOrder[actualIndex];
        final isSelected = userOrder != null;
        final isDisabled = _disabledOptionIndices.contains(actualIndex);
        final correctOrder = _correctRearrangeDisplayOrders[actualIndex];
        final highlightCorrect = showCorrectOrder || _showSuccess;

        Widget optionWidget = AnimationUtils.animatedButton(
          onPressed: () {
            // Block selection when showing incorrect - user must click Continue first
            if (isDisabled || _showIncorrect) return;
            // Handle async operations without making the callback async
            // SoundService().playAnswerSelect().then((_) {
            setState(() {
              if (_rearrangeOrder.containsKey(actualIndex)) {
                // If already selected, remove it and reorder remaining
                final removedOrder = _rearrangeOrder[actualIndex]!;
                _rearrangeOrder.remove(actualIndex);
                // Decrement orders greater than the removed one
                _rearrangeOrder.updateAll((key, value) {
                  if (value > removedOrder) {
                    return value - 1;
                  }
                  return value;
                });
                _nextRearrangeOrder--;
              } else {
                // Add new selection with next order
                _rearrangeOrder[actualIndex] = _nextRearrangeOrder;
                _nextRearrangeOrder++;
              }
            });
            // });
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: kIsWeb ? 10 : 12.h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 16 : 16.w,
                vertical: kIsWeb ? 14 : 16.h,
              ),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey[100]
                    : (highlightCorrect
                        ? Colors.green[50]
                        : (isSelected ? Colors.blue[50] : Colors.white)),
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 14.r),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey[400]!
                      : (highlightCorrect
                          ? Colors.green
                          : (isSelected ? Colors.blue : Colors.grey[300]!)),
                  width: (isSelected || highlightCorrect) ? 2 : 1,
                ),
                boxShadow: (isSelected || highlightCorrect) && !isDisabled
                    ? [
                        BoxShadow(
                          color: (highlightCorrect ? Colors.green : Colors.blue)
                              .withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Order number or indicator
                  Container(
                    width: kIsWeb ? 28 : 32.w,
                    height: kIsWeb ? 28 : 32.h,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey[300]
                          : (highlightCorrect
                              ? Colors.green
                              : (isSelected ? Colors.blue : Colors.grey[200])),
                      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                    ),
                    child: Center(
                      child: isDisabled
                          ? Icon(
                              Icons.block,
                              color: Colors.white,
                              size: kIsWeb ? 14 : 16.sp,
                            )
                          : (highlightCorrect
                              ? Text(
                                  '${correctOrder ?? ""}',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 14 : 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : (isSelected
                                  ? Text(
                                      '$userOrder',
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 14 : 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.drag_indicator,
                                      color: Colors.grey[500],
                                      size: kIsWeb ? 16 : 18.sp,
                                    ))),
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 12 : 14.w),
                  // Answer Text
                  Expanded(
                    child: Text(
                      _answers[actualIndex],
                      style: TextStyle(
                        fontSize: kIsWeb ? 15 : 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDisabled
                            ? Colors.grey[500]
                            : (highlightCorrect
                                ? Colors.green[700]
                                : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Wrap with staggered animation if controller exists
        if (displayIndex < _optionControllers.length) {
          return AnimatedBuilder(
            animation: _optionControllers[displayIndex],
            builder: (context, child) {
              return FadeTransition(
                opacity: _optionFadeAnimations[displayIndex],
                child: SlideTransition(
                  position: _optionSlideAnimations[displayIndex],
                  child: optionWidget,
                ),
              );
            },
          );
        }
        return optionWidget;
      }),
    );
  }

  Widget _buildBottomButton() {
    if (_showSuccess) {
      return _buildSuccessButtons();
    }
    if (_showIncorrect) {
      return _buildIncorrectButtons();
    }
    return _buildCheckButton();
  }

  Widget _buildSuccessButtons() {
    return TweenAnimationBuilder<Offset>(
      key: const ValueKey('success_slide'),
      tween: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, offset, child) {
        return FractionalTranslation(translation: offset, child: child);
      },
      child: Container(
        color: const Color(0xFFE8F5E9),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: kIsWeb ? 700 : double.infinity),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: kIsWeb ? 2 : 12.h),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Celebration icon
                        TweenAnimationBuilder<double>(
                          key: const ValueKey('celebrate_bounce'),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: Image.asset(
                            'assets/images/celebrate.png',
                            width: kIsWeb ? 28 : 32.w,
                            height: kIsWeb ? 28 : 32.h,
                            fit: BoxFit.fitHeight,
                            errorBuilder: (context, error, stackTrace) => Text(
                                '🎉',
                                style:
                                    TextStyle(fontSize: kIsWeb ? 24 : 28.sp)),
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 8 : 10.w),
                        Text(
                          'Correct!',
                          style: TextStyle(
                            fontSize: kIsWeb ? 16 : 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 15 : 10.w),
                        // XP badge
                        TweenAnimationBuilder<double>(
                          key: const ValueKey('xp_badge_bounce'),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity:
                                    value < 0 ? 0 : (value > 1 ? 1 : value),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: kIsWeb ? 8 : 10.w,
                                    vertical: kIsWeb ? 4 : 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(
                                        kIsWeb ? 12 : 14.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '+$_earnedXpForCurrentAttempt XP',
                                    style: TextStyle(
                                      fontSize: kIsWeb ? 12 : 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: kIsWeb ? 40 : 16.w),
                        // Why? button
                        GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _isWhyButtonPressed = true),
                          onTapUp: (_) async {
                            setState(() => _isWhyButtonPressed = false);
                            await VibrationService().lightVibration();
                            _showExplanationModal();
                          },
                          onTapCancel: () =>
                              setState(() => _isWhyButtonPressed = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,
                            height: kIsWeb ? 44 : 53.h,
                            width: kIsWeb ? 90 : 113.w,
                            decoration: BoxDecoration(
                              color: _hexToColor("D9D9D9"),
                              borderRadius:
                                  BorderRadius.circular(kIsWeb ? 22 : 28.r),
                              border: Border(
                                bottom: BorderSide(
                                  color: _hexToColor("BFBFBF"),
                                  width: _isWhyButtonPressed ? 1 : 4,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Why?',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 16 : 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 12 : 16.w),
                        // Continue button
                        GestureDetector(
                          onTapDown: (_) {
                            if (!_showSuccess || _isProcessingContinue) return;
                            setState(() => _isContinueButtonPressed = true);
                          },
                          onTapUp: (_) async {
                            if (_isProcessingContinue) return;
                            _isProcessingContinue = true;
                            setState(() => _isContinueButtonPressed = false);
                            VibrationService().successVibration();
                            await _trackAnswer();
                            _moveToNextQuestion();
                          },
                          onTapCancel: () =>
                              setState(() => _isContinueButtonPressed = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,
                            height: kIsWeb ? 44 : 53.h,
                            width: kIsWeb ? 180 : 226.w,
                            decoration: BoxDecoration(
                              color: _hexToColor("29CC57"),
                              borderRadius:
                                  BorderRadius.circular(kIsWeb ? 22 : 28.r),
                              border: Border(
                                bottom: BorderSide(
                                  color: _hexToColor("1F9940"),
                                  width: _isContinueButtonPressed ? 1 : 4,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 16 : 20.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncorrectButtons() {
    final shouldMoveToNext = _tries >= 2;

    return TweenAnimationBuilder<Offset>(
      key: const ValueKey('incorrect_slide'),
      tween: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, offset, child) {
        return FractionalTranslation(translation: offset, child: child);
      },
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: kIsWeb ? 700 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 24 : 20.w,
              vertical: kIsWeb ? 12 : 12.h,
            ),
            child: Row(
              children: [
                // Why? Button
                GestureDetector(
                  onTapDown: (_) => setState(() => _isWhyButtonPressed = true),
                  onTapUp: (_) async {
                    setState(() => _isWhyButtonPressed = false);
                    await VibrationService().lightVibration();
                    _showExplanationModal();
                  },
                  onTapCancel: () =>
                      setState(() => _isWhyButtonPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    height: kIsWeb ? 44 : 53.h,
                    width: kIsWeb ? 90 : 113.w,
                    decoration: BoxDecoration(
                      color: _hexToColor("D9D9D9"),
                      borderRadius: BorderRadius.circular(kIsWeb ? 22 : 28.r),
                      border: Border(
                        bottom: BorderSide(
                          color: _hexToColor("BFBFBF"),
                          width: _isWhyButtonPressed ? 1 : 4,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Why?',
                        style: TextStyle(
                          fontSize: kIsWeb ? 16 : 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: kIsWeb ? 12 : 16.w),
                // Continue Button
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) =>
                        setState(() => _isTryAgainButtonPressed = true),
                    onTapUp: (_) async {
                      setState(() => _isTryAgainButtonPressed = false);
                      await VibrationService().lightVibration();
                      if (shouldMoveToNext) {
                        await _trackAnswer();
                        _moveToNextQuestion();
                      } else {
                        setState(() {
                          _showIncorrect = false;
                          _selectedAnswerIndex = null;
                          _selectedAnswerIndices.clear();
                          _shortAnswerText = '';
                          _shortAnswerController.clear();
                          _rearrangeOrder = {};
                          _nextRearrangeOrder = 1;
                        });
                      }
                    },
                    onTapCancel: () =>
                        setState(() => _isTryAgainButtonPressed = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      height: kIsWeb ? 44 : 53.h,
                      decoration: BoxDecoration(
                        color: shouldMoveToNext
                            ? _hexToColor("2D2D2D")
                            : _hexToColor("E5E5E5"),
                        borderRadius: BorderRadius.circular(kIsWeb ? 22 : 28.r),
                        border: Border(
                          bottom: BorderSide(
                            color: shouldMoveToNext
                                ? Colors.black
                                : _hexToColor("CCCCCC"),
                            width: _isTryAgainButtonPressed ? 1 : 4,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: kIsWeb ? 16 : 20.sp,
                            fontWeight: FontWeight.w500,
                            color: shouldMoveToNext
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: kIsWeb ? 12 : 16.w),
                // Incorrect label
                TweenAnimationBuilder<double>(
                  key: const ValueKey('incorrect_bounce'),
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/incorrect_icon.png',
                        width: kIsWeb ? 28 : 32.w,
                        height: kIsWeb ? 28 : 32.h,
                        fit: BoxFit.fitHeight,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.close,
                          color: Colors.red,
                          size: kIsWeb ? 18 : 20.sp,
                        ),
                      ),
                      SizedBox(width: kIsWeb ? 6 : 8.w),
                      Text(
                        'Incorrect',
                        style: TextStyle(
                          fontSize: kIsWeb ? 16 : 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckButton() {
    final hasAnswer = _hasAnswerSelected;

    if (!hasAnswer) {
      return Container(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() {
              _isCheckButtonPressed = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              _isCheckButtonPressed = false;
            });
          },
          onTapCancel: () {
            setState(() {
              _isCheckButtonPressed = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            width: kIsWeb ? 320 : 386.w,
            height: kIsWeb ? 44 : 53.h,
            margin: EdgeInsets.only(bottom: kIsWeb ? 16 : 20.h),
            decoration: BoxDecoration(
              color: _hexToColor("F2F2F2"),
              borderRadius: BorderRadius.circular(kIsWeb ? 22 : 28.r),
            ),
            child: Center(
              child: Text(
                'Check',
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 20.sp,
                  fontWeight: FontWeight.w500,
                  color: _hexToColor("999999"),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isCheckButtonPressed = true;
          });
        },
        onTapUp: (_) async {
          setState(() {
            _isCheckButtonPressed = false;
          });

          FocusScope.of(context).unfocus();
          await VibrationService().lightVibration();

          setState(() {
            _tries++;
          });

          bool isCorrect = _checkAnswer();

          if (isCorrect) {
            setState(() {
              _showSuccess = true;
              _showConfetti = true;
            });
            // Reset confetti after animation
            Future.delayed(const Duration(milliseconds: 1600), () {
              if (mounted) setState(() => _showConfetti = false);
            });
            // await SoundService().playCorrectAnswer();
          } else {
            if (_tries < 2 && _selectedAnswerIndex != null) {
              // On first wrong attempt, just show hint without incorrect UI
              setState(() {
                _showShock = true;
                _showTooltip = true; // Auto-show hint on wrong answer
                _disabledOptionIndices.add(_selectedAnswerIndex!);
                _selectedAnswerIndex =
                    null; // Clear selection so user can pick again
              });
            } else {
              // On second wrong attempt, show incorrect UI
              setState(() {
                _showIncorrect = true;
                _showShock = true;
                _showTooltip = true; // Auto-show hint on wrong answer
              });
            }
            // await SoundService().playIncorrectAnswer();
          }
        },
        onTapCancel: () {
          setState(() {
            _isCheckButtonPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          width: kIsWeb ? 320 : 386.w,
          height: kIsWeb ? 44 : 53.h,
          margin: EdgeInsets.only(bottom: kIsWeb ? 16 : 20.h),
          decoration: BoxDecoration(
            color: _hexToColor("2D2D2D"),
            borderRadius: BorderRadius.circular(kIsWeb ? 22 : 28.r),
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: _isCheckButtonPressed ? 1 : 4,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Check',
              style: TextStyle(
                fontSize: kIsWeb ? 16 : 20.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _checkAnswer() {
    print(
        '🔵 Mission Quiz: Checking answer, questionType: ${_currentQuestion.questionType}, isShortAnswer: ${_currentQuestion.isShortAnswer}');

    if (_currentQuestion.isShortAnswer) {
      // For short answer, always consider it correct since we can't validate locally
      // The actual validation happens on the backend via API
      print(
          '🔵 Mission Quiz: Short answer detected, returning true (always correct)');
      return true;
    } else if (_currentQuestion.isMcqMultiple) {
      final selectedCorrect = _selectedAnswerIndices
          .where((index) => _correctAnswerIndices.contains(index))
          .length;
      final allCorrectSelected =
          selectedCorrect == _correctAnswerIndices.length;
      final allSelectedCorrect =
          _selectedAnswerIndices.length == _correctAnswerIndices.length;
      return allCorrectSelected && allSelectedCorrect;
    } else if (_currentQuestion.isRearrange) {
      return _isRearrangeAnswerCorrect;
    } else {
      return _selectedAnswerIndex == _correctAnswerIndex;
    }
  }

  Future<void> _trackAnswer() async {
    try {
      if (_currentQuestion.isShortAnswer) {
        // For short answer, send the text answer
        if (_shortAnswerText.isNotEmpty) {
          await _missionApiService.checkMissionAnswer(
            missionId: widget.mission.id,
            questionId: _currentQuestion.id,
            answerId: _shortAnswerText, // Send text as answer
            tries: _tries,
            isCorrect: _showSuccess,
          );
        }
      } else {
        final selectedAnswerId = _getSelectedAnswerId();
        if (selectedAnswerId != null) {
          await _missionApiService.checkMissionAnswer(
            missionId: widget.mission.id,
            questionId: _currentQuestion.id,
            answerId: selectedAnswerId,
            tries: _tries,
            isCorrect: _showSuccess,
          );
        }
      }
    } catch (e) {
      print('🔵 Mission Quiz: Error tracking answer: $e');
    }
  }

  void _moveToNextQuestion() {
    final isLastQuestion = _currentQuestionIndex >= widget.questions.length - 1;

    if (isLastQuestion) {
      // Complete mission
      print('🔵 MissionQuestionScreen: All questions completed');
      context.read<MissionBloc>().add(CompleteMission(widget.mission.id));
      context.read<MissionBloc>().add(RefreshMissions(
            month: widget.mission.missionDate.month,
            year: widget.mission.missionDate.year,
          ));

      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Congratulations! Mission completed successfully! 🎉',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          // Pass the completed mission ID back to the previous screen
          Navigator.pop(context, widget.mission.id);
        }
      });
    } else {
      // Move to next question
      print(
          '🔵 MissionQuestionScreen: Moving to question ${_currentQuestionIndex + 2}/${widget.questions.length}');
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _selectedAnswerIndices.clear();
        _shortAnswerText = '';
        _shortAnswerController.clear();
        _rearrangeOrder = {};
        _nextRearrangeOrder = 1;
        _showSuccess = false;
        _showIncorrect = false;
        _showTooltip = false;
        _tries = 0;
        _disabledOptionIndices.clear();
      });
      // Shuffle options for the new question
      _shuffleOptions();
      _isProcessingContinue = false;
    }
  }

  String? _getSelectedAnswerId() {
    if (_currentQuestion.isMcqMultiple) {
      // For MCQ multiple, return comma-separated list of selected option IDs
      if (_selectedAnswerIndices.isNotEmpty) {
        return _selectedAnswerIndices
            .where((index) => index < _currentQuestion.options.length)
            .map((index) => _currentQuestion.options[index].id)
            .join(',');
      }
    } else if (_currentQuestion.isRearrange) {
      // For rearrange, return the user's order as comma-separated option IDs
      final selectedIds = _selectedRearrangeOptionIds;
      if (selectedIds.isNotEmpty) {
        return selectedIds.join(',');
      }
    } else if (_selectedAnswerIndex != null &&
        _selectedAnswerIndex! < _currentQuestion.options.length) {
      // For MCQ single
      return _currentQuestion.options[_selectedAnswerIndex!].id;
    }
    return null;
  }

  // Show explanation in a bottom modal sheet
  void _showExplanationModal() {
    final explanation = _currentQuestion.explanation ??
        'Answer the question correctly to proceed.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: kIsWeb ? 400 : 0.6.sh,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(kIsWeb ? 20 : 24.r),
              topRight: Radius.circular(kIsWeb ? 20 : 24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: kIsWeb ? 12 : 12.h),
                width: kIsWeb ? 40 : 40.w,
                height: kIsWeb ? 4 : 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(kIsWeb ? 2 : 2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(kIsWeb ? 16 : 20.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(kIsWeb ? 8 : 10.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: Colors.orange[700],
                        size: kIsWeb ? 20 : 24.sp,
                      ),
                    ),
                    SizedBox(width: kIsWeb ? 12 : 14.w),
                    Text(
                      'Explanation',
                      style: TextStyle(
                        fontSize: kIsWeb ? 18 : 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(kIsWeb ? 6 : 8.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: kIsWeb ? 18 : 20.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              // Explanation content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(kIsWeb ? 16 : 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        explanation,
                        style: TextStyle(
                          fontSize: kIsWeb ? 15 : 16.sp,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: kIsWeb ? 20 : 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
