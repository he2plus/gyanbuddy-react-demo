import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

// Platform-specific imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

// App-specific imports
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/new_login_screen.dart';
import 'screens/confirmation/confirmation_screen.dart';
import 'screens/home/new_home_content_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/splash/image_splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/profile/credits_screen.dart';
import 'utils/env.dart';
import 'utils/animation_utils.dart';
import 'utils/game_animations.dart';
import 'utils/connected_page_transitions.dart';
import 'utils/web_app_ready.dart';
import 'blocs/index.dart';
import 'services/index.dart';
import 'services/firebase_service.dart';
import 'services/app_lifecycle_service.dart';
import 'theme/app_theme.dart';
import 'widgets/rotating_circle_animation.dart';
import 'widgets/loading_screen.dart';
import 'widgets/web_responsive_wrapper.dart';
import 'widgets/global_splash_wrapper.dart';
import 'utils/web_size_utils.dart';
import 'screens/module/module_chapter_screen.dart' show routeObserver;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 1000
    ..maximumSizeBytes = 200 << 20;

  // Register Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize environment
  await Env.initialize();

  // Initialize platform-specific services
  await _initializePlatformServices();

  // Initialize Firebase (non-blocking)
  try {
    await FirebaseService.instance.initialize();
    if (kDebugMode) {
      print('✅ Firebase initialized successfully');
    }

    // Initialize notification service
    await NotificationService().initialize();
  } catch (error) {
    if (kDebugMode) {
      print(
          '❌ Firebase initialization failed, continuing without Firebase: $error');
    }
  }

  // Initialize PostHog analytics (non-blocking)
  PostHogService.initialize().catchError((error) {
    // Don't let PostHog initialization failure block the app
    if (kDebugMode) {
      print(
          'PostHog initialization failed, continuing without analytics: $error');
    }
  });

  // Initialize Sound Service (non-blocking)
  // try {
  //   await SoundService().initialize();
  //   if (kDebugMode) {
  //     print('✅ Sound Service initialized successfully');
  //   }
  // } catch (error) {
  //   if (kDebugMode) {
  //     print('❌ Sound Service initialization failed: $error');
  //   }
  // }

  // Initialize Vibration Service (non-blocking)
  try {
    // VibrationService is a singleton, just access it to initialize
    VibrationService();
    if (kDebugMode) {
      print('✅ Vibration Service initialized successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('❌ Vibration Service initialization failed: $error');
    }
  }

  runApp(const MyApp());
}

/// Initialize platform-specific services and permissions
Future<void> _initializePlatformServices() async {
  // Skip platform-specific initialization on web
  if (kIsWeb) {
    if (kDebugMode) {
      print('🌐 Running on Web - skipping platform-specific services');
    }
    return;
  }

  try {
    // Initialize device info
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    if (kDebugMode) {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        print(
            '📱 Android Device: ${androidInfo.model} (API ${androidInfo.version.sdkInt})');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        print('📱 iOS Device: ${iosInfo.model} (${iosInfo.systemVersion})');
      }
      print(
          '📦 App Version: ${packageInfo.version} (${packageInfo.buildNumber})');
    }

    // Request permissions based on platform
    await _requestPlatformPermissions();

    // Check and guide users for permanently denied permissions
    await _checkAndGuidePermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    if (kDebugMode) {
      print('✅ Platform services initialized successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('❌ Platform services initialization failed: $error');
    }
  }
}

/// Request platform-specific permissions
Future<void> _requestPlatformPermissions() async {
  if (kIsWeb) return; // Skip on web

  try {
    if (Platform.isAndroid) {
      // Android permissions - only request essential ones
      final permissions = [
        Permission.notification,
      ];

      final statuses = await permissions.request();

      if (kDebugMode) {
        for (final permission in permissions) {
          final status = statuses[permission];
          print(
              '🔐 Android Permission ${permission.toString()}: ${status?.toString()}');

          // Provide guidance for denied permissions
          if (status == PermissionStatus.permanentlyDenied) {
            print(
                '⚠️ Permission ${permission.toString()} is permanently denied. User needs to enable it in Settings.');
          }
        }
      }
    } else if (Platform.isIOS) {
      // iOS permissions - request only essential ones and handle gracefully
      final permissions = [
        Permission.notification,
      ];

      // Check current status first
      for (final permission in permissions) {
        final currentStatus = await permission.status;

        if (kDebugMode) {
          print(
              '🔍 Current iOS Permission ${permission.toString()}: ${currentStatus.toString()}');
        }

        // Only request if not permanently denied
        if (currentStatus != PermissionStatus.permanentlyDenied) {
          final status = await permission.request();

          if (kDebugMode) {
            print(
                '🔐 iOS Permission ${permission.toString()}: ${status.toString()}');

            if (status == PermissionStatus.permanentlyDenied) {
              print(
                  '⚠️ Permission ${permission.toString()} is permanently denied.');
              print(
                  '📱 User needs to go to Settings > Privacy & Security > Notifications > GyaanBuddy to enable notifications.');
            } else if (status == PermissionStatus.denied) {
              print(
                  'ℹ️ Permission ${permission.toString()} was denied. Will ask again next time.');
            } else if (status == PermissionStatus.granted) {
              print(
                  '✅ Permission ${permission.toString()} granted successfully!');
            }
          }
        } else {
          if (kDebugMode) {
            print(
                '⚠️ Permission ${permission.toString()} is permanently denied. Skipping request.');
            print(
                '📱 To enable: Settings > Privacy & Security > Notifications > GyaanBuddy');
          }
        }
      }

      // Optional permissions - only request if needed for specific features
      // These are commented out to avoid overwhelming the user
      /*
      final optionalPermissions = [
        Permission.microphone,
        Permission.camera,
        Permission.locationWhenInUse,
      ];
      
      for (final permission in optionalPermissions) {
        final status = await permission.status;
        if (kDebugMode) {
          print('🔍 Optional iOS Permission ${permission.toString()}: ${status.toString()}');
        }
      }
      */
    }
  } catch (error) {
    if (kDebugMode) {
      print('❌ Permission request failed: $error');
    }
  }
}

/// Check if app settings can be opened for permission management
Future<void> _checkAndGuidePermissions() async {
  if (kIsWeb) return; // Skip on web

  if (Platform.isIOS) {
    // Check all permission statuses
    final permissions = [
      Permission.notification,
      Permission.microphone,
      Permission.camera,
      Permission.locationWhenInUse,
    ];

    if (kDebugMode) {
      print('🔍 Current iOS Permission Status:');
      for (final permission in permissions) {
        final status = await permission.status;
        print('   ${permission.toString()}: ${status.toString()}');
      }
    }

    // Check notification permission specifically
    final notificationStatus = await Permission.notification.status;

    if (notificationStatus == PermissionStatus.permanentlyDenied) {
      if (kDebugMode) {
        print(
            '📱 Notification permission shows as permanently denied in code.');
        print('🔧 If you enabled it in Settings, try:');
        print('   1. Force close the app completely');
        print('   2. Reopen the app');
        print('   3. Or restart the iOS Simulator');
        print('');
        print(
            '💡 The permission status might be cached. Restarting should fix it.');
      }

      // Try to refresh permission status
      await _refreshPermissionStatus();
    } else if (notificationStatus == PermissionStatus.granted) {
      if (kDebugMode) {
        print('✅ Notification permission is granted!');
      }
    }
  }
}

/// Refresh permission status to get latest from iOS
Future<void> _refreshPermissionStatus() async {
  if (kIsWeb) return; // Skip on web

  if (Platform.isIOS) {
    try {
      // Force a small delay to allow iOS to update
      await Future.delayed(const Duration(milliseconds: 500));

      final notificationStatus = await Permission.notification.status;

      if (kDebugMode) {
        print(
            '🔄 Refreshed notification status: ${notificationStatus.toString()}');

        if (notificationStatus == PermissionStatus.granted) {
          print('✅ Notification permission is now granted!');
        } else {
          print('⚠️ Still showing as: ${notificationStatus.toString()}');
          print('💡 Try restarting the iOS Simulator or device');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing permission status: $e');
      }
    }
  }
}

/// Initialize local notifications
Future<void> _initializeLocalNotifications() async {
  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('📱 Notification tapped: ${response.payload}');
        }
      },
    );

    if (kDebugMode) {
      print('✅ Local notifications initialized successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('❌ Local notifications initialization failed: $error');
    }
  }
}

/// Firebase background message handler
/// This function must be a top-level function (not a class method)
/// and must be called before runApp()
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('📱 Background message received: ${message.messageId}');
    print('📱 Message data: ${message.data}');
    print('📱 Message notification: ${message.notification?.title}');
  }

  // Handle background message here
  // You can perform actions like:
  // - Update local database
  // - Show local notification
  // - Update app state
  // - Sync data with server

  // Show local notification for background message
  try {
    // Store notification locally using NotificationService
    await NotificationService().showBackgroundNotification(message);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error showing background notification: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes globally
    AppLifecycleService().handleLifecycleChange(state);

    // We'll handle QuizBloc lifecycle in the individual screens that use it
    // This ensures we don't have context issues
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc()..add(const LoadCurrentUser()),
        ),
        BlocProvider<QuizBloc>(
          create: (context) => QuizBloc(),
        ),
        BlocProvider<SubjectBloc>(
          create: (context) => SubjectBloc(),
        ),
        BlocProvider<ModuleContentBloc>(
          create: (context) => ModuleContentBloc(),
        ),
        BlocProvider<ModuleChapterBloc>(
          create: (context) => ModuleChapterBloc(ModuleContentApiService()),
        ),
        BlocProvider<ModuleQuestionsBloc>(
          create: (context) => ModuleQuestionsBloc(),
        ),
        BlocProvider<MissionBloc>(
          create: (context) =>
              MissionBloc(missionApiService: MissionApiService()),
        ),
        BlocProvider<MissionContentBloc>(
          create: (context) =>
              MissionContentBloc(missionApiService: MissionApiService()),
        ),
        BlocProvider<UserTestBloc>(
          create: (context) => UserTestBloc(),
        ),
      ],
      // For web: wrap with MediaQuery override BEFORE ScreenUtilInit
      // This ensures ScreenUtil sees the constrained size
      child: kIsWeb
          ? Builder(
              builder: (context) {
                final mediaQueryData = MediaQuery.of(context);
                // On web, tell ScreenUtil the screen is design-size
                // This prevents over-scaling of .w, .h, .r values
                return MediaQuery(
                  data: mediaQueryData.copyWith(
                    size: const Size(430, 932), // Match design size
                    textScaler: TextScaler.linear(1.0),
                  ),
                  child: _buildScreenUtilInit(),
                );
              },
            )
          : _buildScreenUtilInit(),
    );
  }

  Widget _buildScreenUtilInit() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      fontSizeResolver: (fontSize, instance) {
        if (kIsWeb) {
          return fontSize.toDouble();
        }
        // Use scaleText directly to avoid recursive setSp call
        return fontSize * instance.scaleText;
      },
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Gyan Buddy Student',
          theme: AppTheme.lightTheme,
          home: kIsWeb ? const LoginOrHomeScreen() : const ImageSplashScreen(),
          navigatorKey: GlobalLogoutService.navigatorKey,
          navigatorObservers: [
            PosthogObserver(),
            routeObserver,
          ],
          // Apply GlobalSplashWrapper for splash effects everywhere + MediaQuery override for web
          builder: (context, child) {
            Widget wrappedChild = GlobalSplashWrapper(
              child: child ?? const SizedBox.shrink(),
            );

            if (kIsWeb) {
              final mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  size: const Size(430, 932), // Force design size on web
                  textScaler: TextScaler.linear(1.0),
                ),
                child: wrappedChild,
              );
            }

            return wrappedChild;
          },
          // Use onGenerateRoute for all routes to ensure connected animations
          onGenerateRoute: (settings) {
            Widget page;

            switch (settings.name) {
              case '/onboarding':
                page = const OnboardingScreen();
                // Onboarding uses fade through for smooth entrance
                return ConnectedPageTransitions.fadeThrough(page: page);
              case '/login':
                page = const NewLoginScreen();
                // Login uses fade through for clean entrance
                return ConnectedPageTransitions.fadeThrough(page: page);
              case '/home':
                final args = settings.arguments as Map<String, dynamic>?;
                final initialTab = args?['initialTab'] as int?;
                page = NewHomeContentScreen(initialTabIndex: initialTab);
                // Home uses depth transition for immersive feel
                return ConnectedPageTransitions.depthTransition(page: page);
              case '/confirmation':
                page = const ConfirmationScreen();
                // Confirmation uses connected scale for continuation
                return ConnectedPageTransitions.connectedScale(page: page);
              case '/leaderboard':
                page = const LeaderboardScreen();
                // Leaderboard uses shared axis vertical (hierarchical)
                return ConnectedPageTransitions.sharedAxisVertical(page: page);
              case '/notifications':
                page = const NotificationScreen();
                // Notifications slide in from top conceptually
                return ConnectedPageTransitions.sharedAxisVertical(
                    page: page, forward: true);
              case '/credits':
                page = const CreditsScreen();
                // Credits uses fade through for smooth entrance
                return ConnectedPageTransitions.fadeThrough(page: page);
              default:
                page = const NewLoginScreen();
                return ConnectedPageTransitions.fadeThrough(page: page);
            }
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Brand colors
  static const Color _primaryBlue = Color(0xFF0A1172);
  static const Color _accentCyan = Color(0xFF00D4FF);

  late AnimationController _topLogoController;
  late AnimationController _centerTextController;
  late AnimationController _bottomLogoController;
  late AnimationController _pulseController;

  late Animation<double> _topLogoSlideAnimation;
  late Animation<double> _topLogoOpacityAnimation;
  late Animation<double> _centerTextScaleAnimation;
  late Animation<double> _centerTextOpacityAnimation;
  late Animation<double> _taglineOpacityAnimation;
  late Animation<double> _bottomLogoSlideAnimation;
  late Animation<double> _bottomLogoOpacityAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLoginStatus();
  }

  void _initializeAnimations() {
    // Top logo animation - slides in from top left
    _topLogoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _topLogoSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _topLogoController,
      curve: Curves.easeOutBack,
    ));

    _topLogoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _topLogoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Center text animation
    _centerTextController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _centerTextScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _centerTextController,
      curve: Curves.elasticOut,
    ));

    _centerTextOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _centerTextController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _taglineOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _centerTextController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    // Bottom logo animation - slides in from bottom right
    _bottomLogoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bottomLogoSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _bottomLogoController,
      curve: Curves.easeOutBack,
    ));

    _bottomLogoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _bottomLogoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Pulse animation for subtle breathing effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations in sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start top logo animation immediately
    _topLogoController.forward();

    // Wait a bit then start center text animation
    await Future.delayed(const Duration(milliseconds: 400));
    _centerTextController.forward();

    // Start bottom logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    _bottomLogoController.forward();

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _topLogoController.dispose();
    _centerTextController.dispose();
    _bottomLogoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    // Track app launch
    PostHogService.capture('app_launched', properties: {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    });

    // Add a delay to show enhanced splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Let the UserBloc handle the login check
      // Use connected transition for seamless flow from splash
      Navigator.of(context).pushReplacement(
        ConnectedPageTransitions.depthTransition(
            page: const LoginOrHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBlue,
      body: Stack(
        children: [
          // Solid dark blue background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: _primaryBlue,
          ),

          // Top left arrow logo
          AnimatedBuilder(
            animation: _topLogoController,
            builder: (context, child) {
              return Positioned(
                top: (-30).h + _topLogoSlideAnimation.value,
                left: (-15).w + _topLogoSlideAnimation.value,
                child: Opacity(
                  opacity: _topLogoOpacityAnimation.value,
                  child: Image.asset(
                    'assets/images/arrow.jpeg',
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback: Custom painted arrow if image fails
                      return CustomPaint(
                        size: Size(40.w, 40.w),
                        painter: _ArrowLogoPainter(color: Colors.white),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Center content - GyanBuddy text and tagline
          Center(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_centerTextController, _pulseController]),
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      _centerTextScaleAnimation.value * _pulseAnimation.value,
                  child: Opacity(
                    opacity: _centerTextOpacityAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // GyanBuddy text
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gyan',
                              style: TextStyle(
                                fontSize: 48.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Buddy',
                              style: TextStyle(
                                fontSize: 48.sp,
                                fontWeight: FontWeight.w700,
                                color: _accentCyan,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h),

                        // Tagline
                        Opacity(
                          opacity: _taglineOpacityAnimation.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'A smarter way to ',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'learn',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _accentCyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom right "G" letter
          AnimatedBuilder(
            animation: _bottomLogoController,
            builder: (context, child) {
              return Positioned(
                bottom: (-60).h + _bottomLogoSlideAnimation.value,
                right: (-10).w + _bottomLogoSlideAnimation.value,
                child: Transform.rotate(
                  angle: -0.6, // Slight tilt
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 200.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Custom painter for arrow logo fallback
class _ArrowLogoPainter extends CustomPainter {
  final Color color;

  _ArrowLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw a stylized arrow pointing up-right
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;
    final arrowSize = size.width * 0.35;

    // Arrow body
    path.moveTo(centerX - arrowSize * 0.3, centerY + arrowSize * 0.5);
    path.lineTo(centerX - arrowSize * 0.3, centerY - arrowSize * 0.2);
    path.lineTo(centerX + arrowSize * 0.2, centerY - arrowSize * 0.2);
    path.lineTo(centerX + arrowSize * 0.2, centerY - arrowSize * 0.5);
    path.lineTo(centerX + arrowSize * 0.5, centerY - arrowSize * 0.2);
    path.lineTo(centerX + arrowSize * 0.5, centerY + arrowSize * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for G letter fallback
class _GLetterPainter extends CustomPainter {
  final Color color;

  _GLetterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.35;

    // Draw a partial G shape
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0.3, 4.5, false, paint);

    // Horizontal bar of G
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.8, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginOrHomeScreen extends StatefulWidget {
  const LoginOrHomeScreen({super.key});

  @override
  State<LoginOrHomeScreen> createState() => _LoginOrHomeScreenState();
}

class _LoginOrHomeScreenState extends State<LoginOrHomeScreen> {
  bool _isCaching = false;
  bool _isTransitioning = false;
  final GlobalKey<LoadingScreenState> _loadingScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Trigger the LoadCurrentUser event to check authentication status
    context.read<UserBloc>().add(const LoadCurrentUser());
  }

  /// Trigger the visual transition and warm the cache in the background.
  Future<void> _triggerCachingAndTransition() async {
    if (_isCaching) return; // Prevent duplicate calls

    setState(() {
      _isCaching = true;
    });

    // Play app startup sound when data loading begins
    // SoundService().playAppStartup();

    try {
      // Initialize cache service
      await CacheDataService.instance.initialize();

      if (kDebugMode) {
        print('🚀 LoginOrHomeScreen: Starting background data prefetch...');
      }

      unawaited(_prefetchDataInBackground());
    } catch (e) {
      if (kDebugMode) {
        print('❌ LoginOrHomeScreen: Cache init error: $e');
      }
      // Continue even if caching fails
    }

    // Trigger the visual transition animation (dots merge, circle scales up)
    if (mounted && !_isTransitioning) {
      setState(() {
        _isTransitioning = true;
      });
      _loadingScreenKey.currentState?.triggerTransition();
    }
  }

  Future<void> _prefetchDataInBackground() async {
    try {
      final status = await CacheDataService.instance.prefetchAllData();

      if (kDebugMode) {
        print('✅ LoginOrHomeScreen: Background prefetch complete - $status');
      }

      PostHogService.capture('cache_prefetch_complete', properties: {
        'user_cached': status.userSuccess,
        'subjects_cached': status.subjectsSuccess,
        'modules_cached': status.modulesSuccess,
        'leaderboard_cached': status.leaderboardSuccess,
        'success_count': status.successCount,
        'all_success': status.allSuccess,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ LoginOrHomeScreen: Background prefetch error: $e');
      }
    }
  }

  /// Called when the loader's exit animation completes
  void _onTransitionComplete() {
    if (mounted) {
      // Navigate with circle expand transition
      Navigator.of(context).pushReplacement(
        CircleExpandTransition(
          page: const NewHomeContentScreen(),
          startColor: Colors.white,
          endColor: const Color(0xFF365DEA),
          duration: const Duration(milliseconds: 800),
        ),
      );
      if (kIsWeb) {
        Future.delayed(const Duration(milliseconds: 900), markAppReadyForWeb);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserAuthenticated) {
          // User is authenticated, trigger caching then visual transition
          _triggerCachingAndTransition();
        } else if (state is UserUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
          if (kIsWeb) {
            Future.delayed(
              const Duration(milliseconds: 350),
              markAppReadyForWeb,
            );
          }
        }
      },
      child: LoadingScreen(
        key: _loadingScreenKey,
        primaryColor: const Color(0xFF00167A),
        onTransitionComplete: _onTransitionComplete,
      ),
    );
  }
}
