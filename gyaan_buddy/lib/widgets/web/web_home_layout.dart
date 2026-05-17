import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../../models/study_timer.dart';
import '../../screens/subject/subject_screen.dart';
import '../../screens/mission/mission_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../home/new_home_content.dart';
import '../dashboard/dashboard_content.dart';
import 'web_navigation_drawer.dart';
import 'web_app_bar.dart';
import 'web_page_transition.dart';

/// Web-specific layout with sidebar navigation and app bar
/// This replaces the mobile bottom navigation with a persistent sidebar
class WebHomeLayout extends StatefulWidget {
  final int? initialTabIndex;

  const WebHomeLayout({
    super.key,
    this.initialTabIndex,
  });

  @override
  State<WebHomeLayout> createState() => _WebHomeLayoutState();
}

class _WebHomeLayoutState extends State<WebHomeLayout>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _initialSubjectIndex = 0;
  late StudyTimer _studyTimer;
  Color _currentPageColor = Colors.blue;

  // For responsive drawer behavior
  bool _isDrawerExpanded = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Home',
    'Subjects',
    'Leaderboard',
    'Missions',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
    WidgetsBinding.instance.addObserver(this);
    _studyTimer = StudyTimer();
    _studyTimer.addListener(_onTimerChanged);
  }

  void _onTimerChanged() {
    setState(() {});
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

  List<WebNavigationItem> get _navigationItems => [
        WebNavigationItem(
          imagePath: 'assets/images/home.png',
          label: 'Home',
        ),
        WebNavigationItem(
          imagePath: 'assets/images/subject.png',
          label: 'Subjects',
        ),
        WebNavigationItem(
          imagePath: 'assets/images/dashboard.png',
          label: 'Leaderboard',
        ),
        WebNavigationItem(
          imagePath: 'assets/images/mission.png',
          label: 'Missions',
        ),
        WebNavigationItem(
          imagePath: 'assets/images/you.png',
          label: 'Profile',
        ),
      ];

  Widget _buildHomeLogoutButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: TextButton.icon(
        onPressed: () {
          context.read<UserBloc>().add(const LogoutUser());
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[700],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: isTablet
          ? Drawer(
              width: 260,
              child: _buildNavigationDrawer(),
            )
          : null,
      body: Row(
        children: [
          // Permanent sidebar for desktop
          if (!isTablet) _buildNavigationDrawer(),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Web App Bar
                WebAppBar(
                  title: _titles[_selectedIndex],
                  onMenuPressed: isTablet
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                  showSearch: _selectedIndex == 0 || _selectedIndex == 1,
                  trailing:
                      _selectedIndex == 0 ? _buildHomeLogoutButton() : null,
                ),

                // Content area
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        String? userName;
        String? userInitial;
        String? classLabel;
        final userBloc = context.read<UserBloc>();

        if (state is UserAuthenticated) {
          userName = state.user.firstName.isNotEmpty
              ? state.user.firstName
              : state.user.username;
          userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';
        } else {
          final currentUser = userBloc.currentUser;
          if (currentUser != null) {
            userName = currentUser.firstName.isNotEmpty
                ? currentUser.firstName
                : currentUser.username;
            userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';
          }
        }

        if (userBloc.currentClassName != null &&
            userBloc.currentClassName!.isNotEmpty) {
          classLabel = _formatClassLabel(userBloc.currentClassName!);
        } else if (userBloc.currentGradeName != null &&
            userBloc.currentGradeName!.isNotEmpty) {
          classLabel = _formatClassLabel(userBloc.currentGradeName!);
        }

        return WebNavigationDrawer(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) async {
            // await SoundService().playTabSwitch();
            setState(() {
              _selectedIndex = index;
            });

            // Close drawer on tablet when item selected
            if (MediaQuery.of(context).size.width < 1100) {
              Navigator.of(context).pop();
            }
          },
          items: _navigationItems,
          userName: userName,
          userInitial: userInitial,
          classLabel: classLabel,
        );
      },
    );
  }

  String _formatClassLabel(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.toLowerCase().startsWith('class ')) {
      return trimmedValue;
    }
    return 'Class $trimmedValue';
  }

  Widget _buildContent() {
    return AnimatedPageSwitcher(
      currentIndex: _selectedIndex,
      duration: const Duration(milliseconds: 320),
      randomizeDirection: true,
      randomizeEffect: true,
      child: _buildBody(key: ValueKey(_selectedIndex)),
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
              _selectedIndex = 1;
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
}
