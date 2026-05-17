import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Global service to manage app lifecycle and timer states
class AppLifecycleService extends ChangeNotifier {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  AppLifecycleState _currentState = AppLifecycleState.resumed;
  DateTime? _backgroundTime;
  DateTime? _foregroundTime;
  
  // Timer management
  final List<Timer> _activeTimers = [];
  final Map<String, TimerState> _timerStates = {};

  AppLifecycleState get currentState => _currentState;
  bool get isInBackground => _currentState == AppLifecycleState.paused;
  bool get isInForeground => _currentState == AppLifecycleState.resumed;

  /// Register a timer to be managed by the lifecycle service
  void registerTimer(String timerId, Timer timer) {
    _activeTimers.add(timer);
    _timerStates[timerId] = TimerState(
      timer: timer,
      isPaused: false,
      pausedAt: null,
    );
    
    if (kDebugMode) {
      print('🕐 Registered timer: $timerId');
    }
  }

  /// Unregister a timer from lifecycle management
  void unregisterTimer(String timerId) {
    final timerState = _timerStates.remove(timerId);
    if (timerState != null) {
      _activeTimers.remove(timerState.timer);
      timerState.timer.cancel();
      
      if (kDebugMode) {
        print('🕐 Unregistered timer: $timerId');
      }
    }
  }

  /// Pause all registered timers
  void pauseAllTimers() {
    for (final entry in _timerStates.entries) {
      final timerId = entry.key;
      final timerState = entry.value;
      
      if (!timerState.isPaused) {
        timerState.timer.cancel();
        timerState.isPaused = true;
        timerState.pausedAt = DateTime.now();
        
        if (kDebugMode) {
          print('⏸️ Paused timer: $timerId');
        }
      }
    }
  }

  /// Resume all registered timers
  void resumeAllTimers() {
    for (final entry in _timerStates.entries) {
      final timerId = entry.key;
      final timerState = entry.value;
      
      if (timerState.isPaused) {
        // Create a new timer to replace the cancelled one
        final newTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          // This will be overridden by the specific timer implementation
        });
        
        timerState.timer = newTimer;
        timerState.isPaused = false;
        timerState.pausedAt = null;
        
        if (kDebugMode) {
          print('▶️ Resumed timer: $timerId');
        }
      }
    }
  }

  /// Handle app lifecycle state changes
  void handleLifecycleChange(AppLifecycleState state) {
    if (_currentState == state) return;
    
    final previousState = _currentState;
    _currentState = state;
    
    if (kDebugMode) {
      print('🔄 App lifecycle changed: $previousState -> $state');
    }
    
    switch (state) {
      case AppLifecycleState.paused:
        _backgroundTime = DateTime.now();
        pauseAllTimers();
        break;
      case AppLifecycleState.resumed:
        _foregroundTime = DateTime.now();
        resumeAllTimers();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        pauseAllTimers();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between states
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        pauseAllTimers();
        break;
    }
    
    notifyListeners();
  }

  /// Get the duration the app was in background
  Duration? getBackgroundDuration() {
    if (_backgroundTime != null && _foregroundTime != null) {
      return _foregroundTime!.difference(_backgroundTime!);
    }
    return null;
  }

  /// Check if app was in background for more than specified duration
  bool wasInBackgroundFor(Duration duration) {
    final backgroundDuration = getBackgroundDuration();
    return backgroundDuration != null && backgroundDuration > duration;
  }

  /// Clear background/foreground timestamps
  void clearTimestamps() {
    _backgroundTime = null;
    _foregroundTime = null;
  }

  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _timerStates.clear();
    super.dispose();
  }
}

/// Represents the state of a timer managed by AppLifecycleService
class TimerState {
  Timer timer;
  bool isPaused;
  DateTime? pausedAt;

  TimerState({
    required this.timer,
    required this.isPaused,
    this.pausedAt,
  });
}
