import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_item.dart';
import 'global_logout_service.dart';

/// Service for handling Firebase Cloud Messaging and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Initialize Firebase messaging listeners
      await _initializeFirebaseMessaging();

      // Test FCM token retrieval
      await _testFCMToken();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ NotificationService initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ NotificationService initialization failed: $error');
      }
    }
  }

  /// Initialize Firebase messaging listeners
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("📱 Foreground message: ${message.notification?.title}");
        }

        // Show local notification for foreground messages
        showForegroundNotification(message);
      });

      // Listen for notification clicks when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("🚀 Notification clicked: ${message.notification?.title}");
        }

        // Handle notification click - navigate to appropriate screen
        _handleNotificationClick(message);
      });

      // Check for initial message when app is opened from terminated state
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print(
              "💀 App opened from terminated state: ${initialMessage.notification?.title}");
        }

        // Handle initial message - navigate to appropriate screen
        _handleNotificationClick(initialMessage);
      }

      if (kDebugMode) {
        print('✅ Firebase messaging listeners initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Firebase messaging initialization failed: $error');
      }
    }
  }

  /// Show local notification for foreground messages
  Future<void> showForegroundNotification(RemoteMessage message) async {
    try {
      // Store notification locally
      final notification = NotificationItem(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? 'You have a new message',
        type: message.data['type'] ?? 'general',
        timestamp: DateTime.now(),
        data: message.data.isNotEmpty ? message.data : null,
      );
      await storeNotification(notification);

      const androidNotificationDetails = AndroidNotificationDetails(
        'foreground_channel',
        'Foreground Messages',
        channelDescription: 'Notifications received when app is in foreground',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? 'You have a new message',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing foreground notification: $e');
      }
    }
  }

  /// Show local notification for background messages
  Future<void> showBackgroundNotification(RemoteMessage message) async {
    try {
      // Store notification locally
      final notification = NotificationItem(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? 'You have a new message',
        type: message.data['type'] ?? 'general',
        timestamp: DateTime.now(),
        data: message.data.isNotEmpty ? message.data : null,
      );
      await storeNotification(notification);

      const androidNotificationDetails = AndroidNotificationDetails(
        'background_channel',
        'Background Messages',
        channelDescription: 'Notifications received when app is in background',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? 'You have a new message',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing background notification: $e');
      }
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }

    // You can add custom logic here for handling notification taps
    // For example, parsing the payload and navigating to specific screens
  }

  /// Handle notification click navigation
  void _handleNotificationClick(RemoteMessage message) {
    try {
      // You can customize navigation based on message data
      final data = message.data;

      if (kDebugMode) {
        print('📱 Handling notification click with data: $data');
      }

      // Example navigation logic based on message type
      if (data.containsKey('screen')) {
        final screen = data['screen'];
        switch (screen) {
          case 'home':
            // Navigate to home screen
            _navigateToScreen('/home');
            break;
          case 'leaderboard':
            // Navigate to leaderboard screen
            _navigateToScreen('/leaderboard');
            break;
          case 'profile':
            // Navigate to profile screen
            _navigateToScreen('/profile');
            break;
          case 'notifications':
            // Navigate to notifications screen
            _navigateToScreen('/notifications');
            break;
          default:
            // Default to home screen
            _navigateToScreen('/home');
        }
      } else {
        // Default navigation to home screen
        _navigateToScreen('/home');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification click: $e');
      }
    }
  }

  /// Navigate to a specific screen
  void _navigateToScreen(String routeName) {
    if (kDebugMode) {
      print('🧭 Navigation intent: $routeName');
    }

    // Navigate using the global navigator key
    GlobalLogoutService.navigatorKey.currentState?.pushNamed(routeName);
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidPlugin?.requestNotificationsPermission() ?? false;

        if (kDebugMode) {
          print('🔐 Android notification permission: $granted');
        }

        return granted;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;

        if (kDebugMode) {
          print('🔐 iOS notification permission: $granted');
        }

        return granted;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting notification permissions: $e');
      }
      return false;
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        print(
            '🔑 FCM Token retrieved: ${token != null ? "${token.length} characters" : "null"}');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      if (kDebugMode) {
        print('📢 Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Test FCM token retrieval
  Future<void> _testFCMToken() async {
    try {
      if (kDebugMode) {
        print('🔍 Testing FCM token retrieval...');
      }

      final token = await getFCMToken();

      if (token != null) {
        if (kDebugMode) {
          print('✅ FCM Token retrieved successfully!');
          print('📏 Token length: ${token.length} characters');
          print('🎯 Project ID: gyaanbuddy-600f2');
          print('📱 Sender ID: 130750342442');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to retrieve FCM token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing FCM token: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('📢 Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic $topic: $e');
      }
    }
  }

  // Notification Storage Methods

  /// Store a notification locally
  Future<void> storeNotification(NotificationItem notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getStoredNotifications();

      // Add new notification at the beginning
      notifications.insert(0, notification);

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }

      // Save to SharedPreferences
      final notificationsJson = notifications.map((n) => n.toMap()).toList();
      await prefs.setString(
          'stored_notifications', jsonEncode(notificationsJson));

      if (kDebugMode) {
        print('💾 Stored notification: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing notification: $e');
      }
    }
  }

  /// Get all stored notifications
  Future<List<NotificationItem>> getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('stored_notifications');

      if (notificationsJson == null) {
        return [];
      }

      final List<dynamic> notificationsList = jsonDecode(notificationsJson);
      return notificationsList
          .map((json) => NotificationItem.fromMap(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting stored notifications: $e');
      }
      return [];
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = await getStoredNotifications();
      final notificationIndex =
          notifications.indexWhere((n) => n.id == notificationId);

      if (notificationIndex != -1) {
        notifications[notificationIndex].isRead = true;

        final prefs = await SharedPreferences.getInstance();
        final notificationsJson = notifications.map((n) => n.toMap()).toList();
        await prefs.setString(
            'stored_notifications', jsonEncode(notificationsJson));

        if (kDebugMode) {
          print('✅ Marked notification as read: $notificationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking notification as read: $e');
      }
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getStoredNotifications();
      notifications.removeWhere((n) => n.id == notificationId);

      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => n.toMap()).toList();
      await prefs.setString(
          'stored_notifications', jsonEncode(notificationsJson));

      if (kDebugMode) {
        print('🗑️ Deleted notification: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting notification: $e');
      }
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('stored_notifications');

      if (kDebugMode) {
        print('🧹 Cleared all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing all notifications: $e');
      }
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final notifications = await getStoredNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Create sample notifications for testing
  Future<void> createSampleNotifications() async {
    try {
      final sampleNotifications = [
        NotificationItem(
          id: 'sample_1',
          title: 'Welcome to GyaanBuddy!',
          body:
              'Start your learning journey with our interactive quizzes and lessons.',
          type: 'update',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          data: {'screen': 'home'},
        ),
        NotificationItem(
          id: 'sample_2',
          title: 'Quiz Completed!',
          body:
              'Great job! You scored 85% on the Math quiz. Keep up the good work!',
          type: 'achievement',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          data: {'screen': 'leaderboard'},
        ),
        NotificationItem(
          id: 'sample_3',
          title: 'Daily Study Reminder',
          body:
              'Don\'t forget to complete your daily study session. Consistency is key!',
          type: 'reminder',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          data: {'screen': 'home'},
        ),
        NotificationItem(
          id: 'sample_4',
          title: 'New Quiz Available',
          body:
              'A new Science quiz has been added to your curriculum. Check it out!',
          type: 'quiz',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          data: {'screen': 'home'},
        ),
      ];

      for (final notification in sampleNotifications) {
        await storeNotification(notification);
      }

      if (kDebugMode) {
        print('✅ Created ${sampleNotifications.length} sample notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating sample notifications: $e');
      }
    }
  }
}
