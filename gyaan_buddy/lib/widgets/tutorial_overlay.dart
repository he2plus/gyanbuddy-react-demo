import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../services/vibration_service.dart';

/// A single step in a tutorial sequence
class TutorialStep {
  /// Key of the widget to highlight
  final GlobalKey targetKey;
  
  /// Title for this step
  final String title;
  
  /// Description text
  final String description;
  
  /// Optional icon to show
  final IconData? icon;
  
  /// Position of the tooltip relative to the target
  final TooltipPosition tooltipPosition;
  
  /// Optional custom shape for the highlight
  final HighlightShape shape;
  
  /// Padding around the highlighted area
  final double highlightPadding;

  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon,
    this.tooltipPosition = TooltipPosition.bottom,
    this.shape = HighlightShape.roundedRect,
    this.highlightPadding = 8.0,
  });
}

enum TooltipPosition { top, bottom, left, right, center }
enum HighlightShape { circle, roundedRect, rect }

/// Tutorial overlay that shows spotlight effects and tooltips
class TutorialOverlay extends StatefulWidget {
  /// List of tutorial steps to show
  final List<TutorialStep> steps;
  
  /// Called when tutorial is completed or skipped
  final VoidCallback onComplete;
  
  /// Overlay color (default is semi-transparent black)
  final Color overlayColor;
  
  /// Accent color for buttons and highlights
  final Color accentColor;
  
  /// Whether to show skip button
  final bool showSkipButton;
  
  /// Whether to animate the spotlight
  final bool animateSpotlight;
  
  /// Extra bottom padding for step indicator (to avoid bottom nav bars)
  final double bottomPadding;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.overlayColor = const Color(0xDD000000),
    this.accentColor = const Color(0xFF00D4FF),
    this.showSkipButton = true,
    this.animateSpotlight = true,
    this.bottomPadding = 0,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  // Target widget info
  Rect? _targetRect;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _updateTargetRect();
  }
  
  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  void _updateTargetRect() {
    // Use multiple frames to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _safeUpdateTargetRect();
      });
    });
  }
  
  void _safeUpdateTargetRect() {
    if (!mounted) return;
    if (_currentStep >= widget.steps.length) return;
    
    final step = widget.steps[_currentStep];
    final targetContext = step.targetKey.currentContext;
    
    // Check if the target context is still valid
    if (targetContext == null) return;
    
    final renderBox = targetContext.findRenderObject() as RenderBox?;
    
    // Comprehensive check before accessing render box
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) return;
    
    // Additional check: verify the render object has a valid parent chain
    // by checking if it's part of the render tree
    if (renderBox.owner == null) return;
    
    try {
      // Use global position only - avoid ancestor parameter which can cause issues
      // during widget tree changes
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      if (mounted) {
        setState(() {
          _targetRect = Rect.fromLTWH(
            position.dx - step.highlightPadding,
            position.dy - step.highlightPadding,
            size.width + step.highlightPadding * 2,
            size.height + step.highlightPadding * 2,
          );
        });
      }
    } catch (e) {
      // Silently handle any errors during position calculation
      // This can happen if the widget tree changes during calculation
    }
  }
  
  void _nextStep() async {
    await VibrationService().lightVibration();
    
    if (_currentStep < widget.steps.length - 1) {
      await _fadeController.reverse();
      setState(() {
        _currentStep++;
        _targetRect = null;
      });
      _updateTargetRect();
      _fadeController.forward();
    } else {
      _completeTutorial();
    }
  }
  
  void _previousStep() async {
    await VibrationService().lightVibration();
    
    if (_currentStep > 0) {
      await _fadeController.reverse();
      setState(() {
        _currentStep--;
        _targetRect = null;
      });
      _updateTargetRect();
      _fadeController.forward();
    }
  }
  
  void _completeTutorial() async {
    await VibrationService().navigationVibration();
    await _fadeController.reverse();
    widget.onComplete();
  }
  
  void _skipTutorial() async {
    await VibrationService().lightVibration();
    widget.onComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentStepData = widget.steps[_currentStep];
    final isLastStep = _currentStep == widget.steps.length - 1;
    final screenSize = MediaQuery.of(context).size;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dark overlay with spotlight cutout
              if (_targetRect != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: screenSize,
                        painter: _SpotlightPainter(
                          targetRect: _targetRect!,
                          overlayColor: widget.overlayColor,
                          pulseOffset: widget.animateSpotlight ? _pulseAnimation.value : 0,
                          shape: currentStepData.shape,
                          accentColor: widget.accentColor,
                        ),
                      );
                    },
                  ),
                )
              else
                Positioned.fill(
                  child: Container(color: widget.overlayColor),
                ),
            
            // Tooltip
              if (_targetRect != null)
                _buildTooltip(currentStepData, isLastStep),
              
              // Skip button
              if (widget.showSkipButton)
                Positioned(
                  top: MediaQuery.of(context).padding.top + (kIsWeb ? 16 : 16.h),
                  right: kIsWeb ? 20 : 20.w,
                  child: GestureDetector(
                    onTap: _skipTutorial,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 16 : 16.w,
                        vertical: kIsWeb ? 8 : 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Step indicator
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + (kIsWeb ? 30 : 30.h) + widget.bottomPadding,
                left: 0,
                right: 0,
                child: _buildStepIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTooltip(TutorialStep step, bool isLastStep) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = kIsWeb ? 320.0 : 300.w;
    
    // Calculate tooltip position based on target and preference
    double top = 0, left = 0;
    bool showAbove = false;
    
    bool showCenter = false;
    
    switch (step.tooltipPosition) {
      case TooltipPosition.bottom:
        top = _targetRect!.bottom + (kIsWeb ? 20 : 20.h);
        left = (_targetRect!.left + _targetRect!.right) / 2 - tooltipWidth / 2;
        showAbove = false;
        break;
      case TooltipPosition.top:
        showAbove = true;
        left = (_targetRect!.left + _targetRect!.right) / 2 - tooltipWidth / 2;
        break;
      case TooltipPosition.left:
        top = (_targetRect!.top + _targetRect!.bottom) / 2 - 80;
        left = _targetRect!.left - tooltipWidth - (kIsWeb ? 20 : 20.w);
        break;
      case TooltipPosition.right:
        top = (_targetRect!.top + _targetRect!.bottom) / 2 - 80;
        left = _targetRect!.right + (kIsWeb ? 20 : 20.w);
        break;
      case TooltipPosition.center:
        showCenter = true;
        left = (screenSize.width - tooltipWidth) / 2;
        top = (screenSize.height / 2) - 100; // Centered vertically with slight offset
        break;
    }
    
    // Clamp left position to screen bounds (skip for center)
    if (!showCenter) {
      left = left.clamp(kIsWeb ? 20.0 : 20.w, screenSize.width - tooltipWidth - (kIsWeb ? 20 : 20.w));
    }
    
    // If showing above, calculate top position
    if (showAbove) {
      // Will be positioned from bottom
    }
    
    return Positioned(
      top: showAbove ? null : top,
      bottom: showAbove ? (screenSize.height - _targetRect!.top + (kIsWeb ? 20 : 20.h)) : null,
      left: left,
      child: Container(
        width: tooltipWidth,
        padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and title row
            Row(
              children: [
                if (step.icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(kIsWeb ? 8 : 8.w),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kIsWeb ? 10 : 10.r),
                    ),
                    child: Icon(
                      step.icon,
                      size: kIsWeb ? 24 : 24.sp,
                      color: widget.accentColor,
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 12 : 12.w),
                ],
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: kIsWeb ? 18 : 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: kIsWeb ? 12 : 12.h),
            
            // Description
            Text(
              step.description,
              style: TextStyle(
                fontSize: kIsWeb ? 14 : 14.sp,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            
            SizedBox(height: kIsWeb ? 20 : 20.h),
            
            // Navigation buttons
            Row(
              children: [
                // Back button
                if (_currentStep > 0)
                  GestureDetector(
                    onTap: _previousStep,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 16 : 16.w,
                        vertical: kIsWeb ? 10 : 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: kIsWeb ? 18 : 18.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: kIsWeb ? 4 : 4.w),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: kIsWeb ? 14 : 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const Spacer(),
                
                // Next/Done button
                GestureDetector(
                  onTap: _nextStep,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 20 : 20.w,
                      vertical: kIsWeb ? 10 : 10.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastStep ? 'Got it!' : 'Next',
                          style: TextStyle(
                            fontSize: kIsWeb ? 14 : 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: kIsWeb ? 4 : 4.w),
                        Icon(
                          isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          size: kIsWeb ? 18 : 18.sp,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.steps.length, (index) {
        final isActive = index == _currentStep;
        final isPast = index < _currentStep;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 4 : 4.w),
          height: kIsWeb ? 8 : 8.h,
          width: isActive ? (kIsWeb ? 28 : 24.w) : (kIsWeb ? 8 : 8.w),
          decoration: BoxDecoration(
            color: isActive
                ? widget.accentColor
                : isPast
                    ? widget.accentColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(kIsWeb ? 4 : 4.r),
          ),
        );
      }),
    );
  }
}

/// Custom painter for spotlight effect
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;
  final double pulseOffset;
  final HighlightShape shape;
  final Color accentColor;
  
  _SpotlightPainter({
    required this.targetRect,
    required this.overlayColor,
    required this.pulseOffset,
    required this.shape,
    required this.accentColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    
    // Create path for the whole screen
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create cutout path based on shape
    Path cutoutPath;
    final expandedRect = Rect.fromLTRB(
      targetRect.left - pulseOffset,
      targetRect.top - pulseOffset,
      targetRect.right + pulseOffset,
      targetRect.bottom + pulseOffset,
    );
    
    switch (shape) {
      case HighlightShape.circle:
        final center = targetRect.center;
        final radius = math.max(targetRect.width, targetRect.height) / 2 + pulseOffset;
        cutoutPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case HighlightShape.roundedRect:
        cutoutPath = Path()
          ..addRRect(RRect.fromRectAndRadius(expandedRect, const Radius.circular(16)));
        break;
      case HighlightShape.rect:
        cutoutPath = Path()..addRect(expandedRect);
        break;
    }
    
    // Combine paths to create cutout effect
    final combinedPath = Path.combine(PathOperation.difference, fullPath, cutoutPath);
    canvas.drawPath(combinedPath, paint);
    
    // Draw accent border around the cutout
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    switch (shape) {
      case HighlightShape.circle:
        final center = targetRect.center;
        final radius = math.max(targetRect.width, targetRect.height) / 2 + pulseOffset;
        canvas.drawCircle(center, radius, borderPaint);
        break;
      case HighlightShape.roundedRect:
        canvas.drawRRect(
          RRect.fromRectAndRadius(expandedRect, const Radius.circular(16)),
          borderPaint,
        );
        break;
      case HighlightShape.rect:
        canvas.drawRect(expandedRect, borderPaint);
        break;
    }
  }
  
  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      pulseOffset != oldDelegate.pulseOffset;
}

