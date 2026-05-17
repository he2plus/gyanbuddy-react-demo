import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'vibration_service.dart';

// Sound effect types
enum SoundType {
  correctAnswer,
  incorrectAnswer,
  buttonClick,
  success,
  levelUp,
  tick,
  pop,
  notification,
  answerSelect,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isSoundEnabled = false;
  double _volume = 0.0; // Default volume (0.0 to 1.0) - Sound disabled for now
  bool _isInitialized = false;
  
  // Throttle mechanism for rapid sounds
  DateTime? _lastPlayClickTime;
  static const Duration _playClickThrottle = Duration(milliseconds: 100);
  
  // Track active players for cleanup
  final Set<AudioPlayer> _activePlayers = {};

  /// Create a new player for each sound (more reliable)
  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _activePlayers.add(player);
    
    // Auto-dispose when done playing
    player.onPlayerComplete.listen((_) {
      _disposePlayer(player);
    });
    
    return player;
  }
  
  /// Dispose a player safely
  void _disposePlayer(AudioPlayer player) {
    try {
      _activePlayers.remove(player);
      player.dispose();
    } catch (e) {
      // Ignore dispose errors
    }
  }

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadSoundSettings();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('SoundService initialized successfully - Sound enabled: $_isSoundEnabled, Volume: $_volume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SoundService: $e');
      }
    }
  }

  /// Check if audio is available and working
  Future<bool> isAudioAvailable() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Audio not available: $e');
      }
      return false;
    }
  }

  /// Load sound settings from SharedPreferences
  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? false;
      _volume = prefs.getDouble('sound_volume') ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sound settings: $e');
      }
    }
  }

  /// Save sound settings to SharedPreferences
  Future<void> _saveSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', _isSoundEnabled);
      await prefs.setDouble('sound_volume', _volume);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving sound settings: $e');
      }
    }
  }

  /// Play a custom sound from assets - FIRE AND FORGET (non-blocking)
  void _playCustomSoundFireAndForget(String assetPath, {bool throttle = false}) {
    if (!_isSoundEnabled) return;
    
    // Apply throttling for rapid sounds
    if (throttle) {
      final now = DateTime.now();
      if (_lastPlayClickTime != null && 
          now.difference(_lastPlayClickTime!) < _playClickThrottle) {
        return; // Skip this sound, too soon after last one
      }
      _lastPlayClickTime = now;
    }
    
    // Fire and forget - schedule async work but don't wait
    _playSoundAsync(assetPath);
  }
  
  /// Internal async sound player - runs in background
  void _playSoundAsync(String assetPath) {
    if (kDebugMode) {
      print('🔊 Attempting to play: $assetPath');
    }
    
    try {
      final player = _createPlayer();
      
      // Set volume and play
      player.setVolume(_volume).then((_) {
        return player.play(AssetSource(assetPath));
      }).then((_) {
        if (kDebugMode) {
          print('🔊 Successfully started: $assetPath');
        }
      }).catchError((e) {
        if (kDebugMode) {
          print('Error playing sound $assetPath: $e');
        }
        _disposePlayer(player); // Clean up on error
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error in _playSoundAsync $assetPath: $e');
      }
    }
  }

  /// Play a sound effect using enhanced audio and haptic feedback
  Future<void> playSound(SoundType soundType) async {
    try {
      // Play system sound directly for maximum compatibility
      if (_isSoundEnabled) {
        _playSystemSoundFireAndForget(soundType);
      }
      
      // Add vibration feedback that respects user settings (fire and forget)
      _playVibrationForSoundType(soundType);
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound $soundType: $e');
      }
    }
  }
  
  /// Play vibration for sound type - fire and forget
  void _playVibrationForSoundType(SoundType soundType) {
    switch (soundType) {
      case SoundType.correctAnswer:
        VibrationService().successVibration();
        break;
      case SoundType.incorrectAnswer:
        VibrationService().errorVibration();
        break;
      case SoundType.buttonClick:
        VibrationService().lightVibration();
        break;
      case SoundType.success:
        VibrationService().successVibration();
        break;
      case SoundType.levelUp:
        VibrationService().achievementVibration();
        break;
      case SoundType.tick:
        VibrationService().lightVibration();
        break;
      case SoundType.pop:
        VibrationService().lightVibration();
        break;
      case SoundType.notification:
        VibrationService().lightVibration();
        break;
      case SoundType.answerSelect:
        VibrationService().selectionVibration();
    }
  }

  /// Play system sounds - fire and forget
  void _playSystemSoundFireAndForget(SoundType soundType) {
    try {
      if (kDebugMode) {
        print('🔊 Playing system sound: $soundType');
      }
      
      switch (soundType) {
        case SoundType.correctAnswer:
          SystemSound.play(SystemSoundType.click);
          Future.delayed(const Duration(milliseconds: 50), () {
            SystemSound.play(SystemSoundType.click);
          });
          break;
        case SoundType.incorrectAnswer:
          SystemSound.play(SystemSoundType.alert);
          break;
        case SoundType.buttonClick:
          SystemSound.play(SystemSoundType.click);
          break;
        case SoundType.success:
          SystemSound.play(SystemSoundType.click);
          Future.delayed(const Duration(milliseconds: 100), () {
            SystemSound.play(SystemSoundType.click);
          });
          Future.delayed(const Duration(milliseconds: 200), () {
            SystemSound.play(SystemSoundType.click);
          });
          break;
        case SoundType.levelUp:
          SystemSound.play(SystemSoundType.alert);
          break;
        case SoundType.tick:
          SystemSound.play(SystemSoundType.click);
          break;
        case SoundType.pop:
          SystemSound.play(SystemSoundType.click);
          break;
        case SoundType.notification:
          SystemSound.play(SystemSoundType.alert);
          break;
        case SoundType.answerSelect:
          SystemSound.play(SystemSoundType.click);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing system sound: $e');
      }
    }
  }

  /// Play correct answer sound from custom asset
  Future<void> playCorrectAnswer() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/Correct.mp3');
    VibrationService().successVibration();
  }

  /// Play incorrect answer sound from custom asset
  Future<void> playIncorrectAnswer() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/Wrong_answer.wav');
    VibrationService().errorVibration();
  }

  /// Play button click sound
  Future<void> playButtonClick() async {
    await playSound(SoundType.buttonClick);
  }

  /// Play success sound
  Future<void> playSuccess() async {
    await playSound(SoundType.success);
  }

  /// Play level up sound
  Future<void> playLevelUp() async {
    await playSound(SoundType.levelUp);
  }

  /// Play notification sound
  Future<void> playNotification() async {
    await playSound(SoundType.notification);
  }

  /// Play tick sound
  Future<void> playTick() async {
    await playSound(SoundType.tick);
  }

  /// Play pop sound
  Future<void> playPop() async {
    await playSound(SoundType.pop);
  }

  /// Play answer select sound from custom asset
  Future<void> playAnswerSelect() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/answer-select.ogg');
    VibrationService().selectionVibration();
  }

  /// Play app startup sound from custom asset
  Future<void> playAppStartup() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/App_startup_sound.mp3');
  }

  /// Play profile loading sound from custom asset
  Future<void> playProfileLoading() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/loading_profile.mp3');
  }

  /// Play click sound for splash effects (throttled to prevent rapid fire)
  Future<void> playPlayClick() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/play-click.ogg', throttle: true);
  }

  /// Play module completion sound from custom asset
  Future<void> playModuleComplete() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/Complete_questions_module.ogg');
  }

  /// Play leaderboard loading sound from custom asset
  Future<void> playLeaderboardLoading() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/loading_leaderboard.mp3');
  }

  /// Play question whoosh sound for question transitions
  Future<void> playQuestionWhoosh() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/question-whoosh.ogg');
  }

  /// Play tab switch sound for navigation transitions
  Future<void> playTabSwitch() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/screen_tab_slide_effects.ogg');
  }

  /// Play hint usage sound when hint icon is clicked
  Future<void> playHintUsage() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/hint-usage.ogg');
  }

  /// Play start questions sound before loading quiz
  Future<void> playStartQuestions() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/Start_questions-before_loading_first.ogg');
  }

  /// Play loading contents sound when opening new page
  Future<void> playLoadingContents() async {
    if (!_isSoundEnabled) return;
    _playCustomSoundFireAndForget('sounds/Loading_contents_new_page.mp3');
  }

  /// Toggle sound on/off
  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    await _saveSoundSettings();
  }

  /// Get current sound enabled status
  bool get isSoundEnabled => _isSoundEnabled;

  /// Get current volume level
  double get volume => _volume;

  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _saveSoundSettings();
  }
  
  /// Force maximum volume for all sounds
  Future<void> setMaxVolume() async {
    _volume = 1.0;
    await _saveSoundSettings();
    if (kDebugMode) {
      print('🔊 Volume set to maximum: 1.0');
    }
  }

  /// Increase volume by 0.1
  Future<void> increaseVolume() async {
    await setVolume(_volume + 0.1);
  }

  /// Decrease volume by 0.1
  Future<void> decreaseVolume() async {
    await setVolume(_volume - 0.1);
  }

  /// Stop all sounds
  void stop() {
    for (final player in _activePlayers.toList()) {
      try {
        player.stop();
      } catch (e) {
        if (kDebugMode) {
          print('Error stopping audio player: $e');
        }
      }
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    for (final player in _activePlayers.toList()) {
      try {
        await player.dispose();
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing audio player: $e');
        }
      }
    }
    _activePlayers.clear();
  }
}
