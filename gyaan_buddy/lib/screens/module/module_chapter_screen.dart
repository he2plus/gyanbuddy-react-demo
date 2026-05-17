import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/module_chapter/module_chapter_bloc.dart';
import '../../blocs/module_questions/module_questions_bloc.dart';
import '../../blocs/subject/subject_bloc.dart';
import '../../models/module_model.dart';
import '../../models/subject_model.dart';
import '../../models/module_chapter_model.dart';
import '../../models/module_status.dart';
import '../../widgets/animated_screen_layout.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../widgets/smooth_scroll_wrapper.dart';
import 'chapter_theory_screen.dart';

class ModuleChapterScreen extends StatefulWidget {
  final Subject subject;
  final Module module;

  const ModuleChapterScreen({
    super.key,
    required this.subject,
    required this.module,
  });

  @override
  State<ModuleChapterScreen> createState() => _ModuleChapterScreenState();
}

// Route observer for detecting navigation events
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class _ModuleChapterScreenState extends State<ModuleChapterScreen>
    with TickerProviderStateMixin, RouteAware {
  bool _isRefreshing = false;
  ModuleChapter? currentChapter;
  ScrollController scrollController = ScrollController();
  bool _isStartButtonPressed = false;
  bool _hasScrolledToInProgress = false;
  bool _hasShownCompletionSnackbar = false; // Flag to prevent showing snackbar multiple times
  final GlobalKey _inProgressChapterKey = GlobalKey();
  
  // Keys for tracking chapter positions for dotted line connections
  final List<GlobalKey> _chapterKeys = [];
  // Flag to track if we've triggered the dotted line redraw
  bool _hasTriggeredDottedLineRedraw = false;

  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

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

    // Play loading contents sound when screen opens
    // SoundService().playLoadingContents();

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

    // Load module chapters when screen initializes
    context.read<ModuleChapterBloc>().add(LoadModuleChapters(widget.module.id));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer to detect navigation events
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when a route has been popped off and this route is now visible
    // Reset scroll flag to allow auto-scroll when returning to this screen
    setState(() {
      _hasScrolledToInProgress = false;
      _hasTriggeredDottedLineRedraw = false;
      _hasShownCompletionSnackbar = false; // Reset to allow showing snackbar again if needed
    });
    // Refresh chapters to get latest data
    context.read<ModuleChapterBloc>().add(LoadModuleChapters(widget.module.id));
  }

  Future<void> _refreshChapters() async {
    setState(() {
      _isRefreshing = true;
      _hasScrolledToInProgress = false; // Reset scroll flag on refresh
      _hasTriggeredDottedLineRedraw = false; // Reset dotted line flag on refresh
    });
    context
        .read<ModuleChapterBloc>()
        .add(RefreshModuleChapters(widget.module.id));
  }

  /// Scrolls to the in-progress chapter with a smooth animation
  void _scrollToInProgressChapter() {
    if (_hasScrolledToInProgress || !mounted) return;
    
    final keyContext = _inProgressChapterKey.currentContext;
    if (keyContext != null) {
      _hasScrolledToInProgress = true;
      
      // Use Scrollable.ensureVisible to scroll to the in-progress chapter
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Position it at 30% from the top of the viewport
      );
    } else {
      // Context not ready yet, retry after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasScrolledToInProgress) {
          _scrollToInProgressChapter();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ModuleChapterBloc, ModuleChapterState>(
      listener: (context, state) {
        // When chapters are loaded, update module status in SubjectBloc cache
        if (state is ModuleChaptersLoaded) {
          final moduleChapterBloc = context.read<ModuleChapterBloc>();
          final moduleStatusData =
              moduleChapterBloc.calculateModuleStatus(widget.module.id);

          print(
              '🔵 ModuleChapterScreen: Calculated module status: ${moduleStatusData['status']}, percentage: ${moduleStatusData['percentage']}');

          // Update module status in SubjectBloc cache so subject screen shows updated progress
          context.read<SubjectBloc>().add(UpdateModuleStatus(
                subjectId: widget.subject.id,
                moduleId: widget.module.id,
                newStatus: moduleStatusData['status'] as ModuleStatus,
                newPercentage: moduleStatusData['percentage'] as double,
              ));
        }
      },
      child: Scaffold(
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
                    colors:
                        _getGradientColors(_hexToColor(widget.subject.color)),
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
                    colors: _getBottomGradientColors(
                        _hexToColor(widget.subject.color)),
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Circular shapes overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // Large circle in upper left
                    AnimatedBuilder(
                      animation: _circle1Animation,
                      builder: (context, child) {
                        return Positioned(
                          top:
                              (kIsWeb ? 80.0 : 100.h) + _circle1Animation.value,
                          left: (kIsWeb ? -40.0 : -50.w) +
                              _circle1Animation.value * 0.5,
                          child: Container(
                            width: kIsWeb ? 150 : 200.w,
                            height: kIsWeb ? 150 : 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hexToColor(widget.subject.color)
                                  .withOpacity(0.15),
                            ),
                          ),
                        );
                      },
                    ),
                    // Medium circle in upper right
                    AnimatedBuilder(
                      animation: _circle2Animation,
                      builder: (context, child) {
                        return Positioned(
                          top: (kIsWeb ? 40.0 : 50.h) + _circle2Animation.value,
                          right: (kIsWeb ? -20.0 : -30.w) -
                              _circle2Animation.value * 0.5,
                          child: Container(
                            width: kIsWeb ? 120 : 150.w,
                            height: kIsWeb ? 120 : 150.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hexToColor(widget.subject.color)
                                  .withOpacity(0.2),
                            ),
                          ),
                        );
                      },
                    ),
                    // Small circle in lower right
                    AnimatedBuilder(
                      animation: _circle3Animation,
                      builder: (context, child) {
                        return Positioned(
                          bottom: (kIsWeb ? 180.0 : 240.h) -
                              _circle3Animation.value,
                          right: kIsWeb ? 20 : 20.w,
                          child: Container(
                            width: kIsWeb ? 40 : 50.w,
                            height: kIsWeb ? 40 : 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hexToColor(widget.subject.color)
                                  .withOpacity(0.25),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Content
            AnimatedScreenLayout(
              appBar: Container(
                margin: EdgeInsets.only(
                  top: kIsWeb ? 20 : 70.h,
                  left: kIsWeb ? 20 : 20.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Arrow
                    GestureDetector(
                      onTap: () {
                        // Update module status immediately from current chapters before popping
                        final moduleChapterBloc = context.read<ModuleChapterBloc>();
                        if (moduleChapterBloc.hasCachedChapters(widget.module.id)) {
                          final moduleStatusData = moduleChapterBloc.calculateModuleStatus(widget.module.id);
                          context.read<SubjectBloc>().add(UpdateModuleStatus(
                            subjectId: widget.subject.id,
                            moduleId: widget.module.id,
                            newStatus: moduleStatusData['status'] as ModuleStatus,
                            newPercentage: moduleStatusData['percentage'] as double,
                          ));
                        }
                        
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: kIsWeb ? 22 : 24,
                      ),
                    ),
                  ],
                ),
              ),
              body: RefreshIndicator(
                onRefresh: _refreshChapters,
                child: BlocBuilder<ModuleChapterBloc, ModuleChapterState>(
                  builder: (context, state) {
                    return _buildContent(state);
                  },
                ),
              ),
              animationDuration: const Duration(milliseconds: 600),
              animationCurve: Curves.easeOutCubic,
              enableStaggeredAnimation: true,
              staggerDelay: const Duration(milliseconds: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ModuleChapterState state) {
    if (state is ModuleChapterLoading) {
      return _buildLoadingContent();
    }

    if (state is ModuleChapterError) {
      return _buildErrorContent(state.message);
    }

    if (state is ModuleChaptersLoaded) {
      print("here state is this ${state.chapters}");
      currentChapter = state.chapters.where((e) => e.isInProgress).firstOrNull;
      print("here current chapter is this ${currentChapter?.theory}");
      
      // Update module status when all chapters are completed
      if (currentChapter == null && !_hasShownCompletionSnackbar) {
        _hasShownCompletionSnackbar = true; // Mark as processed to prevent duplicates
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!mounted) return;
          
          // Calculate and update module status
          final moduleChapterBloc = context.read<ModuleChapterBloc>();
          final moduleStatusData = moduleChapterBloc.calculateModuleStatus(widget.module.id);
          
          // Update module status in SubjectBloc cache
          context.read<SubjectBloc>().add(UpdateModuleStatus(
            subjectId: widget.subject.id,
            moduleId: widget.module.id,
            newStatus: moduleStatusData['status'] as ModuleStatus,
            newPercentage: moduleStatusData['percentage'] as double,
          ));
        });
      }

      return _buildLoadedContent(state.chapters);
    }

    return Container();
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Chapters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              // await SoundService().playButtonClick();
              await VibrationService().successVibration();
              context
                  .read<ModuleChapterBloc>()
                  .add(LoadModuleChapters(widget.module.id));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(List<ModuleChapter> chapters) {
    if (chapters.isEmpty) {
      return _buildNoChaptersState();
    }

    // Scroll to in-progress chapter after the widget is built
    if (!_hasScrolledToInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a small delay to ensure layout is complete after navigation
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _scrollToInProgressChapter();
          }
        });
      });
    }

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1 - Left side (fixed, non-scrollable): image, heading, description, modules count
        Expanded(
          flex: 6,
          child: Padding(
            padding: EdgeInsets.all(kIsWeb ? 20 : 20.0),
            child: Column(

              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 20
                  ,),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kIsWeb ? 20 : 24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(kIsWeb ? 24 : 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Cubes Image
                      _buildTopCubesImage(),

                      SizedBox(height: kIsWeb ? 40 : 52.h),

                      // Module Name and Description
                      _buildModuleInfo(),

                      SizedBox(height: kIsWeb ? 24 : 33.h),

                      Text(
                        "${chapters.length} Chapters",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: kIsWeb ? 14 : 16.sp,
                        ),
                      ),
                      Builder(builder: (context) {
                        final totalQuestions = widget.module.questionCount > 0
                            ? widget.module.questionCount
                            : chapters.fold(0, (sum, ch) => sum + ch.questionCount);
                        if (totalQuestions == 0) return const SizedBox();
                        return Padding(
                          padding: EdgeInsets.only(top: kIsWeb ? 4 : 4.h),
                          child: Text(
                            "$totalQuestions Assignments",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                              fontSize: kIsWeb ? 13 : 14.sp,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Section 2 - Right side wrapped in white card
        Expanded(
          flex: 7,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? 20 : 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kIsWeb ? 20 : 24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SmoothScrollOverlay(
                        showTopFade: false,
                        showBottomFade: false,
                        fadeHeight: kIsWeb ? 50 : 50.h,
                        fadeColor: Colors.white,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: kIsWeb ? 90 : 32.0,
                            vertical: kIsWeb ? 32 : 32.0,
                          ),
                          child: Column(
                            children: [
                              // Chapter Container
                              _buildChapterContainer(),

                              SizedBox(height: kIsWeb ? 20 : 24),

                              // Zig-zag chapter layout
                              _buildZigZagChapterLayout(chapters),

                              SizedBox(height: kIsWeb ? 30 : 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -MediaQuery.of(context).size.height * 0.05),
                      child: _buildStartContainer(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
        ),
      ),
      ),
    );
  }

  Widget _buildNoChaptersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Chapters Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No chapters are available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(ModuleChapter chapter, {bool isLastChapter = false}) {
    String image = 'assets/images/stand_boy.png';
    bool? isBoyStanding = true;

    print("change here");
    if (chapter.isImportant && chapter.isInProgress) {
      image = 'assets/images/stand_boy_important.png';
      print(" boy 1");
      isBoyStanding = true;
    } else if (chapter.isImportant && chapter.isNotStarted) {
      image = 'assets/images/disabled_important_stand.png';
      print(" boy 2");
      isBoyStanding = null;
    } else if (chapter.isImportant && chapter.isCompleted) {
      image = 'assets/images/important_platform.png';
      print(" boy 3");
      isBoyStanding = false;
    } else if (chapter.isCompleted) {
      // Use last_platform.png for last chapter when not in progress
      if (isLastChapter && !chapter.isInProgress) {
        image = 'assets/images/last_platform.png';
      } else {
        image = 'assets/images/platform.png';
      }
      print(" boy 4");
      isBoyStanding = false;
    } else if (chapter.isNotStarted) {
      // Use last_platform.png for last chapter when not in progress
      if (isLastChapter && !chapter.isInProgress) {
        image = 'assets/images/last_platform.png';
      } else {
        image = 'assets/images/disabled_platform.png';
      }
      print(" boy 5");
      isBoyStanding = false;
    }

    // When isBoyStanding is true, show Stack with boy on platform
    if (isBoyStanding == true) {
      final platformHeight = kIsWeb ? 45.0 : 57.h;
      final platformWidth = kIsWeb ? 130.0 : chapter.isImportant? 173.w: 120.w;
      final boyHeight = kIsWeb ? 95.0 : 120.h;
      // Boy's feet should be at top of platform with overlap adjustment
      final feetOverlap = kIsWeb ? 5.0 : chapter.isImportant?8.h:10.h;
      final boyBottomOffset = platformHeight - feetOverlap - (kIsWeb ? 25.0 : chapter.isImportant? 30.h: 10.h) + 16;
      // Total stack height = boy height + position where boy's bottom starts
      final stackHeight = boyHeight + boyBottomOffset;
      final stackWidth = platformWidth;
      final platformImage = chapter.isImportant
          ? 'assets/images/important_platform.png'
          : 'assets/images/platform.png';

      return SizedBox(
        height: stackHeight,
        width: stackWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Platform image at the bottom center
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                platformImage,
                fit: BoxFit.contain,
                height: platformHeight,
                width: platformWidth,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
            // Boy image slightly left of center on platform
            Positioned(
              bottom: boyBottomOffset,
              left: 0,
              right: kIsWeb ? 20 : chapter.isImportant? 30.w: 10.w,
              child: Center(
                child: Image.asset(
                  'assets/images/boy.png',
                  fit: BoxFit.contain,
                  height: boyHeight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: kIsWeb ? 50 : 60.w,
                      height: kIsWeb ? 50 : 60.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF87CEEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        size: kIsWeb ? 24 : 30,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Check if this is the last platform image to make it larger
    final isLastPlatformImage = image == 'assets/images/last_platform.png';
    
    final imageHeight = (isBoyStanding == null ||  !isBoyStanding)?
      (isLastPlatformImage ? (kIsWeb ? 120.0 : 90.h) : (kIsWeb ? 80.0 : 60.h))
      : (kIsWeb ? 45.0 : 57.h);
    final imageWidth = (isBoyStanding == null ||  !isBoyStanding)?
      (isLastPlatformImage ? (kIsWeb ? 240.0 : 180.w) : (kIsWeb ? 160.0 : 140.w))
      : (kIsWeb ? 100.0 : 120.w);

    return Container(
      height: imageHeight,
      width: imageWidth,
      child: OverflowBox(
        maxHeight: isLastPlatformImage ? (kIsWeb ? 234.0 : 175.5.h) : imageHeight,
        maxWidth: isLastPlatformImage ? (kIsWeb ? 468.0 : 351.w) : imageWidth,
        child: Image.asset(
        image,
        height: isLastPlatformImage ? (kIsWeb ? 234.0 : 175.5.h) : null,
        width: isLastPlatformImage ? (kIsWeb ? 468.0 : 351.w) : null,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: kIsWeb ? 50 : 60.w,
            height: kIsWeb ? 50 : 60.h,
            decoration: BoxDecoration(
              color: const Color(0xFF87CEEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person,
              size: kIsWeb ? 24 : 30,
              color: Colors.white,
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildZigZagChapterLayout(List<ModuleChapter> chapters) {
    // Initialize keys for each chapter if needed
    while (_chapterKeys.length < chapters.length) {
      _chapterKeys.add(GlobalKey());
    }
    
    // Schedule dotted line redraw after layout (only once per chapter load)
    if (!_hasTriggeredDottedLineRedraw) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hasTriggeredDottedLineRedraw = true;
          setState(() {}); // Trigger rebuild to update dotted lines
        }
      });
    }
    
    // Build chapter cards Column first (determines the size)
    final chapterColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        chapters.length,
        (index) {
          // Calculate which position this chapter should be in (1, 2, or 3)
          // Pattern: center (2), right (3), left (1), center (2), right (3), left (1), ...
          int position = ((index % 3) == 0) ? 2 : (((index % 3) == 1) ? 3 : 1);
          
          final chapter = chapters[index];
          final isInProgress = chapter.isInProgress;

          final isLastChapter = index == chapters.length - 1;
          
          return Padding(
            key: isInProgress ? _inProgressChapterKey : null,
            padding: EdgeInsets.only(bottom: kIsWeb ? 32 : 40.h),
            child: Row(
              children: [
                // Add empty space before the card based on position
                if (position == 2) const Expanded(child: SizedBox()),
                if (position == 3)
                  const Expanded(flex: 2, child: SizedBox()),
                // The chapter card with key for position tracking
                Container(
                  key: _chapterKeys[index],
                  child: isInProgress
                      ? GestureDetector(
                          onTap: () {
                            // Navigate to theory screen with connected transition
                            Navigator.push(
                              context,
                              ConnectedPageTransitions.depthTransition(
                                page: ChapterTheoryScreen(
                                  subject: widget.subject,
                                  module: widget.module,
                                  chapter: chapter,
                                ),
                              ),
                            );
                          },
                          child: _buildChapterCard(chapter, isLastChapter: isLastChapter),
                        )
                      : _buildChapterCard(chapter, isLastChapter: isLastChapter),
                ),

                // Add empty space after the card based on position
                if (position == 1)
                  const Expanded(flex: 2, child: SizedBox()),
                if (position == 2) const Expanded(child: SizedBox()),
              ],
            ),
          );
        },
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dotted lines connecting chapters (drawn first so they appear behind cards)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ChapterConnectionPainter(
                chapterKeys: _chapterKeys.take(chapters.length).toList(),
                chapters: chapters,
              ),
            ),
          ),
        ),
        // Chapter cards (on top of dotted lines)
        chapterColumn,
      ],
    );
  }

  Widget _buildTopCubesImage() {
    final logoUrl = widget.module.logo;
    final hasValidLogo = logoUrl != null && logoUrl.isNotEmpty;
    
    return SizedBox(
      height: kIsWeb ? 90 : 118.h,
      width: kIsWeb ? 100 : 131.w,
      child: Center(
        child: hasValidLogo
            ? Image.network(
                logoUrl,
                height: kIsWeb ? 80 : 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildLogoPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLogoLoading();
                },
              )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      height: kIsWeb ? 80 : 100,
      width: kIsWeb ? 80 : 100,
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        size: kIsWeb ? 32 : 40.h,
        color: const Color(0xFF4A90E2),
      ),
    );
  }

  Widget _buildLogoLoading() {
    return Container(
      height: kIsWeb ? 80 : 100,
      width: kIsWeb ? 80 : 100,
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
        ),
      ),
    );
  }

  Widget _buildModuleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Title
        Text(
          widget.module.name,
          style: TextStyle(
            fontSize: kIsWeb ? 22 : 28.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.start,
        ),

        SizedBox(height: kIsWeb ? 8 : 10.h),

        // Course Description
        Text(
          widget.module.description ?? "",
          style: TextStyle(
            fontSize: kIsWeb ? 14 : 16.sp,
            color: Colors.grey,
          ),
          textAlign: TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildChapterContainer() {
    if (currentChapter == null) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10,),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 20 : 16.w,
            vertical: kIsWeb ? 8 : 6.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kIsWeb ? 24 : 28.r),
            border: Border.all(
              color: _hexToColor(widget.subject.color),
              width: 1.5,
            ),
          ),
          child: Text(
            'MODULE ${currentChapter!.order}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 16.sp,
              color: _hexToColor(widget.subject.color),
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(height: kIsWeb ? 15 : 10.h),
        Text(
          currentChapter!.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: kIsWeb ? 25 : 22.sp,
            color: Colors.black,
          ),
        ),
        SizedBox(height: kIsWeb ? 30 : 10.h),

      ],
    );
  }

  Widget _buildStartContainer() {
    if (currentChapter == null) {
      return const SizedBox();
    }
    return Center(
      child: Container(
        width: kIsWeb ? 380 : 367.w,
        height: kIsWeb ? 130 : 150.h,
        padding: EdgeInsets.all(kIsWeb ? 15 : 20.w),
        margin: EdgeInsets.only(
          bottom: kIsWeb ? 10 : 10.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kIsWeb ? 24 : 30.r),
          border: Border.all(
            color: _hexToColor("365DEA").withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hexToColor("365DEA").withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Flexible(
              child: Text(
                "Let's Start With ${currentChapter!.name}",
                style: TextStyle(
                  fontSize: kIsWeb ? 17 : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: kIsWeb ? 8 : 10.h),

            // Start Button
            GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _isStartButtonPressed = true;
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isStartButtonPressed = false;
                });
                // Navigate to theory screen first with connected transition
                Navigator.push(
                  context,
                  ConnectedPageTransitions.depthTransition(
                    page: ChapterTheoryScreen(
                      subject: widget.subject,
                      module: widget.module,
                      chapter: currentChapter!,
                    ),
                  ),
                );
              },
              onTapCancel: () {
                setState(() {
                  _isStartButtonPressed = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                width: kIsWeb ? 280 : 259.w,
                height: kIsWeb ? 52 : 52.h,
                decoration: BoxDecoration(
                  color: _hexToColor("365DEA"),
                  borderRadius: BorderRadius.circular(kIsWeb ? 20 : 28.r),
                  border: Border(
                    bottom: BorderSide(
                      width: _isStartButtonPressed ? 1 : 4,
                      color: _hexToColor("2A4BC0"),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hexToColor("365DEA")
                          .withOpacity(_isStartButtonPressed ? 0.2 : 0.4),
                      blurRadius: _isStartButtonPressed ? 4 : 8,
                      offset: Offset(0, _isStartButtonPressed ? 1 : 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: kIsWeb ? 22 : 22.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') || name.contains('mathematics')) {
      return Colors.blue;
    } else if (name.contains('science')) {
      return Colors.purple;
    } else if (name.contains('economics')) {
      return Colors.orange;
    } else if (name.contains('history')) {
      return Colors.brown;
    } else if (name.contains('english')) {
      return Colors.indigo;
    } else if (name.contains('geography')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
}

class _DottedLinePainter extends CustomPainter {
  final int itemCount;
  final double itemHeight;

  _DottedLinePainter({
    required this.itemCount,
    required this.itemHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 1) return;

    final paint = Paint()
      ..color = const Color(0xFF365DEA).withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Calculate positions for each card
    final List<Offset> points = [];
    final screenWidth = size.width;

    for (int index = 0; index < itemCount; index++) {
      // Calculate which position this chapter should be in (1, 2, or 3)
      // Start from center (position 2), then right (3), then left (1)
      int position = ((index + 1) % 3) + 1;

      double x;
      // Calculate x position based on the zig-zag pattern
      // Each card takes 1/3 of the screen width (Expanded widget)
      // Position 2 (center): middle third
      // Position 3 (right): right third
      // Position 1 (left): left third
      if (position == 2) {
        // Center position - center of middle third
        x = screenWidth / 2;
      } else if (position == 3) {
        // Right position - center of right third
        x = screenWidth * 5 / 6;
      } else {
        // Left position (position == 1) - center of left third
        x = screenWidth / 6;
      }

      // Calculate y position (center of each card)
      double y = (index * itemHeight) + (itemHeight / 2);

      points.add(Offset(x, y));
    }

    // Draw dotted lines connecting consecutive points (1st to 2nd, 2nd to 3rd, etc.)
    for (int i = 0; i < points.length - 1; i++) {
      _drawCurvedDottedLine(canvas, points[i], points[i + 1], paint);
    }
  }

  void _drawCurvedDottedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    // Calculate control point for a smooth curve
    // The control point is positioned at the midpoint vertically, but offset horizontally
    // to create a curved effect
    final midY = (start.dy + end.dy) / 2;
    final controlPoint = Offset(
      (start.dx + end.dx) / 2,
      midY -
          (end.dy - start.dy).abs() *
              0.3, // Curve upward/downward based on direction
    );

    // Create a quadratic bezier curve path
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    // Draw dotted line along the curve
    final dashWidth = 5;
    final dashSpace = 5;
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter that draws dotted lines connecting chapters using their actual positions
class _ChapterConnectionPainter extends CustomPainter {
  final List<GlobalKey> chapterKeys;
  final List<ModuleChapter> chapters;

  _ChapterConnectionPainter({
    required this.chapterKeys,
    required this.chapters,
  });

  /// Check if a chapter has a boy standing on it (isInProgress)
  bool _hasBoyStanding(ModuleChapter chapter) {
    return chapter.isInProgress;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (chapterKeys.length <= 1) return;

    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Find the Stack's global position by getting the CustomPaint's ancestor
    // We need to find a common reference point
    Offset? stackGlobalPos;
    
    // Get first valid render box to find the Stack's position
    for (final key in chapterKeys) {
      final context = key.currentContext;
      if (context != null) {
        // Walk up to find the Stack (or just use the first card's parent position)
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          // Get the parent chain to find Stack position
          RenderObject? current = renderBox.parent;
          while (current != null) {
            if (current is RenderBox && current.hasSize) {
              stackGlobalPos = current.localToGlobal(Offset.zero);
              break;
            }
            current = current.parent;
          }
          break;
        }
      }
    }
    
    if (stackGlobalPos == null) return;

    // Collect card positions relative to Stack with platform-aware offsets
    final List<Map<String, dynamic>?> cardData = [];
    
    // Platform height for adjustments (matching _buildChapterCard values)
    const double platformHeightWeb = 45.0;
    const double platformHeightMobile = 57.0;
    const double boyHeightWeb = 95.0;
    const double boyHeightMobile = 120.0;
    
    // Check if we're on web (simple check based on platform)
    final isWeb = kIsWeb;
    final platformHeight = isWeb ? platformHeightWeb : platformHeightMobile;
    final boyHeight = isWeb ? boyHeightWeb : boyHeightMobile;
    
    for (int i = 0; i < chapterKeys.length; i++) {
      final key = chapterKeys[i];
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      final chapter = chapters[i];
      
      if (renderBox != null && renderBox.hasSize) {
        final cardGlobalPos = renderBox.localToGlobal(Offset.zero);
        final cardSize = renderBox.size;
        
        // Position relative to Stack
        final relX = cardGlobalPos.dx - stackGlobalPos.dx;
        final relY = cardGlobalPos.dy - stackGlobalPos.dy;
        
        // Offset from actual bottom (20px above)
        const bottomOffset = 20.0;
        
        // For cards with boy standing, adjust connection points to platform level
        double topY = relY;
        double bottomY = relY + cardSize.height - bottomOffset;
        
        if (_hasBoyStanding(chapter)) {
          // Boy is standing on this platform
          // Top connection point should be at boy's head level (same as relY)
          // Bottom connection point should be at platform bottom - 20px
          bottomY = relY + cardSize.height - bottomOffset;
          topY = relY + (cardSize.height - platformHeight);
        }
        
        cardData.add({
          'topCenter': Offset(relX + cardSize.width / 2, topY),
          'bottomCenter': Offset(relX + cardSize.width / 2, bottomY),
          'platformTop': Offset(relX + cardSize.width / 2, relY + cardSize.height - platformHeight),
          'center': Offset(relX + cardSize.width / 2, relY + cardSize.height / 2),
          'hasBoy': _hasBoyStanding(chapter),
        });
      } else {
        cardData.add(null);
      }
    }

    // Draw curved dotted lines from bottom center of each card to bottom center of next
    for (int i = 0; i < cardData.length - 1; i++) {
      final current = cardData[i];
      final next = cardData[i + 1];
      
      if (current != null && next != null) {
        // Start from bottom center of current card
        Offset startPoint = current['bottomCenter'] as Offset;
        
        // End at bottom center of next card
        Offset endPoint = next['bottomCenter'] as Offset;
        
        _drawCurvedDottedLine(
          canvas, 
          startPoint, 
          endPoint, 
          paint,
        );
      }
    }
  }

  void _drawCurvedDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Create a curve that exits start going down, then approaches end straight from top
    
    final verticalDist = end.dy - start.dy;
    
    // First control point - directly below start, controls how long the line goes straight down
    final cp1 = Offset(
      start.dx,
      start.dy + verticalDist * 0.7,
    );
    
    // Second control point - directly above end, ensures straight vertical approach from top
    final cp2 = Offset(
      end.dx,
      end.dy - verticalDist * 0.7,
    );

    // Create smooth S-curve using cubic bezier
    // Line goes: down from start -> curves horizontally -> straight down into end
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    // Draw as dotted line
    const dashLen = 5.0;
    const gapLen = 5.0;
    
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final segment = metric.extractPath(
          dist, 
          (dist + dashLen).clamp(0, metric.length),
        );
        canvas.drawPath(segment, paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChapterConnectionPainter oldDelegate) => true;
}
