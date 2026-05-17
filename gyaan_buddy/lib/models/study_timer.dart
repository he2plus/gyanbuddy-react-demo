import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_lifecycle_service.dart';

class StudyTimer extends ChangeNotifier {
  bool _isActive = false;
  int _seconds = 0;
  Timer? _timer;
  DateTime? _lastActiveTime;
  bool _showTopTimer = false;
  bool _isPausedByBackground = false;
  DateTime? _backgroundPauseTime;

  bool get isActive => _isActive;
  int get seconds => _seconds;
  bool get showTopTimer => _showTopTimer;

  void start() {
    _isActive = true;
    _seconds = 0;
    _showTopTimer = true;
    _isPausedByBackground = false;
    _backgroundPauseTime = null;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPausedByBackground) {
        _seconds++;
        notifyListeners();
      }
    });
    
    // Register with lifecycle service
    AppLifecycleService().registerTimer('study_timer', _timer!);
  }

  void pause() {
    _timer?.cancel();
    _isActive = false;
    _showTopTimer = false;
    _isPausedByBackground = false;
    _backgroundPauseTime = null;
    
    // Unregister from lifecycle service
    AppLifecycleService().unregisterTimer('study_timer');
    
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _isActive = false;
    _seconds = 0;
    _showTopTimer = false;
    _isPausedByBackground = false;
    _backgroundPauseTime = null;
    
    // Unregister from lifecycle service
    AppLifecycleService().unregisterTimer('study_timer');
    
    notifyListeners();
  }

  void onAppPaused() {
    _lastActiveTime = DateTime.now();
    if (_isActive) {
      _isPausedByBackground = true;
      _backgroundPauseTime = DateTime.now();
    }
  }

  void onAppResumed() {
    if (_isActive && _lastActiveTime != null) {
      final timeDiff = DateTime.now().difference(_lastActiveTime!).inMinutes;
      if (timeDiff > 2) {
        // If app was in background for more than 2 minutes, pause the timer
        pause();
      } else if (_isPausedByBackground) {
        // Resume the timer if it was paused by background
        _isPausedByBackground = false;
        _backgroundPauseTime = null;
      }
    }
  }

  String formatTime() {
    int hours = _seconds ~/ 3600;
    int minutes = (_seconds % 3600) ~/ 60;
    int secs = _seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Unregister from lifecycle service
    AppLifecycleService().unregisterTimer('study_timer');
    super.dispose();
  }
}
