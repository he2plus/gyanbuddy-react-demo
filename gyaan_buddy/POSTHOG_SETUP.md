# PostHog Analytics Setup for GyaanBuddy App

This document explains how PostHog analytics has been integrated into your Flutter app and how to use it effectively.

## What's Been Set Up

### 1. Dependencies
- Added `posthog_flutter: ^3.0.0` to `pubspec.yaml`

### 2. Platform Configuration
- **Android**: Added PostHog meta-data to `android/app/src/main/AndroidManifest.xml`
- **iOS**: Added PostHog keys to `ios/Runner/Info.plist`
- **Web**: Added PostHog script to `web/index.html`

### 3. Flutter Integration
- Created `PostHogService` class in `lib/services/posthog_service.dart`
- Initialized PostHog in `main.dart` (non-blocking initialization)
- Added `PosthogObserver` for automatic screen tracking
- Added analytics tracking to login screen as an example
- Implemented comprehensive error handling and initialization checks

## Configuration Details

### API Key
- **Key**: `phc_F5eguJHisPcIXGy7kouxSUQUu2tmNWRnvRjnX9YFEQ6`
- **Host**: `https://us.i.posthog.com`
- **Debug Mode**: Enabled
- **Lifecycle Events**: Tracked automatically

### Error Handling & Initialization
The PostHog service includes comprehensive error handling:
- **Non-blocking initialization**: App startup continues even if PostHog fails to initialize
- **Initialization checks**: All PostHog methods check if the service is ready before executing
- **Graceful degradation**: Analytics failures don't crash the app
- **Debug logging**: Detailed error messages in debug mode
- **Platform channel safety**: Waits for platform channels to be ready before initialization

## How to Use PostHog

### 1. Basic Event Tracking

```dart
import '../services/posthog_service.dart';

// Track a simple event
PostHogService.capture('button_clicked');

// Track an event with properties
PostHogService.capture('quiz_started', properties: {
  'subject': 'Mathematics',
  'difficulty': 'Hard',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### 2. User Identification

```dart
// Identify a user (call this after successful login)
PostHogService.identify(
  userId: 'user123',
  userProperties: {
    'name': 'John Doe',
    'grade': '10th',
    'school': 'ABC School',
  },
);

// Set additional user properties later
PostHogService.setPersonProperties({
  'last_quiz_score': 85,
  'preferred_subject': 'Science',
});
```

### 3. Screen Tracking

```dart
// Option 1: Use the AnalyticsWrapper widget
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return withAnalytics(
      Scaffold(
        // Your screen content
      ),
      'my_screen_name',
      properties: {'section': 'main_menu'},
    );
  }
}

// Option 2: Manual tracking
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    PostHogService.screen('my_screen_name');
  }
  
  // ... rest of the screen
}
```

### 4. Feature Flags

```dart
// Check if a feature is enabled
bool isNewUIEnabled = await PostHogService.isFeatureEnabled('new_ui');

// Get feature flag value
dynamic flagValue = await PostHogService.getFeatureFlag('quiz_timer');
```

### 5. Group Analytics

```dart
// Track group properties (e.g., school, class)
PostHogService.group(
  'school',
  'ABC_School_123',
  groupProperties: {
    'school_type': 'Public',
    'location': 'New York',
    'student_count': 1200,
  },
);
```

## Common Analytics Events to Track

### User Actions
- `login_attempted` - When user tries to log in
- `login_successful` - Successful login
- `logout` - User logs out
- `profile_updated` - User updates profile

### Quiz Related
- `quiz_started` - User starts a quiz
- `quiz_completed` - User finishes a quiz
- `quiz_abandoned` - User leaves quiz early
- `question_answered` - User answers a question
- `quiz_result_viewed` - User views quiz results

### Content Engagement
- `module_opened` - User opens a learning module
- `video_watched` - User watches educational video
- `content_downloaded` - User downloads content
- `bookmark_added` - User bookmarks content

### Navigation
- `screen_viewed` - User visits a screen
- `menu_opened` - User opens navigation menu
- `search_performed` - User searches for content

## Best Practices

### 1. Event Naming
- Use snake_case for event names
- Be descriptive but concise
- Use consistent naming patterns

### 2. Properties
- Include relevant context (user_id, timestamp, etc.)
- Don't include sensitive information
- Use consistent data types

### 3. User Privacy
- Always respect user privacy settings
- Don't track personally identifiable information without consent
- Use `optInCapturing()` and `optOutCapturing()` as needed

### 4. Performance
- Don't track too many events too frequently
- Batch events when possible
- Use async operations for non-critical tracking

## Testing and Debugging

### Enable Debug Mode
Debug mode is already enabled in your configuration. You'll see PostHog logs in your console.

### View Events in PostHog Dashboard
1. Go to your PostHog dashboard
2. Navigate to "Events" section
3. You should see events appearing in real-time

### Common Issues
- **Events not appearing**: Check API key and host configuration
- **User identification issues**: Ensure `identify()` is called after login
- **Screen tracking not working**: Verify `AnalyticsWrapper` is properly used

## Next Steps

1. **Add analytics to other screens**: Use the `AnalyticsWrapper` or manual tracking
2. **Track key user journeys**: Monitor how users progress through your app
3. **Set up funnels**: Track conversion rates for important flows
4. **Create dashboards**: Build custom views in PostHog for your team
5. **A/B testing**: Use PostHog's feature flags for experimentation

## Support

- [PostHog Flutter Documentation](https://posthog.com/docs/libraries/flutter)
- [PostHog Help Center](https://posthog.com/help)
- [PostHog Community](https://posthog.com/slack)

## Example Implementation

See `lib/screens/auth/login_screen.dart` for a complete example of how to integrate PostHog analytics into your screens.
