import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../services/screen_security_service.dart';
import '../../services/user_test_api_service.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/confetti_celebration.dart';
import '../../widgets/shock_animation.dart';
import '../../models/user_test_model.dart';
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

class TestQuizScreen extends StatefulWidget {
  final UserTest test;
  final VoidCallback? onTestCompleted;

  const TestQuizScreen({
    super.key,
    required this.test,
    this.onTestCompleted,
  });

  @override
  State<TestQuizScreen> createState() => _TestQuizScreenState();
}

class _TestQuizScreenState extends State<TestQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  Set<int> _selectedAnswerIndices = {};
  String _shortAnswerText = '';
  final TextEditingController _shortAnswerController = TextEditingController();
  Map<int, int> _rearrangeOrder = {};
  int _nextRearrangeOrder = 1;
  bool _showSuccess = false;
  bool _showIncorrect = false;
  bool _showTooltip = false;
  int _tries = 0;
  Set<int> _disabledOptionIndices = {};
  List<int> _shuffledIndices = [];
  final UserTestApiService _apiService = UserTestApiService();
  bool _isSeeAnswerPressed = false;
  bool _isWhyButtonPressed = false;
  bool _isCheckButtonPressed = false;
  bool _isContinueButtonPressed = false;
  bool _isTryAgainButtonPressed = false;
  bool _isProcessingContinue = false;

  // Animation states
  bool _showConfetti = false;
  bool _showShock = false;

  // Timer related
  Timer? _testTimer;
  Duration _remainingTime = Duration.zero;
  bool _isTimerRunning = false;
  bool _isTimeUp = false;

  // Questions data
  List<TestQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controllers
  late List<AnimationController> _optionControllers;
  late List<Animation<Offset>> _optionSlideAnimations;
  late List<Animation<double>> _optionFadeAnimations;

  late AnimationController _questionController;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _questionFadeAnimation;

  // Base color for the screen
  Color get _baseColor =>
      _hexToColor(widget.test.subjectColor, fallback: const Color(0xFFFF9800));

  // Get current question
  TestQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  // Get answers
  List<String> get _answers =>
      _currentQuestion.options.map((o) => o.optionText).toList();

  // Get correct answer indices
  List<int> get _correctAnswerIndices {
    return _currentQuestion.options
        .asMap()
        .entries
        .where((entry) => entry.value.isCorrect)
        .map((entry) => entry.key)
        .toList();
  }

  // Get correct answer index
  int get _correctAnswerIndex {
    final idx = _currentQuestion.options.indexWhere((o) => o.isCorrect);
    return idx >= 0 ? idx : 0;
  }

  bool get _canCheckAnswer {
    if (_currentQuestion.isRearrange) {
      return _rearrangeOrder.length == _currentQuestion.options.length;
    }
    return _selectedAnswerIndex != null;
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
  String get _questionText => _currentQuestion.questionText;

  // Get explanation
  String get _explanation =>
      _currentQuestion.explanation ??
      'Answer the question correctly to proceed.';

  // Get hint
  String get _hint {
    if (_currentQuestion.hint != null && _currentQuestion.hint!.isNotEmpty) {
      return _currentQuestion.hint!;
    }
    return _currentQuestion.explanation ??
        'Answer the question correctly to proceed.';
  }

  // Check if hint is available
  bool get _hasHint => _currentQuestion.hasHint;

  // Get progress
  double get _progress => _currentQuestionIndex / _questions.length;

  // Get current color based on state
  Color get _currentColor {
    if (_showSuccess) {
      return _hexToColor("31C85D");
    } else if (_showIncorrect) {
      return _hexToColor("EFD895");
    } else {
      return _baseColor;
    }
  }

  @override
  void initState() {
    super.initState();

    // Enable screen security to prevent screenshots and recordings
    ScreenSecurityService().enableSecureMode();

    // Initialize animation controllers
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

    // On web (CanvasKit), set controllers to completed state immediately
    // to avoid blank screen caused by FadeTransition starting at opacity 0
    if (kIsWeb) {
      _questionController.value = 1.0;
      for (var controller in _optionControllers) {
        controller.value = 1.0;
      }
    }

    // Load test questions
    _loadTestQuestions();
  }

  Future<void> _loadTestQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Start the test
      await _apiService.startTest(widget.test.id);

      // Load questions
      final response = await _apiService.getTestQuestions(widget.test.id);

      if (response.success && response.data != null) {
        setState(() {
          _questions = response.data!;
          _isLoading = false;
        });

        if (_questions.isNotEmpty) {
          _shuffleOptions();
          _startOptionAnimations();
          // Start the test timer after questions are loaded
          _startTestTimer();
        }
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTestTimer() {
    // Calculate remaining time based on test end time
    // Server sends times in UTC, so we need to compare with UTC time
    final testEndTime = widget.test.testEndTime.toUtc();
    final now = DateTime.now().toUtc();

    if (now.isAfter(testEndTime)) {
      // Time already up
      _handleTimeUp();
      return;
    }

    _remainingTime = testEndTime.difference(now);
    _isTimerRunning = true;

    // Update timer every second
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          timer.cancel();
          _isTimerRunning = false;
          _handleTimeUp();
        }
      });
    });
  }

  void _handleTimeUp() {
    if (_isTimeUp) return; // Prevent multiple calls
    _isTimeUp = true;

    // Play warning sound
    VibrationService().errorVibration();

    // Show time up dialog and auto-complete the test
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
        ),
        title: Column(
          children: [
            Icon(
              Icons.timer_off,
              size: kIsWeb ? 64 : 64.sp,
              color: Colors.red,
            ),
            SizedBox(height: kIsWeb ? 16 : 16.h),
            const Text('Time\'s Up!'),
          ],
        ),
        content: Text(
          'The test duration has ended. Your progress will be saved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: kIsWeb ? 14 : 14.sp,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _completeTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: kIsWeb ? 12 : 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                ),
              ),
              child: Text(
                'Submit Test',
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingTime.inMinutes < 1) {
      return Colors.red;
    } else if (_remainingTime.inMinutes < 5) {
      return Colors.orange;
    }
    return Colors.green;
  }

  void _shuffleOptions() {
    final optionCount = _currentQuestion.options.length;
    _shuffledIndices = List.generate(optionCount, (i) => i);
    _shuffledIndices.shuffle(Random());
  }

  void _startOptionAnimations() {
    // SoundService().playQuestionWhoosh();

    // On web (CanvasKit), skip reset-and-animate to avoid blank content
    if (kIsWeb) {
      _questionController.value = 1.0;
      for (var controller in _optionControllers) {
        controller.value = 1.0;
      }
      return;
    }

    _questionController.reset();
    _questionController.forward();

    for (var controller in _optionControllers) {
      controller.reset();
    }

    final optionCount = _answers.length.clamp(0, 6);
    for (int i = 0; i < optionCount; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 80)), () {
        if (mounted && i < _optionControllers.length) {
          _optionControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancel the test timer
    _testTimer?.cancel();
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_baseColor),
              ),
              SizedBox(height: kIsWeb ? 16 : 16.h),
              Text(
                'Loading test questions...',
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: kIsWeb ? 64 : 64.sp,
                color: Colors.red[400],
              ),
              SizedBox(height: kIsWeb ? 16 : 16.h),
              Text(
                _errorMessage ?? 'No questions available',
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 16.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: kIsWeb ? 24 : 24.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _baseColor,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      _currentColor.withOpacity(0.05),
                      _currentColor.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Progress bar
                  _buildProgressBar(),

                  if (kIsWeb)
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.005),

                  // Question content
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: kIsWeb
                                    ? constraints.maxWidth * 0.7
                                    : double.infinity),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: kIsWeb ? 24 : 20.w,
                                vertical: kIsWeb ? 16 : 16.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question type badge
                                  SlideTransition(
                                    position: _questionSlideAnimation,
                                    child: FadeTransition(
                                      opacity: _questionFadeAnimation,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kIsWeb ? 12 : 14.w,
                                          vertical: kIsWeb ? 6 : 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _currentColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                              kIsWeb ? 8 : 10.r),
                                          border: Border.all(
                                            color:
                                                _currentColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.quiz,
                                              size: kIsWeb ? 14 : 16.sp,
                                              color: _currentColor,
                                            ),
                                            SizedBox(width: kIsWeb ? 6 : 8.w),
                                            Text(
                                              QuestionType.fromString(
                                                      _currentQuestion
                                                          .questionType)
                                                  .displayName,
                                              style: TextStyle(
                                                fontSize: kIsWeb ? 9 : 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: _currentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: kIsWeb ? 12 : 14.h),

                                  // Question text
                                  _buildQuestionText(),

                                  SizedBox(height: kIsWeb ? 24 : 24.h),

                                  // Answer options
                                  _currentQuestion.isRearrange
                                      ? _buildRearrangeOptions()
                                      : _buildAnswerOptions(),

                                  // Tooltip/explanation
                                  if (_showTooltip) _buildTooltip(),

                                  SizedBox(height: kIsWeb ? 24 : 24.h),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom action button
                  _buildBottomButton(),
                ],
              ),
            ),

            // Confetti celebration
            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiCelebration(
                    isPlaying: _showConfetti,
                    particleCount: 50,
                    duration: const Duration(milliseconds: 1500),
                  ),
                ),
              ),

            // Shock animation
            if (_showShock)
              Positioned.fill(
                child: IgnorePointer(
                  child: IntenseShockEffect(
                    isPlaying: _showShock,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 16 : 16.w,
        vertical: kIsWeb ? 8 : 8.h,
      ),
      child: Column(
        children: [
          // Timer row
          if (_isTimerRunning || _remainingTime.inSeconds > 0)
            _buildTimerWidget(),
          SizedBox(height: kIsWeb ? 4 : 4.h),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  // await SoundService().playButtonClick();
                  _showExitConfirmation();
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.black,
                  size: kIsWeb ? 24 : 24.sp,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.test.title,
                      style: TextStyle(
                        fontSize: kIsWeb ? 18 : 17.6.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                      style: TextStyle(
                        fontSize: kIsWeb ? 16 : 13.2.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Hint button
              if (_hasHint)
                IconButton(
                  onPressed: _showSuccess || _showIncorrect || _tries == 0
                      ? null
                      : () async {
                          await VibrationService().lightVibration();
                          // SoundService().playHintUsage();
                          setState(() {
                            _showTooltip = !_showTooltip;
                          });
                        },
                  icon: Icon(
                    Icons.lightbulb_outline,
                    color: _tries == 0
                        ? Colors.grey[300]
                        : (_showTooltip ? _baseColor : Colors.grey[400]),
                    size: kIsWeb ? 24 : 24.sp,
                  ),
                )
              else
                SizedBox(width: kIsWeb ? 48 : 48.w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    final timerColor = _getTimerColor();
    final isLowTime = _remainingTime.inMinutes < 5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 16 : 16.w,
        vertical: kIsWeb ? 8 : 8.h,
      ),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 20.r),
        border: Border.all(
          color: timerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLowTime ? Icons.timer_off : Icons.timer,
            color: timerColor,
            size: kIsWeb ? 21 : 18.sp,
          ),
          SizedBox(width: kIsWeb ? 8 : 6.w),
          Text(
            _formatDuration(_remainingTime),
            style: TextStyle(
              fontSize: kIsWeb ? 19 : 16.sp,
              fontWeight: FontWeight.bold,
              color: timerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (isLowTime) ...[
            SizedBox(width: kIsWeb ? 8 : 6.w),
            Text(
              'remaining',
              style: TextStyle(
                fontSize: kIsWeb ? 13 : 12.sp,
                color: timerColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 24 : 20.w,
        vertical: kIsWeb ? 8 : 8.h,
      ),
      child: AnimatedProgressBar(
        progress: (_currentQuestionIndex + 1) / _questions.length,
        progressColor: _currentColor,
        backgroundColor: Colors.grey[200]!,
        height: kIsWeb ? 8 : 8.h,
        borderRadius: BorderRadius.circular(kIsWeb ? 4 : 4.r),
      ),
    );
  }

  Widget _buildQuestionText() {
    return SlideTransition(
      position: _questionSlideAnimation,
      child: FadeTransition(
        opacity: _questionFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _questionText,
            style: TextStyle(
              fontSize: kIsWeb ? 14 : 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    final options = _currentQuestion.options;

    return Column(
      children: List.generate(options.length, (displayIndex) {
        final actualIndex = _shuffledIndices.isNotEmpty &&
                displayIndex < _shuffledIndices.length
            ? _shuffledIndices[displayIndex]
            : displayIndex;
        final option = options[actualIndex];
        final isSelected = _selectedAnswerIndex == actualIndex;
        final isDisabled = _disabledOptionIndices.contains(actualIndex);
        final isCorrect = option.isCorrect;
        final showCorrect = _showSuccess && isCorrect;
        final showWrong = _showIncorrect && isSelected && !isCorrect;

        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey[300]!;
        Color textColor = Colors.black87;

        if (showCorrect) {
          backgroundColor = Colors.green[50]!;
          borderColor = Colors.green;
          textColor = Colors.green[800]!;
        } else if (showWrong) {
          backgroundColor = Colors.red[50]!;
          borderColor = Colors.red;
          textColor = Colors.red[800]!;
        } else if (isSelected) {
          backgroundColor = _baseColor.withOpacity(0.1);
          borderColor = _baseColor;
        } else if (isDisabled) {
          backgroundColor = Colors.grey[100]!;
          borderColor = Colors.grey[300]!;
          textColor = Colors.grey[400]!;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: kIsWeb ? 12 : 12.h),
          child: displayIndex < _optionSlideAnimations.length
              ? SlideTransition(
                  position: _optionSlideAnimations[displayIndex],
                  child: FadeTransition(
                    opacity: _optionFadeAnimations[displayIndex],
                    child: _buildOptionCard(
                      option: option,
                      actualIndex: actualIndex,
                      isSelected: isSelected,
                      isDisabled: isDisabled,
                      backgroundColor: backgroundColor,
                      borderColor: borderColor,
                      textColor: textColor,
                    ),
                  ),
                )
              : _buildOptionCard(
                  option: option,
                  actualIndex: actualIndex,
                  isSelected: isSelected,
                  isDisabled: isDisabled,
                  backgroundColor: backgroundColor,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
        );
      }),
    );
  }

  Widget _buildOptionCard({
    required TestQuestionOption option,
    required int actualIndex,
    required bool isSelected,
    required bool isDisabled,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: (_showSuccess || _showIncorrect || isDisabled)
          ? null
          : () async {
              await VibrationService().selectionVibration();
              // SoundService().playAnswerSelect();
              setState(() {
                _selectedAnswerIndex = actualIndex;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _baseColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: kIsWeb ? 24 : 24.w,
              height: kIsWeb ? 24 : 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _baseColor : Colors.grey[200],
                border: Border.all(
                  color: isSelected ? _baseColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: kIsWeb ? 14 : 14.sp,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: kIsWeb ? 12 : 12.w),
            Expanded(
              child: Text(
                option.optionText,
                style: TextStyle(
                  fontSize: kIsWeb ? 12 : 15.sp,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRearrangeOptions() {
    final showCorrectOrder = _showSuccess || _showIncorrect;
    final options = _currentQuestion.options;

    return Column(
      children: List.generate(_shuffledIndices.length, (displayIndex) {
        final actualIndex = displayIndex < _shuffledIndices.length
            ? _shuffledIndices[displayIndex]
            : displayIndex;
        final option = options[actualIndex];
        final userOrder = _rearrangeOrder[actualIndex];
        final isSelected = userOrder != null;
        final correctOrder = _correctRearrangeDisplayOrders[actualIndex];

        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey[300]!;
        Color textColor = Colors.black87;

        if (showCorrectOrder) {
          backgroundColor = Colors.green[50]!;
          borderColor = Colors.green;
          textColor = Colors.green[800]!;
        } else if (isSelected) {
          backgroundColor = _baseColor.withOpacity(0.1);
          borderColor = _baseColor;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: kIsWeb ? 12 : 12.h),
          child: GestureDetector(
            onTap: showCorrectOrder
                ? null
                : () async {
                    await VibrationService().selectionVibration();
                    setState(() {
                      if (_rearrangeOrder.containsKey(actualIndex)) {
                        final removedOrder = _rearrangeOrder[actualIndex]!;
                        _rearrangeOrder.remove(actualIndex);
                        _rearrangeOrder.updateAll((key, value) {
                          if (value > removedOrder) return value - 1;
                          return value;
                        });
                        _nextRearrangeOrder--;
                      } else {
                        _rearrangeOrder[actualIndex] = _nextRearrangeOrder;
                        _nextRearrangeOrder++;
                      }
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || showCorrectOrder) ? 2 : 1,
                ),
                boxShadow: (isSelected || showCorrectOrder)
                    ? [
                        BoxShadow(
                          color: borderColor.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: kIsWeb ? 28 : 30.w,
                    height: kIsWeb ? 28 : 30.w,
                    decoration: BoxDecoration(
                      color: showCorrectOrder
                          ? Colors.green
                          : (isSelected ? _baseColor : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                    ),
                    child: Center(
                      child: showCorrectOrder
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
                                )),
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 12 : 12.w),
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: TextStyle(
                        fontSize: kIsWeb ? 12 : 15.sp,
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTooltip() {
    return Container(
      margin: EdgeInsets.only(top: kIsWeb ? 16 : 16.h),
      padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            color: Colors.amber[700],
            size: kIsWeb ? 20 : 20.sp,
          ),
          SizedBox(width: kIsWeb ? 12 : 12.w),
          Expanded(
            child: Text(
              _showSuccess || _showIncorrect ? _explanation : _hint,
              style: TextStyle(
                fontSize: kIsWeb ? 13 : 14.sp,
                color: Colors.amber[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final bool canCheck = _canCheckAnswer && !_showSuccess && !_showIncorrect;
    final bool showContinue = _showSuccess || _showIncorrect;

    return Container(
      padding: EdgeInsets.all(kIsWeb ? 14 : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: kIsWeb ? 0.3 : 1.0,
            child: SizedBox(
              height: kIsWeb ? 35 : 50.h,
              child: showContinue
                  ? _buildContinueButton()
                  : _buildCheckButton(canCheck),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckButton(bool canCheck) {
    return GestureDetector(
      onTapDown:
          canCheck ? (_) => setState(() => _isCheckButtonPressed = true) : null,
      onTapUp: canCheck
          ? (_) async {
              setState(() => _isCheckButtonPressed = false);
              await _checkAnswer();
            }
          : null,
      onTapCancel: () => setState(() => _isCheckButtonPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: canCheck ? _baseColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(kIsWeb ? 11 : 12.r),
          boxShadow: canCheck && !_isCheckButtonPressed
              ? [
                  BoxShadow(
                    color: _baseColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            'Check',
            style: TextStyle(
              fontSize: kIsWeb ? 16 : 16.sp,
              fontWeight: FontWeight.bold,
              color: canCheck ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isLastQuestion = _currentQuestionIndex >= _questions.length - 1;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isContinueButtonPressed = true),
      onTapUp: (_) async {
        setState(() => _isContinueButtonPressed = false);
        if (_isProcessingContinue) return;
        _isProcessingContinue = true;

        if (isLastQuestion) {
          await _completeTest();
        } else {
          await _goToNextQuestion();
        }

        _isProcessingContinue = false;
      },
      onTapCancel: () => setState(() => _isContinueButtonPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _showSuccess ? Colors.green : _baseColor,
          borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
          boxShadow: !_isContinueButtonPressed
              ? [
                  BoxShadow(
                    color: (_showSuccess ? Colors.green : _baseColor)
                        .withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            isLastQuestion ? 'Complete Test' : 'Continue',
            style: TextStyle(
              fontSize: kIsWeb ? 16 : 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAnswer() async {
    if (!_canCheckAnswer) return;

    _tries++;
    final isRearrange = _currentQuestion.isRearrange;
    final selectedOption =
        isRearrange ? null : _currentQuestion.options[_selectedAnswerIndex!];
    final isCorrect =
        isRearrange ? _isRearrangeAnswerCorrect : selectedOption!.isCorrect;
    final answerId = isRearrange
        ? _selectedRearrangeOptionIds.join(',')
        : selectedOption!.id;

    // Call API to check answer
    await _apiService.checkAnswer(
      testId: widget.test.id,
      questionId: _currentQuestion.id,
      answerId: answerId,
      tries: _tries,
      isCorrect: isCorrect,
    );

    setState(() {
      if (isCorrect) {
        _showSuccess = true;
        _showConfetti = true;
        _showTooltip = true;
        // SoundService().playCorrectAnswer();
        VibrationService().successVibration();

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _showConfetti = false;
            });
          }
        });
      } else {
        _showIncorrect = true;
        _showShock = true;
        if (!isRearrange && _selectedAnswerIndex != null) {
          _disabledOptionIndices.add(_selectedAnswerIndex!);
        }
        // SoundService().playIncorrectAnswer();
        VibrationService().errorVibration();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showShock = false;
            });
          }
        });

        // Show tooltip with explanation
        _showTooltip = true;
      }
    });
  }

  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _selectedAnswerIndices = {};
        _showSuccess = false;
        _showIncorrect = false;
        _showTooltip = false;
        _tries = 0;
        _disabledOptionIndices = {};
        _shortAnswerText = '';
        _shortAnswerController.clear();
        _rearrangeOrder = {};
        _nextRearrangeOrder = 1;
      });

      _shuffleOptions();
      _startOptionAnimations();
    }
  }

  Future<void> _completeTest() async {
    try {
      await _apiService.completeTest(widget.test.id);

      // Play success sound
      // SoundService().playSuccess();
      VibrationService().successVibration();

      if (mounted) {
        // Show completion dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: kIsWeb ? 64 : 64.sp,
                  color: Colors.amber,
                ),
                SizedBox(height: kIsWeb ? 16 : 16.h),
                const Text('Test Completed!'),
              ],
            ),
            content: Text(
              'Congratulations! You have completed the test.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: kIsWeb ? 14 : 14.sp,
                color: Colors.grey[600],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(
                        context,
                        widget
                            .test.id); // Return to subject screen with test ID
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: kIsWeb ? 12 : 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: kIsWeb ? 16 : 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error completing test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing test: $e')),
        );
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
        ),
        title: const Text('Exit Test?'),
        content: const Text(
            'Your progress will be saved, but you will need to continue from where you left off.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit test
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
