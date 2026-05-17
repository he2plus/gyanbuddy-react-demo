import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/user/user_bloc.dart';
import '../../models/user_model.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../widgets/smooth_scroll_wrapper.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool fromQuizScreen;

  const LeaderboardScreen({
    super.key,
    this.fromQuizScreen = false,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'all-time';
  final List<String> _periods = ['daily', 'weekly', 'monthly', 'all-time'];

  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Current user rank animation
  AnimationController? _userRankAnimationController;
  Animation<Offset>? _userRankSlideAnimation;
  Animation<double>? _userRankScaleAnimation;
  bool _hasAnimatedUserRank = false;

  // Helper function to convert hex string to Color
  Color _hexToColor(String? hexString, {Color fallback = Colors.blue}) {
    if (hexString == null || hexString.isEmpty) {
      return fallback;
    }
    try {
      String hex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallback;
    }
  }

  // Helper function to create light/pastel versions of color for gradients
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Colors.white,
    ];
  }

  List<Color> _getBottomGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
    ];
  }

  @override
  void initState() {
    super.initState();

    // Initialize circle animation controllers
    _circle1Controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _circle2Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _circle3Controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _circle1Animation = Tween<double>(
      begin: -20.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _circle1Controller,
      curve: Curves.easeInOut,
    ));

    _circle2Animation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _circle2Controller,
      curve: Curves.easeInOut,
    ));

    _circle3Animation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));

    // Initialize user rank animation if coming from quiz screen
    if (widget.fromQuizScreen) {
      _userRankAnimationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _userRankSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 5), // Start from far below
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _userRankAnimationController!,
        curve: Curves.easeOutBack,
      ));

      _userRankScaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _userRankAnimationController!,
        curve: Curves.easeOutBack,
      ));
    }

    // Load leaderboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _userRankAnimationController?.dispose();
    super.dispose();
  }

  void _loadLeaderboard({int? page}) {
    context.read<UserBloc>().add(LoadLeaderboard(
          page: page,
          limit: 20,
          period: _selectedPeriod,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _hexToColor("C5E1FF");
    final topGradientColors = _getGradientColors(baseColor);
    final bottomGradientColors = _getBottomGradientColors(baseColor);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // White base background
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),
          // Top gradient (1/4 of screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 0.25.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: topGradientColors,
                  stops: const [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0],
                ),
              ),
            ),
          ),
          // Bottom gradient (1/3 of screen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 0.33.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bottomGradientColors,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Circular shapes overlay
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    _AnimatedTranslatedCircle(
                      animation: _circle1Animation,
                      top: -100.h,
                      right: -100.w,
                      width: 300.w,
                      height: 300.w,
                      color: baseColor.withOpacity(0.15),
                    ),
                    _AnimatedTranslatedCircle(
                      animation: _circle2Animation,
                      top: 240.h,
                      left: 40.w,
                      width: 120.w,
                      height: 120.w,
                      color: baseColor.withOpacity(0.25),
                    ),
                    _AnimatedTranslatedCircle(
                      animation: _circle3Animation,
                      bottom: 240.h,
                      right: 20.w,
                      width: 50.w,
                      height: 50.w,
                      color: baseColor.withOpacity(0.25),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          RepaintBoundary(
            child: SafeArea(
              child: AnimatedScreenLayout(
                appBar: Column(
                  children: [
                    _buildHeader(),
                    if (!widget.fromQuizScreen) _buildPeriodFilter(),
                  ],
                ),
                body: _buildLeaderboardContent(),
                animationDuration: const Duration(milliseconds: 600),
                animationCurve: Curves.easeOutCubic,
                enableStaggeredAnimation: true,
                staggerDelay: const Duration(milliseconds: 100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 10,
            ),
          ),
          const Expanded(
            child: Text(
              'Leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadLeaderboard();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  period.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading leaderboard...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        } else if (state is LeaderboardLoaded) {
          return _buildLeaderboardList(state);
        } else if (state is LeaderboardError) {
          return _buildErrorState(state.message);
        } else {
          // If we're not in a leaderboard state, trigger loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadLeaderboard();
          });
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Initializing leaderboard...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildLeaderboardList(LeaderboardLoaded state) {
    if (state.users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Get current user ID
    final currentUser = context.read<UserBloc>().currentUser;
    final currentUserId = currentUser?.id;

    // Start animation if coming from quiz and not yet animated
    if (widget.fromQuizScreen &&
        !_hasAnimatedUserRank &&
        _userRankAnimationController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAnimatedUserRank) {
          _hasAnimatedUserRank = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _userRankAnimationController!.forward();
            }
          });
        }
      });
    }

    return SmoothScrollOverlay(
      showTopFade: true,
      showBottomFade: true,
      fadeHeight: 50.h,
      fadeColor: Colors.white,
      child: RefreshIndicator(
        onRefresh: () async => _loadLeaderboard(),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: state.users.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.users.length) {
              return _buildLoadMoreButton(state.currentPage);
            }

            final user = state.users[index];
            final rank = index + 1;
            final isCurrentUser = user.id == currentUserId;

            return _buildLeaderboardItem(user, rank,
                isCurrentUser: isCurrentUser);
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(User user, int rank,
      {bool isCurrentUser = false}) {
    final isTopThree = rank <= 3;

    Widget itemWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? Colors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: isCurrentUser ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Avatar
          CircleAvatar(
            radius: 25,
            backgroundImage:
                (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                    ? NetworkImage(user.profilePicture!)
                    : null,
            child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                ? Text(
                    user.firstName.isNotEmpty
                        ? user.firstName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Level ${user.levelNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.totalExp} XP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? Colors.orange : Colors.blue,
                ),
              ),
              Text(
                '${user.rewards} rewards',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Apply animation for current user if coming from quiz screen
    if (isCurrentUser &&
        widget.fromQuizScreen &&
        _userRankSlideAnimation != null &&
        _userRankScaleAnimation != null) {
      return AnimatedBuilder(
        animation: _userRankAnimationController!,
        builder: (context, child) {
          return SlideTransition(
            position: _userRankSlideAnimation!,
            child: ScaleTransition(
              scale: _userRankScaleAnimation!,
              child: child,
            ),
          );
        },
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  Widget _buildLoadMoreButton(int currentPage) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: () => _loadLeaderboard(page: currentPage + 1),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text('Load More'),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadLeaderboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }
}

class _AnimatedTranslatedCircle extends StatelessWidget {
  final Animation<double> animation;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double width;
  final double height;
  final Color color;

  const _AnimatedTranslatedCircle({
    required this.animation,
    required this.width,
    required this.height,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        child: RepaintBoundary(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animation.value),
            child: child,
          );
        },
      ),
    );
  }
}
