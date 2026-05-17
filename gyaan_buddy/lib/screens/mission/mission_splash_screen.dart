import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/index.dart';
import 'package:gyanbuddy/screens/mission/mission_detail_screen.dart';
import '../../models/mission_model.dart';
import '../../models/next_content_model.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../services/mission_api_service.dart';

class MissionSplashScreen extends StatefulWidget {
  final Mission mission;
  final NextContent? content;

  const MissionSplashScreen({
    super.key,
    required this.mission,
    this.content,
  });

  @override
  State<MissionSplashScreen> createState() => _MissionSplashScreenState();
}

class _MissionSplashScreenState extends State<MissionSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final MissionApiService _missionApiService = MissionApiService();
  List<MissionQuestionData> _questions = [];

  @override
  void initState() {
    super.initState();

    print('🔵 MissionSplashScreen: initState called - Instance: ${hashCode}');
    print('🔵 MissionSplashScreen: Mission: ${widget.mission.id}');

    _initializeAnimations();
    _loadContent();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Rotation animation (continuous)
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start all animations
    _fadeController.forward();
    _scaleController.forward();
    _rotationController.repeat(); // Continuous rotation
  }

  void _loadContent() async {
    print('🔵 SplashScreen: _loadContent called');

    try {
      print('🔵 SplashScreen: Fetching mission questions...');

      // Call the questions API to get random 6 questions
      final response =
          await _missionApiService.getMissionQuestions(widget.mission.id);

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        print('🔵 SplashScreen: Loaded ${response.data!.length} questions');
        _questions = response.data!;

        if (mounted) {
          _navigateToMissionQuiz();
        }
      } else {
        print(
            '🔵 SplashScreen: No questions available or error: ${response.message}');
        if (mounted) {
          _handleNoQuestions(response.message);
        }
      }
    } catch (e) {
      print('Error loading content: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _navigateToMissionQuiz() async {
    print(
        '🔵 MissionSplashScreen: Navigating to mission quiz with ${_questions.length} questions');
    // Use push to capture the result, then forward it back to MissionSubjectScreen
    final completedMissionId = await Navigator.of(context).push<String>(
      ConnectedPageTransitions.connectedZoom(
        page: MissionQuestionScreen(
          mission: widget.mission,
          questions: _questions,
        ),
      ),
    );

    // Immediately pop back to MissionSubjectScreen with the result
    // Since this screen has Visibility(visible: false), user won't see it
    if (mounted) {
      Navigator.pop(context, completedMissionId);
    }
  }

  void _handleNoQuestions(String message) {
    print(
        '🔵 MissionSplashScreen: No questions available, mission may be completed');

    // Complete the mission to update status and refresh mission list
    print('🔵 MissionSplashScreen: Completing mission ${widget.mission.id}');
    context.read<MissionBloc>().add(CompleteMission(widget.mission.id));
    context.read<MissionBloc>().add(RefreshMissions(
          month: widget.mission.missionDate.month,
          year: widget.mission.missionDate.year,
        ));

    // Show completion snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.celebration,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Congratulations! Mission completed successfully! 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Navigate back after showing the message
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        // Pass the completed mission ID back to the previous screen
        Navigator.pop(context, widget.mission.id);
      }
    });
  }

  @override
  void dispose() {
    print('🔵 MissionSplashScreen: dispose() called');
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 MissionSplashScreen: build() called - Instance: ${hashCode}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Visibility(
        visible: false,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Image.asset(
                  'assets/images/lamp.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
