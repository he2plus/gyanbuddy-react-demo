import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state
/// Tracks whether the user has completed the onboarding flow
class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _onboardingVersionKey = 'onboarding_version';
  
  // Screen-specific tutorial keys
  static const String _subjectScreenTutorialKey = 'subject_screen_tutorial_complete';
  static const String _quizScreenTutorialKey = 'quiz_screen_tutorial_complete';
  static const String _homeScreenTutorialKey = 'home_screen_tutorial_complete';
  static const String _missionScreenTutorialKey = 'mission_screen_tutorial_complete';
  
  // Current onboarding version - increment this to show onboarding again
  // after major app updates with new features
  static const int currentOnboardingVersion = 1;

  /// Check if onboarding has been completed
  static Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
      final savedVersion = prefs.getInt(_onboardingVersionKey) ?? 0;
      
      // If version changed, show onboarding again
      if (savedVersion < currentOnboardingVersion) {
        return false;
      }
      
      return isComplete;
    } catch (e) {
      // If there's an error reading preferences, assume not completed
      return false;
    }
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      await prefs.setInt(_onboardingVersionKey, currentOnboardingVersion);
    } catch (e) {
      // Silently fail - user can still use the app
    }
  }

  /// Reset onboarding (for testing or settings)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      await prefs.remove(_onboardingVersionKey);
    } catch (e) {
      // Silently fail
    }
  }
  
  // ============ Screen-specific tutorials ============
  
  /// Check if a specific screen tutorial has been completed
  static Future<bool> isScreenTutorialComplete(ScreenTutorial tutorial) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTutorialKey(tutorial);
      return prefs.getBool(key) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Mark a specific screen tutorial as completed
  static Future<void> completeScreenTutorial(ScreenTutorial tutorial) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTutorialKey(tutorial);
      await prefs.setBool(key, true);
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Reset a specific screen tutorial (for testing)
  static Future<void> resetScreenTutorial(ScreenTutorial tutorial) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTutorialKey(tutorial);
      await prefs.remove(key);
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Reset all screen tutorials
  static Future<void> resetAllScreenTutorials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subjectScreenTutorialKey);
      await prefs.remove(_quizScreenTutorialKey);
      await prefs.remove(_homeScreenTutorialKey);
      await prefs.remove(_missionScreenTutorialKey);
    } catch (e) {
      // Silently fail
    }
  }
  
  static String _getTutorialKey(ScreenTutorial tutorial) {
    switch (tutorial) {
      case ScreenTutorial.subjectScreen:
        return _subjectScreenTutorialKey;
      case ScreenTutorial.quizScreen:
        return _quizScreenTutorialKey;
      case ScreenTutorial.homeScreen:
        return _homeScreenTutorialKey;
      case ScreenTutorial.missionScreen:
        return _missionScreenTutorialKey;
    }
  }
}

/// Enum for different screen tutorials
enum ScreenTutorial {
  subjectScreen,
  quizScreen,
  homeScreen,
  missionScreen,
}

