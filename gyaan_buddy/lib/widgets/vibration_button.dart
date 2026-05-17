import 'package:flutter/material.dart';
import '../services/vibration_service.dart';

enum VibrationType {
  light,
  success,
  error,
  navigation,
  selection,
  missionComplete,
  quizComplete,
  achievement,
}

class VibrationButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VibrationType vibrationType;
  final ButtonStyle? style;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool autofocus;

  const VibrationButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.vibrationType = VibrationType.light,
    this.style,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (onPressed != null) {
          await _triggerVibration();
          onPressed!();
        }
      },
      onLongPress: onLongPress != null ? () async {
        await _triggerVibration();
        onLongPress!();
      } : null,
      style: style,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
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

/// Vibration-aware TextButton
class VibrationTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VibrationType vibrationType;
  final ButtonStyle? style;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool autofocus;

  const VibrationTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.vibrationType = VibrationType.light,
    this.style,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        if (onPressed != null) {
          await _triggerVibration();
          onPressed!();
        }
      },
      onLongPress: onLongPress != null ? () async {
        await _triggerVibration();
        onLongPress!();
      } : null,
      style: style,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
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

/// Vibration-aware IconButton
class VibrationIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final VibrationType vibrationType;
  final double? iconSize;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final String? tooltip;
  final bool? isSelected;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;

  const VibrationIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.vibrationType = VibrationType.light,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.tooltip,
    this.isSelected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        if (onPressed != null) {
          await _triggerVibration();
          onPressed!();
        }
      },
      icon: icon,
      iconSize: iconSize,
      visualDensity: visualDensity,
      padding: padding,
      alignment: alignment,
      tooltip: tooltip,
      isSelected: isSelected,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
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
