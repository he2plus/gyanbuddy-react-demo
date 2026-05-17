import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/module_chapter/module_chapter_bloc.dart';
import '../../models/user_model.dart';
import '../../widgets/dashboard/ranked_item.dart';
import '../../utils/web_size_utils.dart';
import '../../widgets/smooth_scroll_wrapper.dart';

class ModuleLeaderboardScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const ModuleLeaderboardScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<ModuleLeaderboardScreen> createState() =>
      _ModuleLeaderboardScreenState();
}

class _ModuleLeaderboardScreenState extends State<ModuleLeaderboardScreen>
    with TickerProviderStateMixin {
  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Base color for the background
  final Color _baseColor = const Color(0xFF4A90E2); // Blue color

  // Button press state
  bool _isContinueButtonPressed = false;

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
    _initAnimations();

    // Load leaderboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  void _initAnimations() {
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
      duration: const Duration(seconds: 5),
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
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  void _loadLeaderboard({int? page}) {
    context.read<UserBloc>().add(LoadLeaderboard(
          page: page ?? 1,
          limit: 50,
        ));
  }

  void _refreshLeaderboard() {
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final topGradientColors = _getGradientColors(_baseColor);
    final bottomGradientColors = _getBottomGradientColors(_baseColor);

    return Scaffold(
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
              height: kIsWeb ? 200 : 0.25.sh,
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
              height: kIsWeb ? 250 : 0.33.sh,
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
                      top: -100,
                      right: -100,
                      width: WebSize.width(context, 300),
                      height: WebSize.width(context, 300),
                      color: _baseColor.withOpacity(0.15),
                    ),
                    _AnimatedTranslatedCircle(
                      animation: _circle2Animation,
                      top: 240,
                      left: 40,
                      width: WebSize.width(context, 120),
                      height: WebSize.width(context, 120),
                      color: _baseColor.withOpacity(0.25),
                    ),
                    _AnimatedTranslatedCircle(
                      animation: _circle3Animation,
                      bottom: 240,
                      right: 20,
                      width: WebSize.width(context, 50),
                      height: WebSize.width(context, 50),
                      color: _baseColor.withOpacity(0.25),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          RepaintBoundary(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildBody(),
                  ),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 20.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(kIsWeb ? 8 : 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: kIsWeb ? 24 : 24.sp,
              ),
            ),
          ),
          SizedBox(width: kIsWeb ? 16 : 16.w),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: kIsWeb ? 24 : 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.moduleName,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 14.sp,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _refreshLeaderboard,
            child: Container(
              padding: EdgeInsets.all(kIsWeb ? 8 : 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.black87,
                size: kIsWeb ? 24 : 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
          return _buildLeaderboardList(state.users);
        } else if (state is LeaderboardError) {
          return _buildErrorState(state.message);
        } else {
          // If not in leaderboard state, trigger loading
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

  Widget _buildLeaderboardList(List<User> users) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return SmoothScrollOverlay(
      showTopFade: true,
      showBottomFade: true,
      fadeHeight: kIsWeb ? 40 : 40.h,
      fadeColor: Colors.white,
      child: RefreshIndicator(
        onRefresh: () async {
          _refreshLeaderboard();
        },
        child: ListView.builder(
          padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
          physics: const BouncingScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final rank = index + 1;
            return RankedItem(user: user, rank: rank);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: kIsWeb ? 80 : 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: kIsWeb ? 16 : 16.h),
          Text(
            'No Rankings Yet',
            style: TextStyle(
              fontSize: kIsWeb ? 24 : 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          Text(
            'Be the first to complete this chapter!',
            style: TextStyle(
              fontSize: kIsWeb ? 16 : 16.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: kIsWeb ? 32 : 32.h),
          ElevatedButton.icon(
            onPressed: _refreshLeaderboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _baseColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 24 : 24.w,
                vertical: kIsWeb ? 12 : 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kIsWeb ? 24 : 24.r),
              ),
            ),
          ),
        ],
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
            size: kIsWeb ? 80 : 80.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: kIsWeb ? 16 : 16.h),
          Text(
            'Error Loading Leaderboard',
            style: TextStyle(
              fontSize: kIsWeb ? 24 : 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 32 : 32.w),
            child: Text(
              message,
              style: TextStyle(
                fontSize: kIsWeb ? 16 : 16.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: kIsWeb ? 32 : 32.h),
          ElevatedButton.icon(
            onPressed: _refreshLeaderboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _baseColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 24 : 24.w,
                vertical: kIsWeb ? 12 : 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kIsWeb ? 24 : 24.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 20.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isContinueButtonPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isContinueButtonPressed = false;
          });
          if (context.mounted) {
            context
                .read<ModuleChapterBloc>()
                .add(RefreshModuleChapters(widget.moduleId));
          }
          Navigator.of(context).pop();
        },
        onTapCancel: () {
          setState(() {
            _isContinueButtonPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          height: kIsWeb ? 56 : 56.h,
          decoration: BoxDecoration(
            color: _baseColor,
            borderRadius: BorderRadius.circular(kIsWeb ? 28 : 28.r),
            border: Border(
              bottom: BorderSide(
                color: Color.lerp(_baseColor, Colors.black, 0.3)!,
                width: _isContinueButtonPressed ? 1 : 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: _baseColor
                    .withOpacity(_isContinueButtonPressed ? 0.2 : 0.3),
                blurRadius: _isContinueButtonPressed ? 6 : 12,
                offset: Offset(0, _isContinueButtonPressed ? 2 : 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: kIsWeb ? 18 : 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
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
