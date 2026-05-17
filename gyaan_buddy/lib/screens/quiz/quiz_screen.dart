import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../services/screen_security_service.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/vibration_button.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/confetti_celebration.dart';
import '../../widgets/shock_animation.dart';
import '../../models/subject_model.dart';
import '../../models/module_model.dart';
import '../../models/module_chapter_model.dart';
import '../../models/module_content_model.dart';
import '../../models/module_questions_response.dart';
import '../../models/question_model.dart';
import '../../models/module_status.dart';
import '../../services/cache_data_service.dart';
import '../../services/module_content_api_service.dart';
import '../../blocs/module_chapter/module_chapter_bloc.dart';
import '../../blocs/subject/subject_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../leaderboard/module_leaderboard_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../home/home_screen.dart';
import '../../widgets/dashboard/dashboard_content.dart';

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

class QuizScreen extends StatefulWidget {
  final Subject subject;
  final Module module;
  final ModuleChapter chapter;
  final List<Question> questions;
  final ModuleContentItem? content; // Keep for backward compatibility
  final VoidCallback? onQuizCompleted; // Callback when quiz is completed

  const QuizScreen({
    super.key,
    required this.subject,
    required this.module,
    required this.chapter,
    required this.questions,
    this.content,
    this.onQuizCompleted,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex; // For single select MCQ
  Set<int> _selectedAnswerIndices = {}; // For multiple select MCQ
  String _shortAnswerText = ''; // For short answer questions
  final TextEditingController _shortAnswerController = TextEditingController();
  Map<int, int> _rearrangeOrder =
      {}; // For rearrange questions: optionIndex -> userOrder (1-based)
  int _nextRearrangeOrder = 1; // Next order number to assign
  bool _showSuccess = false;
  bool _showIncorrect = false;
  bool _showTooltip = false;
  int _tries = 0; // Track number of attempts
  Set<int> _disabledOptionIndices = {}; // Track disabled (wrong) options
  List<int> _shuffledIndices =
      []; // Shuffled option indices for randomized display
  final ModuleContentApiService _apiService = ModuleContentApiService();
  bool _isSeeAnswerPressed = false; // Track See Answer button press state
  bool _isWhyButtonPressed = false; // Track Why button press state
  bool _isCheckButtonPressed = false; // Track Check button press state
  bool _isContinueButtonPressed = false; // Track Continue button press state
  bool _isTryAgainButtonPressed = false; // Track Try Again button press state
  bool _isProcessingContinue = false; // Debounce flag for continue button

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
  bool _previousIsShowingHots = false;
  int _previousHotsIndex = -1;

  // HOTS Questions state
  List<Question> _hotsQuestions = [];
  int _hotsIndex = -1;
  bool _isShowingHots = false;
  bool _isLoadingHots = false;

  // Get current question from the list (regular or HOTS)
  Question get _currentQuestion {
    if (_isShowingHots) {
      if (_hotsIndex < _hotsQuestions.length) {
        return _hotsQuestions[_hotsIndex];
      }
      return _hotsQuestions.isNotEmpty
          ? _hotsQuestions.first
          : widget.questions.first;
    }
    if (_currentQuestionIndex < widget.questions.length) {
      return widget.questions[_currentQuestionIndex];
    }
    return widget.questions.first; // Fallback to first question
  }

  int get _earnedXpForCurrentAttempt {
    if (_tries <= 1) return 2;
    if (_tries == 2) return 1;
    return 0;
  }

  // Get question data from current question
  List<String> get _answers {
    return _currentQuestion.options.map((option) => option.optionText).toList();
  }

  // Get correct answer indices from current question (for multiple select)
  List<int> get _correctAnswerIndices {
    return _currentQuestion.options
        .asMap()
        .entries
        .where((entry) => entry.value.isCorrect)
        .map((entry) => entry.key)
        .toList();
  }

  // Get correct answer index from current question (for single select)
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

  // Get question text from current question
  String get _questionText {
    return _currentQuestion.questionText;
  }

  // Get explanation from current question
  String get _explanation {
    return _currentQuestion.explanation ??
        'Answer the question correctly to proceed.';
  }

  // Get hint from current question (falls back to explanation if no hint)
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

  // Calculate progress based on current question and total questions
  double get _progress {
    if (_isShowingHots) {
      // When showing HOTS, progress bar is always full for regular questions
      return 1.0;
    }
    // Start at zero, fill as questions are completed
    return _currentQuestionIndex / widget.questions.length;
  }

  bool _shouldRefreshXpDataAfterCurrentAnswer(bool isLastRegularQuestion) {
    if (_isShowingHots) {
      return _hotsIndex >= _hotsQuestions.length - 1;
    }
    return isLastRegularQuestion &&
        !(widget.chapter.hasHots && _hotsQuestions.isNotEmpty);
  }

  void _refreshXpDataAfterQuizCompletion(UserBloc userBloc) {
    Future.microtask(() async {
      try {
        await CacheDataService.instance.initialize();
        await Future.wait([
          CacheDataService.instance.invalidateUserCache(),
          CacheDataService.instance.invalidateLeaderboardCache(),
        ]);
        if (!userBloc.isClosed) {
          userBloc.add(
            const LoadLeaderboard(
              limit: 10,
              grade: null,
              forceRefresh: true,
            ),
          );
        }
      } catch (e) {
        print('🔵 Quiz: Error refreshing XP data after completion: $e');
      }
    });
  }

  // Get current color based on quiz state
  Color get _currentColor {
    if (_showSuccess) {
      return _hexToColor("31C85D");
    } else if (_showIncorrect) {
      return _hexToColor("FFF8DC");
    } else {
      return _hexToColor(widget.subject.color);
    }
  }

  // Helper function to create bottom gradient colors
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
    // Enable screen security to prevent screenshots and recordings
    ScreenSecurityService().enableSecureMode();
    print(
        '🔵 QuizScreen: Initialized with ${widget.questions.length} questions');

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

    // Find the index of currentQuestionId if it exists
    final currentQuestionId = widget.chapter.currentQuestionId;
    // if (currentQuestionId != null && currentQuestionId.isNotEmpty) {
    if (false) {
      final startIndex = widget.questions.indexWhere(
        (question) => question.id == currentQuestionId,
      );

      if (startIndex != -1) {
        _currentQuestionIndex = startIndex + 1;
        print('🔵 QuizScreen: Found currentQuestionId at index $startIndex');
      } else {
        print(
            '🔵 QuizScreen: currentQuestionId ($currentQuestionId) not found, starting from beginning');
        _currentQuestionIndex = 0;
      }
    } else {
      print('🔵 QuizScreen: No currentQuestionId, starting from beginning');
      _currentQuestionIndex = 0;
    }

    // Shuffle options for randomized display
    _shuffleOptions();

    // Start initial option animations
    _startOptionAnimations();

    // Fetch HOTS questions if chapter has HOTS
    if (widget.chapter.hasHots) {
      _fetchHotsQuestions();
    }
  }

  void _startOptionAnimations() {
    // Play question whoosh sound for transition
    // SoundService().playQuestionWhoosh();

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

  // Fetch HOTS questions from API
  Future<void> _fetchHotsQuestions() async {
    if (_isLoadingHots) return;

    if (!mounted) return;
    setState(() {
      _isLoadingHots = true;
    });

    try {
      print(
          '🔵 QuizScreen: Fetching HOTS questions for chapter ${widget.chapter.id}');
      final result = await _apiService.getHotsQuestions(widget.chapter.id);

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final hotsData = result['data'] as List;
        final questions = hotsData
            .map((json) => Question.fromJson(json as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _hotsQuestions = questions;
            _isLoadingHots = false;
          });
        }

        print('🔵 QuizScreen: Loaded ${_hotsQuestions.length} HOTS questions');
      } else {
        print(
            '🔵 QuizScreen: Failed to load HOTS questions: ${result['message']}');
        if (mounted) {
          setState(() {
            _isLoadingHots = false;
          });
        }
      }
    } catch (e) {
      print('🔵 QuizScreen: Error fetching HOTS questions: $e');
      if (mounted) {
        setState(() {
          _isLoadingHots = false;
        });
      }
    }
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

  // Helper to check if an answer is selected
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
  Widget build(BuildContext context) {
    final currentColor = _currentColor;
    final bottomGradientColors = _getBottomGradientColors(currentColor);

    // Show gradient only when an answer is selected or showing result
    final showGradient = _hasAnswerSelected || _showSuccess || _showIncorrect;

    // Check if question changed and restart animations
    final questionChanged = _previousQuestionIndex != _currentQuestionIndex ||
        _previousIsShowingHots != _isShowingHots ||
        _previousHotsIndex != _hotsIndex;

    if (questionChanged) {
      _previousQuestionIndex = _currentQuestionIndex;
      _previousIsShowingHots = _isShowingHots;
      _previousHotsIndex = _hotsIndex;
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
              // Bottom gradient (1/4 of screen) - only show when answer selected or showing result
              SafeArea(
                top: !kIsWeb,
                bottom: !kIsWeb,
                child: AnimatedScreenLayout(
                  appBar: Column(
                    children: [
                      _buildHeader(),
                      Divider(height: kIsWeb ? 1 : 1.h),
                    ],
                  ),
                  body: Column(
                    children: [
                      // Question Area (constrained width)
                      Expanded(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(
                                maxWidth: kIsWeb ? 700 : double.infinity),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: kIsWeb ? 24 : 4.w),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: kIsWeb ? 8 : 8.h,
                                    right: kIsWeb ? 52 : 52.w,
                                    child: GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Question reported'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.flag_outlined,
                                        size: kIsWeb ? 20 : 24.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: kIsWeb ? 8 : 8.h,
                                    right: kIsWeb ? 16 : 16.w,
                                    child: IgnorePointer(
                                      ignoring: _tries == 0,
                                      child: AnimationUtils.animatedButton(
                                        onPressed: () {
                                          // Play hint usage sound
                                          // SoundService().playHintUsage();
                                          setState(() {
                                            _showTooltip = !_showTooltip;
                                          });
                                        },
                                        child: Opacity(
                                          opacity: _tries == 0 ? 0.5 : 1.0,
                                          child: Image.asset(
                                            'assets/images/lamp.png',
                                            width: kIsWeb ? 24 : 28.w,
                                            height: kIsWeb ? 24 : 28.h,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                _showTooltip
                                                    ? Icons.lightbulb
                                                    : Icons.lightbulb_outline,
                                                color: _tries == 0
                                                    ? Colors.grey
                                                    : Colors.orange,
                                                size: kIsWeb ? 18 : 20.sp,
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
                                      SizedBox(height: kIsWeb ? 40 : 44.h),

                                      // Question type badge
                                      AnimatedBuilder(
                                        animation: _questionController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _questionFadeAnimation,
                                            child: SlideTransition(
                                              position: _questionSlideAnimation,
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      kIsWeb ? 16 : 16.w,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        kIsWeb ? 14 : 14.w,
                                                    vertical: kIsWeb ? 8 : 8.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _currentColor
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            kIsWeb ? 10 : 10.r),
                                                    border: Border.all(
                                                      color: _currentColor
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.quiz,
                                                        size:
                                                            kIsWeb ? 16 : 16.sp,
                                                        color: _currentColor,
                                                      ),
                                                      SizedBox(
                                                          width:
                                                              kIsWeb ? 8 : 8.w),
                                                      Text(
                                                        _currentQuestion
                                                            .questionType
                                                            .displayName,
                                                        style: TextStyle(
                                                          fontSize: kIsWeb
                                                              ? 14
                                                              : 13.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: _currentColor,
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
                                          .questionType.displayName.isNotEmpty)
                                        SizedBox(height: kIsWeb ? 8 : 10.h),

                                      // Question text with slide-in animation from left
                                      AnimatedBuilder(
                                        animation: _questionController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _questionFadeAnimation,
                                            child: SlideTransition(
                                              position: _questionSlideAnimation,
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      kIsWeb ? 16 : 16.w,
                                                  vertical: kIsWeb ? 8 : 8.h,
                                                ),
                                                child: Text(
                                                  _questionText,
                                                  style: TextStyle(
                                                    fontSize:
                                                        kIsWeb ? 18 : 18.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                    height: 1.4,
                                                    overflow: TextOverflow.fade,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Question Image (if available) - with same slide animation
                                      if (_currentQuestion.image != null &&
                                          _currentQuestion.image!.isNotEmpty)
                                        AnimatedBuilder(
                                          animation: _questionController,
                                          builder: (context, child) {
                                            return FadeTransition(
                                              opacity: _questionFadeAnimation,
                                              child: SlideTransition(
                                                position:
                                                    _questionSlideAnimation,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                      top: kIsWeb ? 12 : 12.h),
                                                  child: _buildQuestionImage(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                      SizedBox(height: kIsWeb ? 16 : 16.h),

                                      // Answer Options or Text Input based on question type
                                      Expanded(
                                        child: SingleChildScrollView(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: kIsWeb ? 16 : 12.w),
                                          child: _currentQuestion.isShortAnswer
                                              ? _buildShortAnswerInput()
                                              : _currentQuestion.isRearrange
                                                  ? _buildRearrangeOptions()
                                                  : _buildAnswerOptions(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Hint Tooltip - attached below the hint image
                                  if (_showTooltip)
                                    Positioned(
                                      top: kIsWeb
                                          ? 40
                                          : 44.h, // Positioned right below hint button (8.h + 28.h + 8.h gap)
                                      right: kIsWeb ? 4 : 4.w,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: kIsWeb ? 280 : 1.sw * 0.75,
                                          maxHeight: kIsWeb ? 250 : 1.sh * 0.4,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // Arrow pointer pointing to hint button
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  right: kIsWeb ? 18 : 20.w),
                                              child: CustomPaint(
                                                size: Size(kIsWeb ? 16 : 18.w,
                                                    kIsWeb ? 10 : 12.h),
                                                painter: _TrianglePainter(
                                                  color: Colors.white,
                                                  borderColor: Colors.orange,
                                                ),
                                              ),
                                            ),
                                            // Main tooltip container
                                            Container(
                                              padding: EdgeInsets.all(
                                                  kIsWeb ? 14 : 16.w),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(
                                                      kIsWeb ? 12 : 14.r),
                                                  topRight: Radius.circular(
                                                      kIsWeb ? 4 : 6.r),
                                                  bottomLeft: Radius.circular(
                                                      kIsWeb ? 12 : 14.r),
                                                  bottomRight: Radius.circular(
                                                      kIsWeb ? 12 : 14.r),
                                                ),
                                                border: Border.all(
                                                    color: Colors.orange,
                                                    width: 1.5),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    spreadRadius: 1,
                                                    blurRadius:
                                                        kIsWeb ? 10 : 12.r,
                                                    offset: Offset(
                                                        0, kIsWeb ? 4 : 6.h),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        '💡 Hint:',
                                                        style: TextStyle(
                                                          fontSize: kIsWeb
                                                              ? 14
                                                              : 16.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .orange[800],
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _showTooltip =
                                                                false;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  kIsWeb
                                                                      ? 4
                                                                      : 4.w),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.orange
                                                                .withOpacity(
                                                                    0.3),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.close,
                                                            size: kIsWeb
                                                                ? 16
                                                                : 18.sp,
                                                            color: Colors
                                                                .orange[800],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          kIsWeb ? 8 : 10.h),
                                                  Flexible(
                                                    child: Text(
                                                      _hint,
                                                      style: TextStyle(
                                                        fontSize:
                                                            kIsWeb ? 13 : 14.sp,
                                                        color: Colors.black87,
                                                        height: 1.4,
                                                      ),
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
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
                        ),
                      ),

                      // Bottom Button Container with curved top corners (full width)
                      Container(
                        height: kIsWeb ? 90 : 0.13.sh,
                        decoration: BoxDecoration(
                          color: _showIncorrect
                              ? const Color(0xFFFFF9C4)
                              : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: _buildBottomButton(),
                      ),
                    ],
                  ),
                  animationDuration: const Duration(milliseconds: 600),
                  animationCurve: Curves.easeOutCubic,
                  enableStaggeredAnimation: true,
                  staggerDelay: const Duration(milliseconds: 100),
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
      padding: EdgeInsets.all(kIsWeb ? 12 : 16.w),
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
            child: AnimatedProgressBar(
              progress: _progress,
              // Dynamic progress based on question completion
              height: kIsWeb ? 12 : 14.h,
              backgroundColor: Colors.grey[300]!,
              progressColor: Colors.green,
              duration: const Duration(milliseconds: 800),
            ),
          ),

          SizedBox(width: kIsWeb ? 12 : 16.w),

          // Progress Dots for HOTS questions (only show if chapter has hots)
          if (widget.chapter.hasHots)
            Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 1 : 1.w),
                  width: kIsWeb ? 18 : 22.w,
                  height: kIsWeb ? 12 : 14.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kIsWeb ? 6 : 7.r),
                    color:
                        index <= _hotsIndex ? Colors.orange : Colors.grey[300],
                    shape: BoxShape.rectangle,
                  ),
                ),
              ),
            ),
          // ),

          // SizedBox(width: 16.w),

          // Hint Button
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
                  // Option letter indicator (A, B, C, D based on display position)
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
                                      String.fromCharCode(65 +
                                          displayIndex), // A, B, C, D based on display position
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
                  // Answer Text - use actual index to get the correct answer text
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
        // Disable input when showing incorrect - user must click Continue first
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_shuffledIndices.length, (displayIndex) {
        // Get the actual option index from shuffled indices
        final actualIndex = _shuffledIndices[displayIndex];
        final userOrder = _rearrangeOrder[actualIndex];
        final isSelected = userOrder != null;
        final isDisabled = _disabledOptionIndices.contains(actualIndex);
        // Show correct order after 2 wrong attempts
        final showCorrectOrder = _showIncorrect && _tries >= 2;
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
                  // Answer Text - use actual index to get the correct answer text
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
      return TweenAnimationBuilder<Offset>(
        key: const ValueKey('success_slide'),
        tween: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, offset, child) {
          return FractionalTranslation(
            translation: offset,
            child: child,
          );
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

                    // All in one row: 🎉, Correct!, XP, Continue button
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Celebration icon with bounce animation
                          TweenAnimationBuilder<double>(
                            key: const ValueKey('celebrate_bounce'),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/images/celebrate.png',
                              width: kIsWeb ? 28 : 32.w,
                              height: kIsWeb ? 28 : 32.h,
                              fit: BoxFit.fitHeight,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  '🎉',
                                  style:
                                      TextStyle(fontSize: kIsWeb ? 24 : 28.sp),
                                );
                              },
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
                          // XP badge with animation
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
                          // Continue Button
                          GestureDetector(
                            onTapDown: (_) {
                              // Only respond if showing success and not already processing
                              if (!_showSuccess || _isProcessingContinue)
                                return;
                              // Set debounce flag immediately to prevent multiple taps
                              _isProcessingContinue = true;
                              setState(() {
                                _isContinueButtonPressed = true;
                              });
                            },
                            onTapUp: (_) {
                              // Debounce: prevent multiple clicks and ensure answer was given
                              if (!_showSuccess) return;

                              // Fire-and-forget sound/vibration (no await to prevent delay)
                              // SoundService().playSuccess();
                              VibrationService().successVibration();

                              // Capture current question data for API call BEFORE changing state
                              final currentQuestion = _currentQuestion;
                              final shortAnswerText = _shortAnswerText;
                              final tries = _tries;
                              final selectedAnswerId = _getSelectedAnswerId();
                              final selectedAnswerIds = _getSelectedAnswerIds();
                              final isLastQuestion = _currentQuestionIndex >=
                                  widget.questions.length - 1;
                              final shouldRefreshXpData =
                                  _shouldRefreshXpDataAfterCurrentAnswer(
                                      isLastQuestion);
                              final userBloc = context.read<UserBloc>();

                              // UPDATE UI IMMEDIATELY - then API calls run in background
                              if (_isShowingHots) {
                                if (_hotsIndex >= _hotsQuestions.length - 1) {
                                  // All HOTS questions completed, navigate to dashboard
                                  print(
                                      '🔵 Quiz: All HOTS questions completed, navigating to dashboard');
                                  widget.onQuizCompleted?.call();
                                  if (context.mounted) {
                                    context.read<ModuleChapterBloc>().add(
                                        RefreshModuleChapters(
                                            widget.module.id));
                                  }
                                  // Play module completion sound
                                  // SoundService().playModuleComplete();
                                  Navigator.of(context).pushReplacement(
                                    ConnectedPageTransitions.fadeThrough(
                                      page: Scaffold(
                                          body: DashboardContent(
                                              fromQuizScreen: true,
                                              moduleId: widget.module.id)),
                                    ),
                                  );
                                } else {
                                  // Move to next HOTS question
                                  print(
                                      '🔵 Quiz: Moving to next HOTS question (${_hotsIndex + 1}/${_hotsQuestions.length})');
                                  _hotsIndex++;
                                  _shuffleOptions(); // Shuffle options for next question
                                  setState(() {
                                    _isContinueButtonPressed = false;
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
                                    _isProcessingContinue =
                                        false; // Reset debounce after state update
                                  });
                                }
                              } else if (isLastQuestion) {
                                if (widget.chapter.hasHots &&
                                    _hotsQuestions.isNotEmpty) {
                                  // Start showing HOTS questions
                                  print(
                                      '🔵 Quiz: All regular questions completed, starting HOTS questions (${_hotsQuestions.length} available)');
                                  _isShowingHots = true;
                                  _hotsIndex = 0;
                                  _shuffleOptions(); // Shuffle options for first HOTS question
                                  setState(() {
                                    _isContinueButtonPressed = false;
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
                                    _isProcessingContinue =
                                        false; // Reset debounce after state update
                                  });
                                } else {
                                  // No HOTS questions, navigate to dashboard
                                  print(
                                      '🔵 Quiz: All questions completed, navigating back and refreshing module chapters');
                                  widget.onQuizCompleted?.call();
                                  if (context.mounted) {
                                    context.read<ModuleChapterBloc>().add(
                                        RefreshModuleChapters(
                                            widget.module.id));
                                  }
                                  // Play module completion sound
                                  // SoundService().playModuleComplete();
                                  Navigator.of(context).pushReplacement(
                                    ConnectedPageTransitions.fadeThrough(
                                      page: Scaffold(
                                          body: DashboardContent(
                                              fromQuizScreen: true,
                                              moduleId: widget.module.id)),
                                    ),
                                  );
                                }
                              } else {
                                // Move to next question by updating state IMMEDIATELY
                                print(
                                    '🔵 Quiz: Moving to next question (${_currentQuestionIndex + 1}/${widget.questions.length})');
                                _currentQuestionIndex++;
                                _shuffleOptions(); // Shuffle options for next question
                                setState(() {
                                  _isContinueButtonPressed = false;
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
                                  _isProcessingContinue =
                                      false; // Reset debounce after state update
                                });
                              }

                              // Fire-and-forget API call in background (no await, no blocking)
                              _trackAnswerInBackground(
                                currentQuestion: currentQuestion,
                                shortAnswerText: shortAnswerText,
                                tries: tries,
                                selectedAnswerId: selectedAnswerId,
                                selectedAnswerIds: selectedAnswerIds,
                                isLastQuestion: isLastQuestion,
                                shouldRefreshXpData: shouldRefreshXpData,
                                userBloc: userBloc,
                              );
                            },
                            onTapCancel: () {
                              setState(() {
                                _isContinueButtonPressed = false;
                                _isProcessingContinue =
                                    false; // Reset debounce on cancel
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                              height: kIsWeb ? 44 : 53.h,
                              width: kIsWeb ? 320 : 386.w,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: _hexToColor("29CC57").withOpacity(
                                        _isContinueButtonPressed ? 0.2 : 0.4),
                                    blurRadius:
                                        _isContinueButtonPressed ? 4 : 8,
                                    offset: Offset(
                                        0, _isContinueButtonPressed ? 1 : 4),
                                  ),
                                ],
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

    // Show incorrect answer UI
    if (_showIncorrect) {
      return TweenAnimationBuilder<Offset>(
        key: const ValueKey('incorrect_slide'),
        tween: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, offset, child) {
          return FractionalTranslation(
            translation: offset,
            child: child,
          );
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
                    onTapDown: (_) =>
                        setState(() => _isSeeAnswerPressed = true),
                    onTapUp: (_) async {
                      setState(() => _isSeeAnswerPressed = false);
                      await VibrationService().lightVibration();
                      _showExplanationModal();
                    },
                    onTapCancel: () =>
                        setState(() => _isSeeAnswerPressed = false),
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
                            width: _isSeeAnswerPressed ? 1 : 4,
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
                        if (_tries >= 2) {
                          _moveToNextQuestionAfterWrongAnswer();
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
                          color: _tries >= 2
                              ? _hexToColor("2D2D2D")
                              : _hexToColor("E5E5E5"),
                          borderRadius:
                              BorderRadius.circular(kIsWeb ? 22 : 28.r),
                          border: Border(
                            bottom: BorderSide(
                              color: _tries >= 2
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
                              color:
                                  _tries >= 2 ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 12 : 16.w),
                  // Incorrect label at rightmost
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

    // Check if answer is selected/entered based on question type
    bool hasAnswer = false;
    if (_currentQuestion.isShortAnswer) {
      hasAnswer = _shortAnswerText.isNotEmpty;
    } else if (_currentQuestion.isMcqMultiple) {
      hasAnswer = _selectedAnswerIndices.isNotEmpty;
    } else if (_currentQuestion.isRearrange) {
      // For rearrange, all options must be ordered
      hasAnswer = _rearrangeOrder.length == _answers.length;
    } else {
      hasAnswer = _selectedAnswerIndex != null;
    }

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
            margin: EdgeInsets.only(
              bottom: kIsWeb ? 23 : 20.h,
            ),
            decoration: BoxDecoration(
              color: _hexToColor("F2F2F2"),
              borderRadius: BorderRadius.circular(kIsWeb ? 22 : 28.r),
            ),
            child: Center(
              child: Text(
                'Check',
                style: TextStyle(
                  fontSize: kIsWeb ? 20 : 20.sp,
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
        onTapDown: hasAnswer
            ? (_) {
                setState(() {
                  _isCheckButtonPressed = true;
                });
              }
            : null,
        onTapUp: hasAnswer
            ? (_) async {
                setState(() {
                  _isCheckButtonPressed = false;
                });
                // Dismiss keyboard
                FocusScope.of(context).unfocus();

                await VibrationService().lightVibration();
                // Increment tries counter
                setState(() {
                  _tries++;
                });

                // Check answer based on question type
                bool isCorrect = false;

                if (_currentQuestion.isShortAnswer) {
                  // For short answer, check via API
                  try {
                    final result = await _apiService.checkAnswer(
                      _currentQuestion.id,
                      _shortAnswerText,
                      _tries,
                      isLast: false, // Not the final attempt yet
                      isShortAnswer: true,
                    );

                    if (result['success'] == true &&
                        result['data']?['is_correct'] == true) {
                      final response = result['data']['module_progress'];
                      Map<String, dynamic> data = response;
                      if (mounted) {
                        context.read<SubjectBloc>().add(UpdateModuleStatus(
                              subjectId: widget.subject.id,
                              moduleId: widget.module.id,
                              newStatus: ModuleStatus.fromString(
                                  data['status'] as String),
                              newPercentage:
                                  (data['percentage'] as num).toDouble(),
                            ));

                        // Update chapter's currentQuestionId to next question
                        _updateChapterCurrentQuestion();
                      }
                      isCorrect = true;
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
                      // On first wrong attempt, just show hint without incorrect UI
                      if (_tries < 2) {
                        setState(() {
                          _showShock = true;
                          _showTooltip = true; // Auto-show hint on wrong answer
                          _shortAnswerText = '';
                          _shortAnswerController.clear();
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
                  } catch (e) {
                    print('🔵 Quiz: Error checking short answer: $e');
                    // On first wrong attempt, just show hint without incorrect UI
                    if (_tries < 2) {
                      setState(() {
                        _showShock = true;
                        _showTooltip = true; // Auto-show hint on wrong answer
                        _shortAnswerText = '';
                        _shortAnswerController.clear();
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
                } else if (_currentQuestion.isMcqMultiple) {
                  // Check if all selected answers are correct and all correct answers are selected
                  final selectedCorrect = _selectedAnswerIndices
                      .where((index) => _correctAnswerIndices.contains(index))
                      .length;
                  final allCorrectSelected =
                      selectedCorrect == _correctAnswerIndices.length;
                  final allSelectedCorrect = _selectedAnswerIndices.length ==
                      _correctAnswerIndices.length;
                  isCorrect = allCorrectSelected && allSelectedCorrect;

                  if (isCorrect) {
                    // Update chapter's currentQuestionId to next question
                    _updateChapterCurrentQuestion();

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
                    // Disable wrong options that were selected
                    final wrongOptions = _selectedAnswerIndices
                        .where(
                            (index) => !_correctAnswerIndices.contains(index))
                        .toSet();

                    if (_tries < 2) {
                      // On first wrong attempt, just show hint without incorrect UI
                      setState(() {
                        _showShock = true;
                        _showTooltip = true; // Auto-show hint on wrong answer
                        _disabledOptionIndices.addAll(wrongOptions);
                        _selectedAnswerIndices
                            .clear(); // Clear selection so user can pick again
                      });
                    } else {
                      // On second wrong attempt, show incorrect UI
                      setState(() {
                        _showIncorrect = true;
                        _showShock = true;
                        _showTooltip = true;
                        _disabledOptionIndices.addAll(wrongOptions);
                      });
                    }
                    // await SoundService().playIncorrectAnswer();
                  }
                } else if (_currentQuestion.isRearrange) {
                  isCorrect = _isRearrangeAnswerCorrect;

                  if (isCorrect) {
                    // Update chapter's currentQuestionId to next question
                    _updateChapterCurrentQuestion();

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
                    if (_tries < 2) {
                      // On first wrong attempt, just show hint without incorrect UI
                      setState(() {
                        _showShock = true;
                        _showTooltip = true; // Auto-show hint on wrong answer
                        _rearrangeOrder = {}; // Clear rearrange selection
                        _nextRearrangeOrder = 1;
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
                } else {
                  // Single select MCQ
                  isCorrect = _selectedAnswerIndex == _correctAnswerIndex;

                  if (isCorrect) {
                    // Update chapter's currentQuestionId to next question
                    _updateChapterCurrentQuestion();

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
                }
              }
            : null,
        onTapCancel: () {
          setState(() {
            _isCheckButtonPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          width: kIsWeb ? 440 : 386.w,
          height: kIsWeb ? 50 : 53.h,
          margin: EdgeInsets.only(
            bottom: kIsWeb ? 20 : 20.h,
          ),
          decoration: BoxDecoration(
            color: hasAnswer ? _hexToColor("2D2D2D") : _hexToColor("F2F2F2"),
            borderRadius: BorderRadius.circular(kIsWeb ? 22 : 28.r),
            border: hasAnswer
                ? Border(
                    bottom: BorderSide(
                      color: Colors.black,
                      width: _isCheckButtonPressed ? 1 : 4,
                    ),
                  )
                : null,
          ),
          child: Center(
            child: Text(
              'Check',
              style: TextStyle(
                fontSize: kIsWeb ? 16 : 20.sp,
                fontWeight: FontWeight.w500,
                color: hasAnswer ? Colors.white : _hexToColor("999999"),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Move to next question after 2nd wrong attempt
  void _moveToNextQuestionAfterWrongAnswer() {
    // Capture current question data for API call BEFORE changing state
    final currentQuestion = _currentQuestion;
    final shortAnswerText = _shortAnswerText;
    final tries = _tries;
    final selectedAnswerId = _getSelectedAnswerId();
    final selectedAnswerIds = _getSelectedAnswerIds();
    final isLastQuestion = _currentQuestionIndex >= widget.questions.length - 1;
    final shouldRefreshXpData =
        _shouldRefreshXpDataAfterCurrentAnswer(isLastQuestion);
    final userBloc = context.read<UserBloc>();

    // UPDATE UI IMMEDIATELY
    if (_isShowingHots) {
      if (_hotsIndex >= _hotsQuestions.length - 1) {
        // All HOTS questions completed, navigate to dashboard
        print(
            '🔵 Quiz: All HOTS questions completed (wrong answer), navigating to dashboard');
        widget.onQuizCompleted?.call();
        if (context.mounted) {
          context
              .read<ModuleChapterBloc>()
              .add(RefreshModuleChapters(widget.module.id));
        }
        // Play module completion sound
        // SoundService().playModuleComplete();
        Navigator.of(context).pushReplacement(
          ConnectedPageTransitions.fadeThrough(
            page: SafeArea(
              top: false,
              child: Scaffold(
                body: DashboardContent(
                    fromQuizScreen: true, moduleId: widget.module.id),
              ),
            ),
          ),
        );
      } else {
        // Move to next HOTS question
        print(
            '🔵 Quiz: Moving to next HOTS question after wrong answer (${_hotsIndex + 1}/${_hotsQuestions.length})');
        _hotsIndex++;
        _shuffleOptions(); // Shuffle options for next question
        setState(() {
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
      }
    } else if (isLastQuestion) {
      if (widget.chapter.hasHots && _hotsQuestions.isNotEmpty) {
        // Start showing HOTS questions
        print(
            '🔵 Quiz: All regular questions completed (wrong answer), starting HOTS questions');
        _isShowingHots = true;
        _hotsIndex = 0;
        _shuffleOptions(); // Shuffle options for first HOTS question
        setState(() {
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
      } else {
        // No HOTS questions, navigate to dashboard
        print(
            '🔵 Quiz: All questions completed (wrong answer), navigating to dashboard');
        widget.onQuizCompleted?.call();
        if (context.mounted) {
          context
              .read<ModuleChapterBloc>()
              .add(RefreshModuleChapters(widget.module.id));
        }
        // Play module completion sound
        // SoundService().playModuleComplete();
        Navigator.of(context).pushReplacement(
          ConnectedPageTransitions.fadeThrough(
            page: Scaffold(
                body: DashboardContent(
                    fromQuizScreen: true, moduleId: widget.module.id)),
          ),
        );
      }
    } else {
      // Move to next question
      print(
          '🔵 Quiz: Moving to next question after wrong answer (${_currentQuestionIndex + 1}/${widget.questions.length})');
      _currentQuestionIndex++;
      _shuffleOptions(); // Shuffle options for next question
      setState(() {
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
    }

    // Fire-and-forget API call in background
    _trackAnswerInBackground(
      currentQuestion: currentQuestion,
      shortAnswerText: shortAnswerText,
      tries: tries,
      selectedAnswerId: selectedAnswerId,
      selectedAnswerIds: selectedAnswerIds,
      isLastQuestion: isLastQuestion,
      shouldRefreshXpData: shouldRefreshXpData,
      userBloc: userBloc,
    );
  }

  // Track answer in background without blocking UI
  void _trackAnswerInBackground({
    required Question currentQuestion,
    required String shortAnswerText,
    required int tries,
    required String? selectedAnswerId,
    required List<String> selectedAnswerIds,
    required bool isLastQuestion,
    required bool shouldRefreshXpData,
    required UserBloc userBloc,
  }) async {
    try {
      if (currentQuestion.isShortAnswer) {
        if (isLastQuestion) {
          print(
              '🔵 Quiz: Final answer tracking for question ${currentQuestion.id}, answer text: $shortAnswerText, tries $tries, isLast: true');
          final result = await _apiService.checkAnswer(
            currentQuestion.id,
            shortAnswerText,
            tries,
            isLast: true,
            isShortAnswer: true,
          );
          if (shouldRefreshXpData && result['success'] == true) {
            _refreshXpDataAfterQuizCompletion(userBloc);
          }
          print('🔵 Quiz: Final API response: $result');
        }
      } else if (currentQuestion.isMcqMultiple || currentQuestion.isRearrange) {
        // Handle both MCQ multiple and rearrange questions
        if (selectedAnswerIds.isNotEmpty) {
          print(
              '🔵 Quiz: Final answer tracking for question ${currentQuestion.id}, answer IDs: $selectedAnswerIds, tries $tries, isLast: $isLastQuestion');
          final result = await _apiService.checkAnswer(
            currentQuestion.id,
            selectedAnswerIds,
            tries,
            isLast: isLastQuestion,
            isMultipleSelect: true,
          );
          if (shouldRefreshXpData && result['success'] == true) {
            _refreshXpDataAfterQuizCompletion(userBloc);
          }
          print('🔵 Quiz: Final API response: $result');
        }
      } else {
        if (selectedAnswerId != null) {
          print(
              '🔵 Quiz: Final answer tracking for question ${currentQuestion.id}, answer $selectedAnswerId, tries $tries, isLast: $isLastQuestion');
          final result = await _apiService.checkAnswer(
            currentQuestion.id,
            selectedAnswerId,
            tries,
            isLast: isLastQuestion,
          );
          if (shouldRefreshXpData && result['success'] == true) {
            _refreshXpDataAfterQuizCompletion(userBloc);
          }
          if (result['status'] == true) {
            final response = result['data']['module_progress'];
            Map<String, dynamic> data = response;
            if (mounted) {
              context.read<SubjectBloc>().add(UpdateModuleStatus(
                    subjectId: widget.subject.id,
                    moduleId: widget.module.id,
                    newStatus:
                        ModuleStatus.fromString(data['status'] as String),
                    newPercentage: (data['percentage'] as num).toDouble(),
                  ));
            }
          }
          print('🔵 Quiz: Final API response: $result');
        }
      }
    } catch (e) {
      print('🔵 Quiz: Error tracking final answer: $e');
    }
  }

  // Update chapter's currentQuestionId to the next question
  void _updateChapterCurrentQuestion() {
    if (!mounted) return;
    // Don't update current question for HOTS questions
    if (_isShowingHots) return;

    // Bounds check to prevent RangeError when quiz is completed
    if (_currentQuestionIndex >= widget.questions.length) return;

    context.read<ModuleChapterBloc>().add(
          UpdateChapterCurrentQuestion(
            moduleId: widget.module.id,
            chapterId: widget.chapter.id,
            currentQuestionId: widget.questions[_currentQuestionIndex].id,
          ),
        );
  }

  // Get the selected answer ID from the question content (for single select)
  String? _getSelectedAnswerId() {
    if (_selectedAnswerIndex != null &&
        _selectedAnswerIndex! < _currentQuestion.options.length) {
      return _currentQuestion.options[_selectedAnswerIndex!].id;
    }
    return null;
  }

  // Get the selected answer IDs from the question content (for multiple select)
  List<String> _getSelectedAnswerIds() {
    if (_currentQuestion.isMcqMultiple) {
      return _selectedAnswerIndices
          .where((index) => index < _currentQuestion.options.length)
          .map((index) => _currentQuestion.options[index].id)
          .toList();
    } else if (_currentQuestion.isRearrange) {
      // For rearrange, return option IDs sorted by user's order
      return _selectedRearrangeOptionIds;
    }
    return [];
  }

  Color _getSubjectColor(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') || name.contains('mathematics')) {
      return Colors.blue;
    } else if (name.contains('science')) {
      return Colors.purple;
    } else if (name.contains('economics')) {
      return Colors.orange;
    } else if (name.contains('history')) {
      return Colors.brown;
    } else if (name.contains('english')) {
      return Colors.indigo;
    } else if (name.contains('geography')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }

  // Show explanation in a bottom modal sheet
  void _showExplanationModal() {
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
                        _explanation,
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

/// Custom painter to draw a triangle arrow for the speech bubble tooltip
class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(size.width / 2, 0) // Top center point
      ..lineTo(size.width, size.height) // Bottom right
      ..lineTo(0, size.height) // Bottom left
      ..close();

    canvas.drawPath(path, fillPaint);

    // Draw only the top two edges (not the bottom) to blend with container
    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
