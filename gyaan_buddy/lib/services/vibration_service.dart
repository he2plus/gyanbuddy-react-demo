import 'dart:io';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal() {
    _loadVibrationSetting();
    if (kDebugMode) {
      print('VibrationService initialized - Enabled: $_isEnabled');
    }
  }

  bool _isEnabled = true;
  static const String _vibrationKey = 'vibration_enabled';

  /// Check if running on iOS
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// Check if vibration is available on the device
  Future<bool> get isAvailable async {
    // Web doesn't support vibration
    if (kIsWeb) {
      return false;
    }
    // iOS always has haptic feedback on supported devices
    if (_isIOS) {
      return true;
    }
    return await Vibration.hasVibrator() ?? false;
  }

  /// Enable or disable vibration
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _saveVibrationSetting(enabled);
  }

  /// Load vibration setting from SharedPreferences
  Future<void> _loadVibrationSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_vibrationKey) ?? true; // Default to true
    } catch (e) {
      // If there's an error loading preferences, keep default value
      _isEnabled = true;
    }
  }

  /// Save vibration setting to SharedPreferences
  Future<void> _saveVibrationSetting(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationKey, enabled);
    } catch (e) {
      // If there's an error saving preferences, continue silently
      print('Error saving vibration setting: $e');
    }
  }

  /// Get current vibration state
  bool get isEnabled => _isEnabled;

  /// Light vibration for button taps and general interactions
  Future<void> lightVibration() async {
    if (!_isEnabled) {
      if (kDebugMode) {
        print('Vibration disabled, skipping light vibration');
      }
      return;
    }
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (kDebugMode) {
        print('Playing light vibration');
      }
      if (_isIOS) {
        // Use selection click for the lightest feedback
        await HapticFeedback.selectionClick();
      } else {
        // Reduced duration and low amplitude (1-255, lower = weaker)
        Vibration.vibrate(duration: 10, amplitude: 40);
      }
    } else {
      if (kDebugMode) {
        print('Vibration not available on this device');
      }
    }
  }

  /// Medium vibration for successful actions
  Future<void> successVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // Use selection click for subtle feedback on iOS
        await HapticFeedback.selectionClick();
      } else {
        // Reduced duration and amplitude
        Vibration.vibrate(duration: 20, amplitude: 60);
      }
    }
  }

  /// Strong vibration for important events
  Future<void> strongVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // Use light impact for reduced intensity on iOS
        await HapticFeedback.lightImpact();
      } else {
        // Reduced duration and amplitude
        Vibration.vibrate(duration: 40, amplitude: 80);
      }
    }
  }

  /// Pattern vibration for mission completion
  Future<void> missionCompleteVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // iOS pattern: subtle double tap
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.selectionClick();
      } else {
        // Reduced pattern with lower amplitude
        Vibration.vibrate(pattern: [0, 15, 40, 20, 40, 25], amplitude: 50);
      }
    }
  }

  /// Pattern vibration for quiz completion
  Future<void> quizCompleteVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // iOS pattern: single subtle tap
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.selectionClick();
      } else {
        // Reduced pattern with lower amplitude
        Vibration.vibrate(pattern: [0, 10, 30, 10, 30, 15], amplitude: 45);
      }
    }
  }

  /// Pattern vibration for achievements
  Future<void> achievementVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // iOS celebratory pattern - subtle double tap
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.selectionClick();
      } else {
        // Reduced pattern with lower amplitude
        Vibration.vibrate(pattern: [0, 12, 40, 12, 40, 15, 50], amplitude: 50);
      }
    }
  }

  /// Error vibration pattern
  Future<void> errorVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // iOS error pattern - single selection click for subtle feedback
        await HapticFeedback.selectionClick();
      } else {
        // Reduced error pattern with lower amplitude
        Vibration.vibrate(pattern: [0, 25, 50, 25], amplitude: 60);
      }
    }
  }

  /// Navigation vibration
  Future<void> navigationVibration() async {
    if (kDebugMode) {
      print('🔔 navigationVibration called - isEnabled: $_isEnabled, kIsWeb: $kIsWeb');
    }
    
    if (!_isEnabled) {
      if (kDebugMode) {
        print('🔔 Vibration disabled by user setting');
      }
      return;
    }
    
    // Web doesn't support vibration
    if (kIsWeb) {
      if (kDebugMode) {
        print('🔔 Web platform - vibration not supported');
      }
      return;
    }
    
    final available = await isAvailable;
    if (kDebugMode) {
      print('🔔 Device has vibrator: $available');
    }
    
    if (available) {
      if (_isIOS) {
        await HapticFeedback.selectionClick();
      } else {
        // Reduced duration and amplitude
        Vibration.vibrate(duration: 8, amplitude: 30);
      }
      if (kDebugMode) {
        print('🔔 Vibration triggered!');
      }
    }
  }

  /// Selection vibration
  Future<void> selectionVibration() async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        await HapticFeedback.selectionClick();
      } else {
        // Reduced duration and amplitude
        Vibration.vibrate(duration: 8, amplitude: 35);
      }
    }
  }

  /// Custom vibration with pattern
  Future<void> customVibration(List<int> pattern) async {
    if (!_isEnabled) return;
    
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      if (_isIOS) {
        // On iOS, approximate the pattern with haptic impacts
        // Pattern alternates between wait time and vibration
        for (int i = 0; i < pattern.length; i++) {
          if (i % 2 == 0) {
            // Wait
            await Future.delayed(Duration(milliseconds: pattern[i]));
          } else {
            // Vibrate - use light impact for reduced intensity
            await HapticFeedback.selectionClick();
          }
        }
      } else {
        // Use reduced amplitude for custom patterns
        Vibration.vibrate(pattern: pattern, amplitude: 50);
      }
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancelVibration() async {
    // Web doesn't support vibration
    if (kIsWeb) {
      return;
    }
    
    if (await isAvailable) {
      Vibration.cancel();
    }
  }
}

/// Mixin for easy vibration integration in widgets
mixin VibrationMixin<T extends StatefulWidget> on State<T> {
  final VibrationService _vibrationService = VibrationService();

  /// Add vibration to any tap gesture
  Future<void> vibrateOnTap() async {
    await _vibrationService.lightVibration();
  }

  /// Add vibration to successful actions
  Future<void> vibrateOnSuccess() async {
    await _vibrationService.successVibration();
  }

  /// Add vibration to errors
  Future<void> vibrateOnError() async {
    await _vibrationService.errorVibration();
  }

  /// Add vibration to navigation
  Future<void> vibrateOnNavigation() async {
    await _vibrationService.navigationVibration();
  }

  /// Add vibration to selection
  Future<void> vibrateOnSelection() async {
    await _vibrationService.selectionVibration();
  }

  /// Add vibration to mission completion
  Future<void> vibrateOnMissionComplete() async {
    await _vibrationService.missionCompleteVibration();
  }

  /// Add vibration to quiz completion
  Future<void> vibrateOnQuizComplete() async {
    await _vibrationService.quizCompleteVibration();
  }

  /// Add vibration to achievements
  Future<void> vibrateOnAchievement() async {
    await _vibrationService.achievementVibration();
  }
}

/// Extension for StatelessWidget to add vibration capabilities
extension VibrationExtension on StatelessWidget {
  VibrationService get vibrationService => VibrationService();
}

/// Extension for StatefulWidget to add vibration capabilities
extension VibrationStateExtension on State {
  VibrationService get vibrationService => VibrationService();
}
