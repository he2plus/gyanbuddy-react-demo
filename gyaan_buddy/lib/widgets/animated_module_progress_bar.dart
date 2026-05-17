import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/module_status.dart';

/// A widget that displays an animated progress bar for module completion.
/// 
/// Animates smoothly from [previousPercentage] to [percentage] when values differ.
/// When the module reaches 100% completion, shows a celebration animation
/// with the progress bar filling and a checkmark scaling up.
class AnimatedModuleProgressBar extends StatefulWidget {
  final String moduleId;
  final ModuleStatus status;
  final double percentage; // Current/updated percentage
  final Color progressColor;
  final double? previousPercentage; // Previous percentage for animation reference
  final VoidCallback? onCompletionAnimationDone;

  const AnimatedModuleProgressBar({
    super.key,
    required this.moduleId,
    required this.status,
    required this.percentage,
    required this.progressColor,
    this.previousPercentage,
    this.onCompletionAnimationDone,
  });

  @override
  State<AnimatedModuleProgressBar> createState() => _AnimatedModuleProgressBarState();
}

class _AnimatedModuleProgressBarState extends State<AnimatedModuleProgressBar>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _checkmarkController;
  late AnimationController _celebrationController;
  late AnimationController _percentageTextController;
  
  // Animations
  late Animation<double> _progressAnimation;
  late Animation<double> _checkmarkScaleAnimation;
  late Animation<double> _checkmarkOpacityAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _percentageTextAnimation;
  
  // State
  double _fromPercentage = 0;
  double _toPercentage = 0;
  bool _showCheckmark = false;
  bool _hasAnimatedCompletion = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _setupStaticAnimations();
    _initializeValues();
  }

  void _initControllers() {
    // Progress bar fill animation - 1 second for smooth visual
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Checkmark scale animation
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Celebration pulse animation
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Percentage text counter animation
    _percentageTextController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _setupStaticAnimations() {
    // Elastic scale animation for checkmark (bouncy entrance)
    _checkmarkScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_checkmarkController);
    
    _checkmarkOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );
    
    // Celebration pulse animation
    _celebrationAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Add listeners for rebuilds
    _progressController.addListener(_onAnimationTick);
    _checkmarkController.addListener(_onAnimationTick);
    _percentageTextController.addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    if (mounted) setState(() {});
  }

  void _initializeValues() {
    // Determine starting and ending percentages
    final hasPrevious = widget.previousPercentage != null;
    final previousValue = widget.previousPercentage ?? 0;
    final currentValue = widget.percentage;
    
    // Check if we need to animate (previous is different and less than current)
    final shouldAnimate = hasPrevious && 
                          previousValue < currentValue && 
                          previousValue != currentValue;
    
    if (shouldAnimate) {
      // Set up animation from previous to current
      _fromPercentage = previousValue;
      _toPercentage = currentValue;
      
      // Start animation after frame renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startProgressAnimation();
        }
      });
    } else {
      // No animation needed, show current value directly
      _fromPercentage = currentValue;
      _toPercentage = currentValue;
      
      // If already completed, show checkmark without animation
      if (widget.status == ModuleStatus.completed) {
        _showCheckmark = true;
        _hasAnimatedCompletion = true;
      }
    }
  }

  void _startProgressAnimation() {
    _isAnimating = true;
    
    // Create the progress animation from previous to current
    _progressAnimation = Tween<double>(
      begin: _fromPercentage,
      end: _toPercentage,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Create percentage text animation (same values)
    _percentageTextAnimation = Tween<double>(
      begin: _fromPercentage,
      end: _toPercentage,
    ).animate(
      CurvedAnimation(
        parent: _percentageTextController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Start both animations together
    _progressController.forward(from: 0);
    _percentageTextController.forward(from: 0);
    
    // When progress animation completes
    _progressController.addStatusListener(_onProgressComplete);
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _progressController.removeStatusListener(_onProgressComplete);
      
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _fromPercentage = _toPercentage;
        });
        
        // If reached 100%, trigger completion animation
        if (_toPercentage >= 100 && !_hasAnimatedCompletion) {
          _hasAnimatedCompletion = true;
          _triggerCompletionAnimation();
        }
      }
    }
  }

  void _triggerCompletionAnimation() async {
    // Small delay before showing checkmark
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;
    
    setState(() {
      _showCheckmark = true;
    });
    
    // Start checkmark scale animation
    _checkmarkController.forward(from: 0).then((_) {
      if (!mounted) return;
      
      // Trigger celebration pulse
      _celebrationController.forward().then((_) {
        if (!mounted) return;
        _celebrationController.reverse();
        widget.onCompletionAnimationDone?.call();
      });
    });
  }

  @override
  void didUpdateWidget(AnimatedModuleProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if we received new values that need animation
    final hasNewPreviousValue = widget.previousPercentage != null &&
                                 oldWidget.previousPercentage != widget.previousPercentage;
    
    final percentageIncreased = widget.percentage > _toPercentage;
    
    if (hasNewPreviousValue && widget.previousPercentage! < widget.percentage) {
      // New animation needed: animate from previous to current
      _fromPercentage = widget.previousPercentage!;
      _toPercentage = widget.percentage;
      _startProgressAnimation();
    } else if (percentageIncreased && !_isAnimating) {
      // Percentage increased without previous value - animate from current display to new
      _fromPercentage = _toPercentage;
      _toPercentage = widget.percentage;
      _startProgressAnimation();
    }
    
    // Handle status change to completed
    if (widget.status == ModuleStatus.completed && 
        oldWidget.status != ModuleStatus.completed &&
        !_hasAnimatedCompletion) {
      if (!_isAnimating) {
        _fromPercentage = _toPercentage;
        _toPercentage = 100;
        _startProgressAnimation();
      }
    }
  }

  @override
  void dispose() {
    _progressController.removeListener(_onAnimationTick);
    _checkmarkController.removeListener(_onAnimationTick);
    _percentageTextController.removeListener(_onAnimationTick);
    _progressController.dispose();
    _checkmarkController.dispose();
    _celebrationController.dispose();
    _percentageTextController.dispose();
    super.dispose();
  }

  /// Get the current displayed percentage (animated or static)
  double get _currentPercentage {
    if (_isAnimating && _progressController.isAnimating) {
      return _progressAnimation.value;
    }
    return _toPercentage;
  }

  @override
  Widget build(BuildContext context) {
    final displayPercentage = _currentPercentage;
    final progressFactor = (displayPercentage / 100).clamp(0.0, 1.0);
    
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progressWidth = constraints.maxWidth * progressFactor;
              
              return AnimatedBuilder(
                animation: _celebrationAnimation,
                builder: (context, child) {
                  final scale = _celebrationController.isAnimating 
                      ? _celebrationAnimation.value 
                      : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: Stack(
                      children: [
                        // Background track
                        Container(
                          height: kIsWeb ? 4 : 4.h,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        // Progress fill
                        Container(
                          height: kIsWeb ? 4 : 4.h,
                          width: progressWidth,
                          decoration: BoxDecoration(
                            color: widget.progressColor,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: _showCheckmark
                                ? [
                                    BoxShadow(
                                      color: widget.progressColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(width: kIsWeb ? 8 : 8.w),
        // Percentage text or checkmark
        _buildPercentageIndicator(),
      ],
    );
  }

  Widget _buildPercentageIndicator() {
    // Show checkmark for completed modules
    if (_showCheckmark || widget.status == ModuleStatus.completed) {
      return AnimatedBuilder(
        animation: _checkmarkScaleAnimation,
        builder: (context, child) {
          final scale = _checkmarkController.isAnimating
              ? _checkmarkScaleAnimation.value
              : 1.0;
          final opacity = _checkmarkController.isAnimating
              ? _checkmarkOpacityAnimation.value.clamp(0.0, 1.0)
              : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: kIsWeb ? 20 : 20.w,
                height: kIsWeb ? 20 : 20.h,
                decoration: BoxDecoration(
                  color: widget.progressColor,
                  shape: BoxShape.circle,
                  boxShadow: _checkmarkController.isAnimating
                      ? [
                          BoxShadow(
                            color: widget.progressColor.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: widget.progressColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: Icon(
                  Icons.check,
                  size: kIsWeb ? 14 : 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );
    }
    
    // Animated percentage text
    final displayPercentage = _isAnimating && _percentageTextController.isAnimating
        ? _percentageTextAnimation.value
        : _toPercentage;
    
    return Text(
      '${displayPercentage.toInt()}%',
      style: TextStyle(
        fontSize: kIsWeb ? 14 : 14.sp,
        fontWeight: FontWeight.w600,
        color: widget.progressColor,
      ),
    );
  }
}

/// A service to track and store previous module percentages
/// for animating progress changes when navigating back to subject screen.
class ModuleProgressTracker {
  static final ModuleProgressTracker _instance = ModuleProgressTracker._internal();
  factory ModuleProgressTracker() => _instance;
  ModuleProgressTracker._internal();
  
  // Map of moduleId -> previous percentage
  final Map<String, double> _previousPercentages = {};
  
  // Map of moduleId -> whether completion animation has been shown
  final Map<String, bool> _completionAnimationShown = {};
  
  /// Get the previous percentage for a module
  double? getPreviousPercentage(String moduleId) {
    return _previousPercentages[moduleId];
  }
  
  /// Update the stored percentage for a module
  void updatePercentage(String moduleId, double percentage) {
    _previousPercentages[moduleId] = percentage;
  }
  
  /// Check if a module needs progress animation
  bool needsProgressAnimation(String moduleId, double currentPercentage) {
    final previous = _previousPercentages[moduleId];
    return previous != null && previous < currentPercentage;
  }
  
  /// Mark completion animation as shown for a module
  void markCompletionAnimationShown(String moduleId) {
    _completionAnimationShown[moduleId] = true;
  }
  
  /// Check if completion animation has been shown
  bool hasShownCompletionAnimation(String moduleId) {
    return _completionAnimationShown[moduleId] ?? false;
  }
  
  /// Clear all stored data (useful when user logs out or clears cache)
  void clear() {
    _previousPercentages.clear();
    _completionAnimationShown.clear();
  }
  
  /// Store current percentages before navigation
  void storeCurrentPercentages(List<MapEntry<String, double>> modules) {
    for (final entry in modules) {
      _previousPercentages[entry.key] = entry.value;
    }
  }
}
