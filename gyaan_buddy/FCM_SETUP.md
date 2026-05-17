# Firebase Cloud Messaging (FCM) Setup Guide

## Overview
Your Flutter app already has a comprehensive FCM setup implemented. This guide covers the current implementation and how to use it.

## Current Implementation Status ✅

### 1. Dependencies (Already Configured)
```yaml
firebase_messaging: ^16.0.0
flutter_local_notifications: ^18.0.0
```

### 2. Firebase Configuration Files
- ✅ `android/app/google-services.json` - Android configuration
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS configuration
- ✅ Firebase project: `gyaanbuddy-600f2`

### 3. Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)
- ✅ Firebase configuration included
- ✅ PostHog analytics configured
- ⚠️ **Missing**: FCM-specific permissions and services

#### iOS (`ios/Runner/Info.plist`)
- ✅ Background modes configured: `fetch` and `remote-notification`
- ✅ Firebase App Delegate Proxy disabled
- ✅ PostHog analytics configured

### 4. Flutter Implementation
- ✅ `FirebaseMessagingService` - Main FCM service
- ✅ `FCMBackendService` - Backend integration service
- ✅ Initialization in `main.dart`
- ✅ Local notifications setup
- ✅ Token management
- ✅ Topic subscription/unsubscription

## Setup Completion Steps

### 1. Update Android Manifest (Required)
Add FCM-specific permissions and services to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    
    <application
        android:label="GyaanBuddy"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add FCM service -->
        <service
            android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        
        <!-- Rest of your existing configuration... -->
    </application>
</manifest>
```

### 2. Update iOS App Delegate (Required)
Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Set messaging delegate
    Messaging.messaging().delegate = self
    
    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
  }
}
```

### 3. Initialize Backend Service
In your app initialization, configure the backend service:

```dart
// In main.dart or where you initialize your app
FirebaseMessagingService().initializeBackend(
  baseUrl: 'https://your-backend-api.com',
  apiKey: 'your-api-key',
);
```

## Testing FCM Setup

### 1. Create FCM Test Screen
Use the provided `FCMTestScreen` to test your FCM setup:

```dart
// Navigate to test screen
Navigator.pushNamed(context, '/fcm-test');
```

### 2. Test Features
- ✅ Get FCM Token
- ✅ Subscribe/Unsubscribe to topics
- ✅ Send test notifications
- ✅ Handle foreground/background messages
- ✅ Local notification display

### 3. Backend Integration
The `FCMBackendService` provides these endpoints:
- `POST /api/fcm/token` - Register FCM token
- `PUT /api/fcm/token/{userId}` - Update FCM token
- `DELETE /api/fcm/token/{userId}` - Delete FCM token
- `POST /api/fcm/topics/subscribe` - Subscribe to topics
- `POST /api/fcm/topics/unsubscribe` - Unsubscribe from topics

## Usage Examples

### 1. Initialize FCM Service
```dart
// Initialize with user ID for backend integration
await FirebaseMessagingService().initialize(userId: 'user123');
```

### 2. Subscribe to Topics
```dart
// Subscribe to general notifications
await FirebaseMessagingService().subscribeToTopic('general');

// Subscribe to user-specific notifications
await FirebaseMessagingService().subscribeToTopic('user_123');
```

### 3. Get FCM Token
```dart
String? token = await FirebaseMessagingService().getToken();
print('FCM Token: $token');
```

### 4. Handle Notifications
The service automatically handles:
- Foreground messages (shows local notification)
- Background messages (handled by Firebase)
- App launch from notification (navigates appropriately)

## Troubleshooting

### Common Issues

1. **Token not generated**
   - Check Firebase configuration files
   - Verify internet connection
   - Check device permissions

2. **Notifications not showing**
   - Verify notification permissions
   - Check notification channel setup
   - Ensure app is not in Do Not Disturb mode

3. **Backend integration failing**
   - Verify API endpoints
   - Check authentication headers
   - Ensure proper error handling

### Debug Commands
```dart
// Enable debug logging
if (kDebugMode) {
  print('FCM Token: ${await FirebaseMessagingService().getToken()}');
  print('Is Initialized: ${FirebaseMessagingService().isInitialized}');
}
```

## Next Steps

1. ✅ Complete Android manifest updates
2. ✅ Update iOS App Delegate
3. ✅ Test FCM functionality using test screen
4. ✅ Integrate with your backend API
5. ✅ Implement notification navigation logic
6. ✅ Add notification preferences UI

## Support

For issues or questions:
1. Check Firebase Console for token registration
2. Verify notification delivery in Firebase Console
3. Test with Firebase Console's "Send test message" feature
4. Review debug logs for detailed error information

