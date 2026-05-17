import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Brilliant-inspired animation utilities that focus on:
/// 1. Progressive revelation of information
/// 2. Interactive problem-solving feedback
/// 3. Smooth micro-interactions
/// 4. Adaptive animations based on user performance
class BrilliantAnimations {
  
  // Progressive reveal animation - shows content step by step
  static Widget progressiveReveal({
    required List<Widget> steps,
    required VoidCallback onStepComplete,
    Duration stepDelay = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
  }) {
    return ProgressiveReveal(
      steps: steps,
      onStepComplete: onStepComplete,
      stepDelay: stepDelay,
      curve: curve,
    );
  }

  // Interactive problem-solving widget with Brilliant-style feedback
  static Widget interactiveProblem({
    required Widget problem,
    required Widget solution,
    required VoidCallback onSolve,
    bool showHint = false,
    Duration revealDuration = const Duration(milliseconds: 1200),
  }) {
    return InteractiveProblem(
      problem: problem,
      solution: solution,
      onSolve: onSolve,
      showHint: showHint,
      revealDuration: revealDuration,
    );
  }

  // Step-by-step solution reveal
  static Widget stepByStepSolution({
    required List<SolutionStep> steps,
    required VoidCallback onComplete,
    Duration stepDuration = const Duration(milliseconds: 1000),
  }) {
    return StepByStepSolution(
      steps: steps,
      onComplete: onComplete,
      stepDuration: stepDuration,
    );
  }

  // Adaptive celebration based on performance
  static Widget adaptiveCelebration({
    required double performanceScore, // 0.0 to 1.0
    required VoidCallback onComplete,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return AdaptiveCelebration(
      performanceScore: performanceScore,
      onComplete: onComplete,
      duration: duration,
    );
  }

  // Micro-interaction for button presses
  static Widget microInteraction({
    required Widget child,
    required VoidCallback onTap,
    MicroInteractionType type = MicroInteractionType.scale,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return MicroInteraction(
      child: child,
      onTap: onTap,
      type: type,
      duration: duration,
    );
  }

  // Visual thinking process animation
  static Widget thinkingProcess({
    required List<String> thoughts,
    required VoidCallback onComplete,
    Duration thoughtDelay = const Duration(milliseconds: 1200),
  }) {
    return ThinkingProcess(
      thoughts: thoughts,
      onComplete: onComplete,
      thoughtDelay: thoughtDelay,
    );
  }

  // Brilliant-style progress indicator
  static Widget brilliantProgress({
    required double value,
    required int totalSteps,
    Color primaryColor = Colors.blue,
    Color secondaryColor = Colors.grey,
    Duration animationDuration = const Duration(milliseconds: 800),
  }) {
    return BrilliantProgress(
      value: value,
      totalSteps: totalSteps,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      animationDuration: animationDuration,
    );
  }

  // Smooth content morphing (like Brilliant's explanations)
  static Widget contentMorph({
    required Widget from,
    required Widget to,
    Duration duration = const Duration(milliseconds: 1000),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return ContentMorph(
      from: from,
      to: to,
      duration: duration,
      curve: curve,
    );
  }
}

enum MicroInteractionType {
  scale,
  ripple,
  glow,
  bounce,
  tilt,
}

class SolutionStep {
  final String title;
  final Widget content;
  final String? explanation;
  final Duration? customDuration;

  SolutionStep({
    required this.title,
    required this.content,
    this.explanation,
    this.customDuration,
  });
}

// Progressive Reveal Widget
class ProgressiveReveal extends StatefulWidget {
  final List<Widget> steps;
  final VoidCallback onStepComplete;
  final Duration stepDelay;
  final Curve curve;

  const ProgressiveReveal({
    super.key,
    required this.steps,
    required this.onStepComplete,
    this.stepDelay = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ProgressiveReveal> createState() => _ProgressiveRevealState();
}

class _ProgressiveRevealState extends State<ProgressiveReveal>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startProgressiveReveal();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.steps.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();
  }

  void _startProgressiveReveal() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.stepDelay * i, () {
        if (mounted && i < _controllers.length) {
          _controllers[i].forward().then((_) {
            if (i == _controllers.length - 1) {
              widget.onStepComplete();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.steps.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacityAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: widget.steps[index],
              ),
            );
          },
        );
      }),
    );
  }
}

// Interactive Problem Widget
class InteractiveProblem extends StatefulWidget {
  final Widget problem;
  final Widget solution;
  final VoidCallback onSolve;
  final bool showHint;
  final Duration revealDuration;

  const InteractiveProblem({
    super.key,
    required this.problem,
    required this.solution,
    required this.onSolve,
    this.showHint = false,
    this.revealDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<InteractiveProblem> createState() => _InteractiveProblemState();
}

class _InteractiveProblemState extends State<InteractiveProblem>
    with TickerProviderStateMixin {
  late AnimationController _problemController;
  late AnimationController _solutionController;
  late AnimationController _hintController;
  
  late Animation<double> _problemOpacity;
  late Animation<Offset> _problemSlide;
  late Animation<double> _solutionOpacity;
  late Animation<double> _solutionScale;
  late Animation<double> _hintOpacity;

  bool _isSolved = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startProblemAnimation();
  }

  void _initializeAnimations() {
    _problemController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _solutionController = AnimationController(
      duration: widget.revealDuration,
      vsync: this,
    );
    
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _problemOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _problemController,
      curve: Curves.easeOutCubic,
    ));

    _problemSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _problemController,
      curve: Curves.easeOutCubic,
    ));

    _solutionOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _solutionController,
      curve: Curves.easeOutCubic,
    ));

    _solutionScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _solutionController,
      curve: Curves.elasticOut,
    ));

    _hintOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOut,
    ));
  }

  void _startProblemAnimation() {
    _problemController.forward();
  }

  void _solveProblem() {
    setState(() {
      _isSolved = true;
    });
    
    _solutionController.forward().then((_) {
      widget.onSolve();
    });
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });
    
    if (_showHint) {
      _hintController.forward();
    } else {
      _hintController.reverse();
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _solutionController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Problem Section
        AnimatedBuilder(
          animation: _problemController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _problemOpacity,
              child: SlideTransition(
                position: _problemSlide,
                child: widget.problem,
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Hint Section
        if (widget.showHint)
          AnimatedBuilder(
            animation: _hintController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _hintOpacity,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Think about the key concepts involved...',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          children: [
            if (widget.showHint)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleHint,
                  icon: Icon(_showHint ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade100,
                    foregroundColor: Colors.amber.shade800,
                  ),
                ),
              ),
            if (widget.showHint) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSolved ? null : _solveProblem,
                child: Text(_isSolved ? 'Solved!' : 'Solve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSolved ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Solution Section
        if (_isSolved)
          AnimatedBuilder(
            animation: _solutionController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _solutionOpacity,
                child: ScaleTransition(
                  scale: _solutionScale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: widget.solution,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Step-by-Step Solution Widget
class StepByStepSolution extends StatefulWidget {
  final List<SolutionStep> steps;
  final VoidCallback onComplete;
  final Duration stepDuration;

  const StepByStepSolution({
    super.key,
    required this.steps,
    required this.onComplete,
    this.stepDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<StepByStepSolution> createState() => _StepByStepSolutionState();
}

class _StepByStepSolutionState extends State<StepByStepSolution>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _scaleAnimations;
  
  int _currentStep = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStepAnimation();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.steps.length,
      (index) => AnimationController(
        duration: widget.steps[index].customDuration ?? widget.stepDuration,
        vsync: this,
      ),
    );

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();
  }

  void _startStepAnimation() {
    _animateNextStep();
  }

  void _animateNextStep() {
    if (_currentStep < _controllers.length) {
      _controllers[_currentStep].forward().then((_) {
        setState(() {
          _currentStep++;
        });
        
        if (_currentStep < _controllers.length) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _animateNextStep();
          });
        } else {
          setState(() {
            _isComplete = true;
          });
          widget.onComplete();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: List.generate(widget.steps.length, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < widget.steps.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green 
                        : isActive 
                            ? Colors.blue 
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Steps
        ...List.generate(widget.steps.length, (index) {
          final step = widget.steps[index];
          final isVisible = index <= _currentStep;
          
          if (!isVisible) return const SizedBox.shrink();
          
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacityAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: ScaleTransition(
                    scale: _scaleAnimations[index],
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          step.content,
                          if (step.explanation != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              step.explanation!,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// Adaptive Celebration Widget
class AdaptiveCelebration extends StatefulWidget {
  final double performanceScore;
  final VoidCallback onComplete;
  final Duration duration;

  const AdaptiveCelebration({
    super.key,
    required this.performanceScore,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<AdaptiveCelebration> createState() => _AdaptiveCelebrationState();
}

class _AdaptiveCelebrationState extends State<AdaptiveCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  
  String get _celebrationText {
    if (widget.performanceScore >= 0.9) return 'Outstanding!';
    if (widget.performanceScore >= 0.7) return 'Great job!';
    if (widget.performanceScore >= 0.5) return 'Good work!';
    return 'Keep trying!';
  }
  
  Color get _celebrationColor {
    if (widget.performanceScore >= 0.9) return Colors.purple;
    if (widget.performanceScore >= 0.7) return Colors.green;
    if (widget.performanceScore >= 0.5) return Colors.blue;
    return Colors.orange;
  }
  
  IconData get _celebrationIcon {
    if (widget.performanceScore >= 0.9) return Icons.star;
    if (widget.performanceScore >= 0.7) return Icons.celebration;
    if (widget.performanceScore >= 0.5) return Icons.thumb_up;
    return Icons.trending_up;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward().then((_) {
      widget.onComplete();
    });
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
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _celebrationColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _celebrationColor.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _celebrationIcon,
                      size: 48,
                      color: _celebrationColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _celebrationText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _celebrationColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${(widget.performanceScore * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: _celebrationColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Micro Interaction Widget
class MicroInteraction extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final MicroInteractionType type;
  final Duration duration;

  const MicroInteraction({
    super.key,
    required this.child,
    required this.onTap,
    this.type = MicroInteractionType.scale,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<MicroInteraction> createState() => _MicroInteractionState();
}

class _MicroInteractionState extends State<MicroInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    switch (widget.type) {
      case MicroInteractionType.scale:
        _animation = Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
      case MicroInteractionType.bounce:
        _animation = Tween<double>(
          begin: 1.0,
          end: 1.1,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.elasticOut,
        ));
        break;
      case MicroInteractionType.tilt:
        _animation = Tween<double>(
          begin: 0.0,
          end: 0.1,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
      default:
        _animation = Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
    }
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          switch (widget.type) {
            case MicroInteractionType.scale:
            case MicroInteractionType.bounce:
              return Transform.scale(
                scale: _animation.value,
                child: widget.child,
              );
            case MicroInteractionType.tilt:
              return Transform.rotate(
                angle: _animation.value,
                child: widget.child,
              );
            default:
              return Transform.scale(
                scale: _animation.value,
                child: widget.child,
              );
          }
        },
      ),
    );
  }
}

// Thinking Process Widget
class ThinkingProcess extends StatefulWidget {
  final List<String> thoughts;
  final VoidCallback onComplete;
  final Duration thoughtDelay;

  const ThinkingProcess({
    super.key,
    required this.thoughts,
    required this.onComplete,
    this.thoughtDelay = const Duration(milliseconds: 1200),
  });

  @override
  State<ThinkingProcess> createState() => _ThinkingProcessState();
}

class _ThinkingProcessState extends State<ThinkingProcess>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentThought = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _startThinkingProcess();
  }

  void _startThinkingProcess() {
    _showNextThought();
  }

  void _showNextThought() {
    if (_currentThought < widget.thoughts.length) {
      _controller.forward().then((_) {
        Future.delayed(widget.thoughtDelay, () {
          if (mounted) {
            setState(() {
              _currentThought++;
            });
            
            if (_currentThought < widget.thoughts.length) {
              _controller.reset();
              _showNextThought();
            } else {
              widget.onComplete();
            }
          }
        });
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
    if (_currentThought >= widget.thoughts.length) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.thoughts[_currentThought],
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Brilliant Progress Widget
class BrilliantProgress extends StatefulWidget {
  final double value;
  final int totalSteps;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration animationDuration;

  const BrilliantProgress({
    super.key,
    required this.value,
    required this.totalSteps,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.grey,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<BrilliantProgress> createState() => _BrilliantProgressState();
}

class _BrilliantProgressState extends State<BrilliantProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value,
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
    return Column(
      children: [
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: widget.secondaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
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
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.totalSteps, (index) {
            final isActive = (index + 1) / widget.totalSteps <= widget.value;
            
            return AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive ? widget.primaryColor : widget.secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// Content Morph Widget
class ContentMorph extends StatefulWidget {
  final Widget from;
  final Widget to;
  final Duration duration;
  final Curve curve;

  const ContentMorph({
    super.key,
    required this.from,
    required this.to,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  State<ContentMorph> createState() => _ContentMorphState();
}

class _ContentMorphState extends State<ContentMorph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _morphAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
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
    return AnimatedBuilder(
      animation: _morphAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // From widget (fading out)
            Opacity(
              opacity: 1.0 - _morphAnimation.value,
              child: Transform.scale(
                scale: 1.0 - _morphAnimation.value * 0.1,
                child: widget.from,
              ),
            ),
            
            // To widget (fading in)
            Opacity(
              opacity: _morphAnimation.value,
              child: Transform.scale(
                scale: 0.9 + _morphAnimation.value * 0.1,
                child: widget.to,
              ),
            ),
          ],
        );
      },
    );
  }
}
