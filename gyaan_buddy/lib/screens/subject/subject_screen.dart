import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/shimmer_image_placeholder.dart';
import '../../blocs/subject/subject_bloc.dart';
import '../../models/module_status.dart';
import '../../models/subject_model.dart';
import '../../models/module_model.dart';
import '../../widgets/background_container.dart';
import '../../widgets/animated_module_progress_bar.dart';
import '../../utils/connected_page_transitions.dart';
import '../module/module_chapter_screen.dart';
import '../../services/vibration_service.dart';

class SubjectScreen extends StatefulWidget {
  final int? initialSubjectIndex;

  const SubjectScreen({
    super.key,
    this.initialSubjectIndex,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen>
    with TickerProviderStateMixin, RouteAware {
  List<Subject> _apiSubjects = [];

  // Track which module card is pressed for border animation (by module ID)
  String? _pressedModuleId;

  // Track previous percentages for progress animations
  final Map<String, double> _previousModulePercentages = {};

  // Prevent repeated module load dispatches while a subject request is in flight.
  final Set<String> _requestedModuleSubjectIds = {};

  // Flag to trigger progress animations after navigation
  bool _shouldAnimateProgress = false;

  // Scroll controller for main scroll
  late ScrollController _scrollController;
  final Map<String, ScrollController> _moduleScrollControllers = {};

  // GlobalKeys for tutorial highlights
  final GlobalKey _firstModuleKey = GlobalKey();

  // Animation controller for DUE badge
  late AnimationController _dueBadgeController;
  late Animation<double> _dueBadgeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _dueBadgeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _dueBadgeScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _dueBadgeController, curve: Curves.easeInOut),
    );

    // Load subjects when screen initializes
    context.read<SubjectBloc>().add(const LoadSubjects());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer to detect navigation events
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }

    // If subjects are already loaded, fetch modules for all subjects
    final state = context.read<SubjectBloc>().state;
    if (state is SubjectsLoaded && _apiSubjects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onSubjectsLoaded();
        }
      });
    } else if (_apiSubjects.isEmpty) {
      final subjectBloc = context.read<SubjectBloc>();
      if (!subjectBloc.hasFetchedSubjects) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            subjectBloc.add(const LoadSubjects());
          }
        });
      }
    }
  }

  @override
  void didPopNext() {
    // Called when a route has been popped off and this route is now visible
    // Refresh modules for all subjects to get the latest progress data
    if (_apiSubjects.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          for (final subject in _apiSubjects) {
            context.read<SubjectBloc>().add(RefreshSubjectModules(subject.id));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    for (final controller in _moduleScrollControllers.values) {
      controller.dispose();
    }
    _dueBadgeController.dispose();
    super.dispose();
  }

  ScrollController _moduleScrollControllerFor(String subjectId) {
    return _moduleScrollControllers.putIfAbsent(
      subjectId,
      () => ScrollController(),
    );
  }

  // Fetch modules for all subjects when subjects are loaded
  void _onSubjectsLoaded() {
    if (_apiSubjects.isEmpty) return;
    final subjectBloc = context.read<SubjectBloc>();
    for (final subject in _apiSubjects) {
      if (subjectBloc.hasCachedModules(subject.id)) {
        _requestedModuleSubjectIds.remove(subject.id);
        subjectBloc.add(LoadSubjectModules(subject.id));
      } else if (_requestedModuleSubjectIds.add(subject.id)) {
        subjectBloc.add(LoadSubjectModules(subject.id));
      }
    }
  }

  // Refresh modules for all subjects
  void _refreshModules() {
    _requestedModuleSubjectIds.clear();
    for (final subject in _apiSubjects) {
      context.read<SubjectBloc>().add(RefreshSubjectModules(subject.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        overlayColor: Colors.white,
        opacity: 0.9,
        child: BlocConsumer<SubjectBloc, SubjectState>(
          listener: (context, state) {
            if (state is SubjectError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SubjectLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SubjectsLoaded) {
              _apiSubjects = state.subjects;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _apiSubjects.isNotEmpty) {
                  _onSubjectsLoaded();
                }
              });
              return _buildSubjectScreen();
            } else if (state is SubjectError) {
              return _buildErrorWidget(state.message);
            } else {
              return _buildSubjectScreen();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSubjectScreen() {
    if (_apiSubjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects available',
          style: TextStyle(fontSize: 18.sp, color: Colors.grey),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshModules(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: kIsWeb ? 16 : 16.h),
              ..._apiSubjects.asMap().entries.expand((entry) {
                final index = entry.key;
                final subject = entry.value;
                return [
                  _buildSubjectSection(subject, isFirst: index == 0),
                  if (index < _apiSubjects.length - 1)
                    SizedBox(height: kIsWeb ? 10 : 10.h),
                ];
              }),
              SizedBox(height: kIsWeb ? 100 : 100.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds one subject block: header row + horizontal modules row
  Widget _buildSubjectSection(Subject subject, {bool isFirst = false}) {
    final subjectColor = _hexToColor(subject.color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header row
        Padding(
          padding: EdgeInsets.only(
            left: kIsWeb ? 200 : 50.w,
            right: kIsWeb ? 20 : 20.w,
            top: isFirst ? (kIsWeb ? 8 : 8.h) : (kIsWeb ? 16 : 12.h),
            bottom: kIsWeb ? 12 : 12.h,
          ),
          child: Row(
            children: [
              // Subject logo
              Container(
                width: kIsWeb ? 100 : 56.w,
                height: kIsWeb ? 100 : 56.h,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: subject.logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: subject.logo,
                        fit: BoxFit.contain,
                        memCacheWidth: kIsWeb ? 180 : 96,
                        memCacheHeight: kIsWeb ? 180 : 96,
                        maxWidthDiskCache: 220,
                        maxHeightDiskCache: 220,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        errorWidget: (context, url, error) => Icon(
                          _getSubjectIcon(subject.name),
                          color: subjectColor,
                          size: kIsWeb ? 70 : 26.sp,
                        ),
                      )
                    : Icon(
                        _getSubjectIcon(subject.name),
                        color: subjectColor,
                        size: kIsWeb ? 70 : 26.sp,
                      ),
              ),
              SizedBox(width: kIsWeb ? 20 : 14.w),
              // Subject name
              Expanded(
                child: Text(
                  subject.name,
                  style: TextStyle(
                    fontSize: kIsWeb ? 22 : 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Horizontal scrollable module row
        _buildHorizontalModulesRow(subject, isFirstSubject: isFirst),
        // Divider between subjects
        Padding(
          padding: EdgeInsets.only(
            left: kIsWeb ? 40 : 50.w,
            right: kIsWeb ? 20 : 20.w,
            top: kIsWeb ? 20 : 20.h,
          ),
          child: Divider(color: Colors.grey.withOpacity(0.2), height: 1),
        ),
      ],
    );
  }

  /// Horizontal scrollable row of module cards for a given subject
  Widget _buildHorizontalModulesRow(
    Subject subject, {
    bool isFirstSubject = false,
  }) {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        final subjectBloc = context.read<SubjectBloc>();
        List<Module>? modules;

        if (state is ModulesLoaded && state.subjectId == subject.id) {
          modules = state.modules;
        } else if (subjectBloc.hasCachedModules(subject.id)) {
          modules = subjectBloc.getCachedModules(subject.id);
        }

        if (modules == null) {
          // Still loading
          return SizedBox(
            height: kIsWeb ? 180 : 180.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (modules.isEmpty) {
          return SizedBox(
            height: kIsWeb ? 60 : 60.h,
            child: Center(
              child: Text(
                'No chapters available',
                style: TextStyle(
                    color: Colors.grey, fontSize: kIsWeb ? 13 : 13.sp),
              ),
            ),
          );
        }

        final sortedModules = modules.reversed.toList();
        final horizontalController = _moduleScrollControllerFor(subject.id);

        return Padding(
          padding: EdgeInsets.only(
            left: kIsWeb ? 200 : 50.w,
            right: kIsWeb ? 365 : 20.w,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              vertical: kIsWeb ? 16 : 16.h,
              horizontal: kIsWeb ? 14 : 14.w,
            ),
            child: SizedBox(
              height: kIsWeb ? 178 : 178.h,
              child: Scrollbar(
                controller: horizontalController,
                thumbVisibility: true,
                trackVisibility: false,
                interactive: true,
                radius: const Radius.circular(20),
                thickness: kIsWeb ? 5 : 4,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: kIsWeb ? 10 : 10.h),
                    child: CustomPaint(
                      painter: _ChapterConnectorPainter(
                        lineY: kIsWeb ? 84.0 : 84.h,
                      ),
                      child: Row(
                        children: sortedModules.asMap().entries.map((entry) {
                          final index = entry.key;
                          final module = entry.value;
                          final isFirstModule = index == 0;
                          final isLast = index == sortedModules.length - 1;
                          return Padding(
                            key: isFirstSubject && isFirstModule
                                ? _firstModuleKey
                                : null,
                            padding: EdgeInsets.only(
                              right: isLast ? 0 : (kIsWeb ? 12.0 : 12.w),
                            ),
                            child: _buildCompactModuleCard(module, subject),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Compact module card for horizontal display
  Widget _buildCompactModuleCard(Module module, Subject subject) {
    final subjectColor = _hexToColor(subject.color);
    final isPressed = _pressedModuleId == module.id;
    final isDisabled = !module.isEnabled;
    final isCompleted = module.userStatus == ModuleStatus.completed;
    final isInProgress = module.userStatus == ModuleStatus.inProgress;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled && !isCompleted) {
          setState(() => _pressedModuleId = module.id);
        }
      },
      onTapUp: (_) async {
        setState(() => _pressedModuleId = null);
        if (isDisabled || isCompleted) return;
        _storeCurrentModulePercentages(
            context.read<SubjectBloc>().getCachedModules(subject.id) ?? []);
        Navigator.of(context)
            .push(
          ConnectedPageTransitions.scaleInward(
            page: ModuleChapterScreen(module: module, subject: subject),
          ),
        )
            .then((_) {
          if (mounted) {
            setState(() => _shouldAnimateProgress = true);
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) setState(() => _shouldAnimateProgress = false);
            });
          }
        });
      },
      onTapCancel: () => setState(() => _pressedModuleId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        width: kIsWeb ? 155 : 170.w,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
            right: BorderSide(color: Colors.grey[300]!, width: 1),
            bottom:
                BorderSide(color: Colors.grey[300]!, width: isPressed ? 1 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isPressed ? 0.05 : 0.1),
              spreadRadius: isPressed ? 0 : 1,
              blurRadius: isPressed ? 4 : 8,
              offset: Offset(0, isPressed ? 1 : 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Module image
                  SizedBox(
                    height: kIsWeb ? 77 : 77.h,
                    width: double.infinity,
                    child: (module.logo != null && module.logo!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: module.logo!,
                            fit: BoxFit.contain,
                            memCacheWidth: kIsWeb ? 160 : 120,
                            memCacheHeight: kIsWeb ? 160 : 120,
                            maxWidthDiskCache: 220,
                            maxHeightDiskCache: 220,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            errorWidget: (context, url, error) => Icon(
                              Icons.menu_book_rounded,
                              color: isDisabled ? Colors.grey : subjectColor,
                              size: kIsWeb ? 36 : 36.sp,
                            ),
                            placeholder: (context, url) =>
                                const ShimmerImagePlaceholder(
                                    width: 60, height: 60, borderRadius: 8),
                          )
                        : Icon(
                            Icons.menu_book_rounded,
                            color: isDisabled ? Colors.grey : subjectColor,
                            size: kIsWeb ? 36 : 36.sp,
                          ),
                  ),
                  SizedBox(height: kIsWeb ? 8 : 8.h),
                  // Module name
                  Expanded(
                    child: Text(
                      module.name,
                      style: TextStyle(
                        fontSize: kIsWeb ? 12 : 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.black54 : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Progress bar
                  if (isInProgress || isCompleted) ...[
                    SizedBox(height: kIsWeb ? 6 : 6.h),
                    AnimatedModuleProgressBar(
                      moduleId: module.id,
                      status: module.userStatus,
                      percentage: module.userPercentage,
                      progressColor: _getProgressBarColor(module.userStatus),
                      previousPercentage: _shouldAnimateProgress
                          ? _previousModulePercentages[module.id]
                          : null,
                      onCompletionAnimationDone: () =>
                          VibrationService().successVibration(),
                    ),
                  ],
                ],
              ),
              // Badge: DUE / OVERDUE / LOCK
              if (isDisabled)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.lock, color: Colors.white, size: 11),
                  ),
                )
              else if (!isInProgress && !isCompleted)
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _dueBadgeScaleAnimation,
                    builder: (context, child) {
                      final isOverdue = module.hasDueDate && module.isOverdue;
                      return Transform.scale(
                        scale: _dueBadgeScaleAnimation.value,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isOverdue ? 6.w : 8.w, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? Colors.red[600]
                                : _hexToColor('12B540'),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOverdue ? 'OVERDUE' : 'DUE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods to get icon and color based on subject name
  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') || name.contains('mathematics')) {
      return Icons.calculate;
    } else if (name.contains('science')) {
      return Icons.science;
    } else if (name.contains('economics')) {
      return Icons.trending_up;
    } else if (name.contains('geography')) {
      return Icons.public;
    } else if (name.contains('history')) {
      return Icons.history;
    } else if (name.contains('english')) {
      return Icons.language;
    } else if (name.contains('physics')) {
      return Icons.science;
    } else if (name.contains('chemistry')) {
      return Icons.science;
    } else if (name.contains('biology')) {
      return Icons.science;
    } else {
      return Icons.book;
    }
  }

  // Helper function to convert hex string to Color
  Color _hexToColor(String? hexString, {Color fallback = Colors.blue}) {
    if (hexString == null || hexString.isEmpty) {
      return fallback;
    }
    try {
      // Remove # if present and add it if not
      String hex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;
      // Add # prefix for Color parsing
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallback;
    }
  }

  Color _getProgressBarColor(ModuleStatus status) {
    return _hexToColor("31C85D");
  }

  /// Store current module percentages before navigation
  /// This allows animating the progress bar when returning to this screen
  void _storeCurrentModulePercentages(List<Module> modules) {
    for (final module in modules) {
      _previousModulePercentages[module.id] = module.userPercentage;
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading subjects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<SubjectBloc>().add(const LoadSubjects());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Manual switch to next subject
}

class _ChapterConnectorPainter extends CustomPainter {
  final double lineY;

  _ChapterConnectorPainter({required this.lineY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, lineY - 1, size.width, 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChapterConnectorPainter oldDelegate) =>
      oldDelegate.lineY != lineY;
}
