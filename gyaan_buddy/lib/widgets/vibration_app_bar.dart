import 'package:flutter/material.dart';
import '../services/vibration_service.dart';
import 'vibration_button.dart';

class VibrationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final double? titleSpacing;
  final double? leadingWidth;
  final PreferredSizeWidget? bottom;
  final bool enableVibration;

  const VibrationAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.titleSpacing,
    this.leadingWidth,
    this.bottom,
    this.enableVibration = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions?.map((action) {
        if (action is IconButton) {
          return VibrationIconButton(
            icon: action.icon,
            onPressed: action.onPressed,
            vibrationType: VibrationType.navigation,
          );
        } else if (action is TextButton) {
          return VibrationTextButton(

            child: action.child ?? const SizedBox(),
            onPressed: action.onPressed,
            vibrationType: VibrationType.navigation,
          );
        }
        return action;
      }).toList(),
      leading: leading != null
          ? _wrapLeadingWithVibration(leading!)
          : automaticallyImplyLeading
              ? _wrapLeadingWithVibration(
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              : null,
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth,
      bottom: bottom,
    );
  }

  Widget _wrapLeadingWithVibration(Widget leading) {
    if (leading is IconButton) {
      return VibrationIconButton(
        icon: leading.icon,
        onPressed: leading.onPressed,
        vibrationType: VibrationType.navigation,
      );
    }
    return leading;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Vibration-aware BackButton
class VibrationBackButton extends StatelessWidget {
  final Color? color;
  final String? tooltip;
  final bool enableVibration;

  const VibrationBackButton({
    super.key,
    this.color,
    this.tooltip,
    this.enableVibration = true,
  });

  @override
  Widget build(BuildContext context) {
    return VibrationIconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color,
      ),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      vibrationType: VibrationType.navigation,
    );
  }
}

/// Vibration-aware CloseButton
class VibrationCloseButton extends StatelessWidget {
  final Color? color;
  final String? tooltip;
  final bool enableVibration;

  const VibrationCloseButton({
    super.key,
    this.color,
    this.tooltip,
    this.enableVibration = true,
  });

  @override
  Widget build(BuildContext context) {
    return VibrationIconButton(
      icon: Icon(
        Icons.close,
        color: color,
      ),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: tooltip ?? MaterialLocalizations.of(context).closeButtonTooltip,
      vibrationType: VibrationType.navigation,
    );
  }
}
