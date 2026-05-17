import 'package:flutter/material.dart';
import '../services/vibration_service.dart';
import 'vibration_button.dart';

class VibrationGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final VibrationType vibrationType;
  final bool enableVibration;

  const VibrationGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.vibrationType = VibrationType.light,
    this.enableVibration = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enableVibration && onTap != null
          ? () async {
              await _triggerVibration();
              onTap!();
            }
          : onTap,
      onDoubleTap: enableVibration && onDoubleTap != null
          ? () async {
              await _triggerVibration();
              onDoubleTap!();
            }
          : onDoubleTap,
      onLongPress: enableVibration && onLongPress != null
          ? () async {
              await _triggerVibration();
              onLongPress!();
            }
          : onLongPress,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      child: child,
    );
  }

  Future<void> _triggerVibration() async {
    final vibrationService = VibrationService();
    
    switch (vibrationType) {
      case VibrationType.light:
        await vibrationService.lightVibration();
        break;
      case VibrationType.success:
        await vibrationService.successVibration();
        break;
      case VibrationType.error:
        await vibrationService.errorVibration();
        break;
      case VibrationType.navigation:
        await vibrationService.navigationVibration();
        break;
      case VibrationType.selection:
        await vibrationService.selectionVibration();
        break;
      case VibrationType.missionComplete:
        await vibrationService.missionCompleteVibration();
        break;
      case VibrationType.quizComplete:
        await vibrationService.quizCompleteVibration();
        break;
      case VibrationType.achievement:
        await vibrationService.achievementVibration();
        break;
    }
  }
}

/// Vibration-aware InkWell widget
class VibrationInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final ValueChanged<bool>? onHover;
  final Color? overlayColor;
  final Color? splashColor;
  final Color? highlightColor;
  final BorderRadius? borderRadius;
  final VibrationType vibrationType;
  final bool enableVibration;

  const VibrationInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.onHover,
    this.overlayColor,
    this.splashColor,
    this.highlightColor,
    this.borderRadius,
    this.vibrationType = VibrationType.light,
    this.enableVibration = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enableVibration && onTap != null
          ? () async {
              await _triggerVibration();
              onTap!();
            }
          : onTap,
      onDoubleTap: enableVibration && onDoubleTap != null
          ? () async {
              await _triggerVibration();
              onDoubleTap!();
            }
          : onDoubleTap,
      onLongPress: enableVibration && onLongPress != null
          ? () async {
              await _triggerVibration();
              onLongPress!();
            }
          : onLongPress,
      onHighlightChanged: onHighlightChanged,
      onHover: onHover,
      overlayColor: overlayColor != null ? WidgetStateProperty.all(overlayColor) : null,
      splashColor: splashColor,
      highlightColor: highlightColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  Future<void> _triggerVibration() async {
    final vibrationService = VibrationService();
    
    switch (vibrationType) {
      case VibrationType.light:
        await vibrationService.lightVibration();
        break;
      case VibrationType.success:
        await vibrationService.successVibration();
        break;
      case VibrationType.error:
        await vibrationService.errorVibration();
        break;
      case VibrationType.navigation:
        await vibrationService.navigationVibration();
        break;
      case VibrationType.selection:
        await vibrationService.selectionVibration();
        break;
      case VibrationType.missionComplete:
        await vibrationService.missionCompleteVibration();
        break;
      case VibrationType.quizComplete:
        await vibrationService.quizCompleteVibration();
        break;
      case VibrationType.achievement:
        await vibrationService.achievementVibration();
        break;
    }
  }
}
