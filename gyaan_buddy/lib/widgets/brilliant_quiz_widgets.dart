import 'package:flutter/material.dart';
import '../utils/brilliant_animations.dart';
import '../utils/game_animations.dart';
import '../services/sound_service.dart';
import '../services/vibration_service.dart';

/// Brilliant-inspired quiz widgets that enhance the learning experience
/// with progressive revelation, interactive problem-solving, and adaptive feedback
class BrilliantQuizWidgets {
  
  // Enhanced answer option with Brilliant-style interactions
  static Widget brilliantAnswerOption({
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required VoidCallback onTap,
    required int index,
    String? explanation,
  }) {
    return BrilliantAnswerOption(
      text: text,
      isSelected: isSelected,
      isCorrect: isCorrect,
      showResult: showResult,
      onTap: onTap,
      index: index,
      explanation: explanation,
    );
  }

  // Progressive question reveal
  static Widget progressiveQuestion({
    required String question,
    required List<String> hints,
    required VoidCallback onHintRequested,
    Duration revealDelay = const Duration(milliseconds: 800),
  }) {
    return ProgressiveQuestion(
      question: question,
      hints: hints,
      onHintRequested: onHintRequested,
      revealDelay: revealDelay,
    );
  }

  // Interactive solution explanation
  static Widget interactiveSolution({
    required List<SolutionStep> solutionSteps,
    required VoidCallback onComplete,
    bool showThinkingProcess = true,
  }) {
    return InteractiveSolution(
      solutionSteps: solutionSteps,
      onComplete: onComplete,
      showThinkingProcess: showThinkingProcess,
    );
  }

  // Adaptive feedback based on performance
  static Widget adaptiveFeedback({
    required bool isCorrect,
    required double timeSpent,
    required int attempts,
    required VoidCallback onContinue,
  }) {
    return AdaptiveFeedback(
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      attempts: attempts,
      onContinue: onContinue,
    );
  }

  // Brilliant-style progress indicator
  static Widget brilliantQuizProgress({
    required int currentQuestion,
    required int totalQuestions,
    required double overallProgress,
    Color primaryColor = Colors.blue,
  }) {
    return BrilliantQuizProgress(
      currentQuestion: currentQuestion,
      totalQuestions: totalQuestions,
      overallProgress: overallProgress,
      primaryColor: primaryColor,
    );
  }

  // Interactive concept explanation
  static Widget conceptExplanation({
    required String concept,
    required String explanation,
    required List<String> examples,
    required VoidCallback onComplete,
  }) {
    return ConceptExplanation(
      concept: concept,
      explanation: explanation,
      examples: examples,
      onComplete: onComplete,
    );
  }
}

// Brilliant Answer Option Widget
class BrilliantAnswerOption extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;
  final int index;
  final String? explanation;

  const BrilliantAnswerOption({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
    required this.index,
    this.explanation,
  });

  @override
  State<BrilliantAnswerOption> createState() => _BrilliantAnswerOptionState();
}

class _BrilliantAnswerOptionState extends State<BrilliantAnswerOption>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
  late AnimationController _resultController;
  late AnimationController _explanationController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _resultScaleAnimation;
  late Animation<double> _explanationOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _explanationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));

    _resultScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    ));

    _explanationOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _explanationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(BrilliantAnswerOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected && !oldWidget.isSelected) {
      _selectionController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _selectionController.reverse();
    }
    
    if (widget.showResult && !oldWidget.showResult) {
      _resultController.forward();
      if (widget.explanation != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _explanationController.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _resultController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (!widget.showResult) {
      return widget.isSelected ? Colors.blue.shade50 : Colors.white;
    }
    
    if (widget.isCorrect) {
      return Colors.green.shade50;
    } else if (widget.isSelected) {
      return Colors.red.shade50;
    }
    return Colors.grey.shade50;
  }

  Color get _borderColor {
    if (!widget.showResult) {
      return widget.isSelected ? Colors.blue : Colors.grey.shade300;
    }
    
    if (widget.isCorrect) {
      return Colors.green;
    } else if (widget.isSelected) {
      return Colors.red;
    }
    return Colors.grey.shade300;
  }

  IconData? get _resultIcon {
    if (!widget.showResult) return null;
    
    if (widget.isCorrect) {
      return Icons.check_circle;
    } else if (widget.isSelected) {
      return Icons.cancel;
    }
    return null;
  }

  Color get _resultIconColor {
    if (widget.isCorrect) return Colors.green;
    if (widget.isSelected) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return BrilliantAnimations.microInteraction(
      type: MicroInteractionType.scale,
      onTap: () async {
        // await SoundService().playButtonClick();
        await VibrationService().selectionVibration();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _selectionController,
          _resultController,
          _explanationController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColor,
                  width: 2,
                ),
                boxShadow: [
                  if (widget.isSelected || widget.showResult)
                    BoxShadow(
                      color: _borderColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Option letter/number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + widget.index), // A, B, C, D
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Answer text
                        Expanded(
                          child: Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        
                        // Result icon
                        if (_resultIcon != null)
                          Transform.scale(
                            scale: _resultScaleAnimation.value,
                            child: Icon(
                              _resultIcon,
                              color: _resultIconColor,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Explanation (if available and showing result)
                  if (widget.explanation != null && widget.showResult)
                    FadeTransition(
                      opacity: _explanationOpacityAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.explanation!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade800,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}

// Progressive Question Widget
class ProgressiveQuestion extends StatefulWidget {
  final String question;
  final List<String> hints;
  final VoidCallback onHintRequested;
  final Duration revealDelay;

  const ProgressiveQuestion({
    super.key,
    required this.question,
    required this.hints,
    required this.onHintRequested,
    this.revealDelay = const Duration(milliseconds: 800),
  });

  @override
  State<ProgressiveQuestion> createState() => _ProgressiveQuestionState();
}

class _ProgressiveQuestionState extends State<ProgressiveQuestion>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentHintIndex = 0;
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  void _requestHint() {
    setState(() {
      _showHints = true;
    });
    widget.onHintRequested();
  }

  void _showNextHint() {
    if (_currentHintIndex < widget.hints.length - 1) {
      setState(() {
        _currentHintIndex++;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Hint section
                if (_showHints) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hint ${_currentHintIndex + 1} of ${widget.hints.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.hints[_currentHintIndex],
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (_currentHintIndex < widget.hints.length - 1) ...[
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _showNextHint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade100,
                              foregroundColor: Colors.amber.shade800,
                            ),
                            child: const Text('Next Hint'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // Hint request button
                  ElevatedButton.icon(
                    onPressed: _requestHint,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Need a hint?'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade100,
                      foregroundColor: Colors.amber.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Interactive Solution Widget
class InteractiveSolution extends StatefulWidget {
  final List<SolutionStep> solutionSteps;
  final VoidCallback onComplete;
  final bool showThinkingProcess;

  const InteractiveSolution({
    super.key,
    required this.solutionSteps,
    required this.onComplete,
    this.showThinkingProcess = true,
  });

  @override
  State<InteractiveSolution> createState() => _InteractiveSolutionState();
}

class _InteractiveSolutionState extends State<InteractiveSolution> {
  bool _showSolution = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_showSolution) ...[
          // Show solution button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showSolution = true;
              });
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Show Solution'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade100,
              foregroundColor: Colors.green.shade800,
            ),
          ),
        ] else ...[
          // Solution steps
          BrilliantAnimations.stepByStepSolution(
            steps: widget.solutionSteps,
            onComplete: widget.onComplete,
          ),
        ],
      ],
    );
  }
}

// Adaptive Feedback Widget
class AdaptiveFeedback extends StatefulWidget {
  final bool isCorrect;
  final double timeSpent; // in seconds
  final int attempts;
  final VoidCallback onContinue;

  const AdaptiveFeedback({
    super.key,
    required this.isCorrect,
    required this.timeSpent,
    required this.attempts,
    required this.onContinue,
  });

  @override
  State<AdaptiveFeedback> createState() => _AdaptiveFeedbackState();
}

class _AdaptiveFeedbackState extends State<AdaptiveFeedback> {
  double get _performanceScore {
    double score = 0.0;
    
    // Base score for correctness
    if (widget.isCorrect) {
      score += 0.6;
      
      // Bonus for speed (under 30 seconds)
      if (widget.timeSpent < 30) {
        score += 0.2;
      }
      
      // Bonus for first attempt
      if (widget.attempts == 1) {
        score += 0.2;
      }
    } else {
      // Partial credit for persistence
      if (widget.attempts <= 3) {
        score += 0.3;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  String get _feedbackMessage {
    if (widget.isCorrect) {
      if (widget.attempts == 1 && widget.timeSpent < 30) {
        return 'Excellent! You solved it quickly and correctly!';
      } else if (widget.attempts == 1) {
        return 'Great job! You got it right on the first try!';
      } else if (widget.timeSpent < 30) {
        return 'Well done! You solved it quickly!';
      } else {
        return 'Good work! You got the correct answer!';
      }
    } else {
      return 'Keep trying! Learning takes practice.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Adaptive celebration
        BrilliantAnimations.adaptiveCelebration(
          performanceScore: _performanceScore,
          onComplete: () {},
        ),
        
        const SizedBox(height: 16),
        
        // Feedback message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            _feedbackMessage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat('Time', '${widget.timeSpent.toInt()}s'),
            _buildStat('Attempts', '${widget.attempts}'),
            _buildStat('Score', '${(_performanceScore * 100).toInt()}%'),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Continue button
        ElevatedButton(
          onPressed: widget.onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// Brilliant Quiz Progress Widget
class BrilliantQuizProgress extends StatefulWidget {
  final int currentQuestion;
  final int totalQuestions;
  final double overallProgress;
  final Color primaryColor;

  const BrilliantQuizProgress({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.overallProgress,
    this.primaryColor = Colors.blue,
  });

  @override
  State<BrilliantQuizProgress> createState() => _BrilliantQuizProgressState();
}

class _BrilliantQuizProgressState extends State<BrilliantQuizProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.overallProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Question counter and progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${widget.currentQuestion} of ${widget.totalQuestions}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(widget.overallProgress * 100).toInt()}% Complete',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Concept Explanation Widget
class ConceptExplanation extends StatefulWidget {
  final String concept;
  final String explanation;
  final List<String> examples;
  final VoidCallback onComplete;

  const ConceptExplanation({
    super.key,
    required this.concept,
    required this.explanation,
    required this.examples,
    required this.onComplete,
  });

  @override
  State<ConceptExplanation> createState() => _ConceptExplanationState();
}

class _ConceptExplanationState extends State<ConceptExplanation> {
  int _currentExampleIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Concept title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.school,
                color: Colors.purple.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.concept,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Explanation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            widget.explanation,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Examples
        if (widget.examples.isNotEmpty) ...[
          Text(
            'Examples:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.examples[_currentExampleIndex],
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                
                if (widget.examples.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Example ${_currentExampleIndex + 1} of ${widget.examples.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (_currentExampleIndex > 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentExampleIndex--;
                            });
                          },
                          child: const Text('Previous'),
                        ),
                      if (_currentExampleIndex < widget.examples.length - 1)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentExampleIndex++;
                            });
                          },
                          child: const Text('Next'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Complete button
        ElevatedButton(
          onPressed: widget.onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Got it!'),
        ),
      ],
    );
  }
}
