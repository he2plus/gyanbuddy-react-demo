import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/study_timer.dart';
import '../../widgets/home/new_home_content.dart';
import '../../widgets/home/top_timer.dart';
import '../../widgets/dashboard/dashboard_content.dart';
import '../subject/subject_screen.dart';
import '../mission/mission_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/animated_navigation_bar.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/web/web_home_layout.dart';
import '../../widgets/web/web_page_transition.dart';
import '../../utils/connected_page_transitions.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';

/// A new Home Content Screen with a modern UI design
/// featuring:
/// - User greeting with profile avatar
/// - Progress indicator
/// - XP badge and notifications
/// - GyanBuddy leaderboard card with weekly king
/// - Dynamic subject grid fetched from SubjectBloc
class NewHomeContentScreen extends StatefulWidget {
  final int? initialTabIndex;

  const NewHomeContentScreen({super.key, this.initialTabIndex});

  @override
  State<NewHomeContentScreen> createState() => _NewHomeContentScreenState();
}

class _NewHomeContentScreenState extends State<NewHomeContentScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _initialSubjectIndex = 0;
  late StudyTimer _studyTimer;
  Color _currentPageColor = const Color(0xFF1E3A8A); // Primary blue

  @override
  void initState() {
    super.initState();
    // Set initial tab if provided
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
    WidgetsBinding.instance.addObserver(this);
    _studyTimer = StudyTimer();
    _studyTimer.addListener(_onTimerChanged);
  }

  void _onTimerChanged() {
    setState(() {
      // Rebuild the widget when timer changes
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studyTimer.removeListener(_onTimerChanged);
    _studyTimer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _studyTimer.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _studyTimer.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use web-specific layout with sidebar navigation on web
    if (kIsWeb) {
      return WebHomeLayout(initialTabIndex: widget.initialTabIndex);
    }

    // Mobile layout with floating bottom navigation bar
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main content that extends behind nav bar
          Positioned.fill(
            child: AnimatedScreenLayout(
              appBar: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: _studyTimer.showTopTimer ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: TopTimer(
                      studyTimer: _studyTimer,
                      backgroundColor: _currentPageColor,
                    ),
                  ),
                ],
              ),
              body: SmoothPageSwitcher(
                currentIndex: _selectedIndex,
                duration: const Duration(milliseconds: 350),
                child: _buildBody(key: ValueKey(_selectedIndex)),
              ),
              animationDuration: const Duration(milliseconds: 600),
              animationCurve: Curves.easeOutCubic,
              enableStaggeredAnimation: true,
              staggerDelay: const Duration(milliseconds: 100),
            ),
          ),
          // Floating bottom navigation bar with integrated glass blur
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({Key? key}) {
    switch (_selectedIndex) {
      case 0:
        return NewHomeContent(
          key: key,
          studyTimer: _studyTimer,
          onNavigateToSubject: (int subjectIndex) async {
            // await SoundService().playButtonClick();
            setState(() {
              _initialSubjectIndex = subjectIndex;
              _selectedIndex = 1; // Switch to Subject tab immediately
            });
          },
          onPageColorChanged: (Color color) {
            setState(() {
              _currentPageColor = color;
            });
          },
          onProfileTap: () {
            setState(() {
              _selectedIndex = 4;
            });
          },
        );
      case 1:
        return SubjectScreen(
            key: key, initialSubjectIndex: _initialSubjectIndex);
      case 2:
        return DashboardContent(key: key);
      case 3:
        return MissionScreen(key: key);
      case 4:
        return ProfileScreen(key: key);
      default:
        return NewHomeContent(
          key: key,
          studyTimer: _studyTimer,
          onPageColorChanged: (Color color) {
            setState(() {
              _currentPageColor = color;
            });
          },
          onProfileTap: () {
            setState(() {
              _selectedIndex = 4;
            });
          },
        );
    }
  }

  Widget _buildBottomNavigationBar() {
    final navigationItems = [
      NavigationItem(imagePath: 'assets/images/home.png', label: 'Home'),
      NavigationItem(imagePath: 'assets/images/subject.png', label: 'Subject'),
      NavigationItem(
          imagePath: 'assets/images/dashboard.png', label: 'Leaderboard'),
      NavigationItem(imagePath: 'assets/images/mission.png', label: 'Mission'),
      NavigationItem(
          imagePath: 'assets/images/you.png', label: 'You', size: 32.h),
    ];

    return AnimatedNavigationBar(
      selectedIndex: _selectedIndex,
      onItemSelected: (index) async {
        // await SoundService().playTabSwitch();
        setState(() {
          _selectedIndex = index;
        });
      },
      items: navigationItems,
    );
  }
}
