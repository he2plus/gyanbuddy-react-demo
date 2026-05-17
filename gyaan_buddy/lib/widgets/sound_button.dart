import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final SoundType soundType;
  final bool enableSound;

  const SoundButton({
    super.key,
    required this.child,
    this.onPressed,
    this.soundType = SoundType.buttonClick,
    this.enableSound = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // if (enableSound) {
        //   await SoundService().playSound(soundType);
        // }
        onPressed?.call();
      },
      child: child,
    );
  }
}

class SoundElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final SoundType soundType;
  final bool enableSound;
  final ButtonStyle? style;

  const SoundElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.soundType = SoundType.buttonClick,
    this.enableSound = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // if (enableSound) {
        //   await SoundService().playSound(soundType);
        // }
        onPressed?.call();
      },
      style: style,
      child: child,
    );
  }
}

class SoundTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final SoundType soundType;
  final bool enableSound;
  final ButtonStyle? style;

  const SoundTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.soundType = SoundType.buttonClick,
    this.enableSound = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        // if (enableSound) {
        //   await SoundService().playSound(soundType);
        // }
        onPressed?.call();
      },
      style: style,
      child: child,
    );
  }
}

class SoundIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final SoundType soundType;
  final bool enableSound;
  final ButtonStyle? style;
  final double? iconSize;
  final String? tooltip;

  const SoundIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.soundType = SoundType.buttonClick,
    this.enableSound = true,
    this.style,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        // if (enableSound) {
        //   await SoundService().playSound(soundType);
        // }
        onPressed?.call();
      },
      icon: icon,
      style: style,
      iconSize: iconSize,
      tooltip: tooltip,
    );
  }
}
