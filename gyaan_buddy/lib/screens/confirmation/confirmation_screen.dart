import 'package:flutter/material.dart';
import '../../utils/animation_utils.dart';
import '../../utils/connected_page_transitions.dart';
import '../../screens/home/home_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onContinue;

  const ConfirmationScreen({
    super.key,
    this.title,
    this.subtitle,
    this.onContinue,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _backgroundController;

  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _backgroundScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut,
    ));

    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _backgroundScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    ));

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _backgroundController.forward();
    });

    // Navigate to home after all animations complete
    _setupAutoNavigation();
  }

  void _setupAutoNavigation() {
    // Wait for the longest animation to complete (background animation: 1200ms)
    // Add a small delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Navigate to home with fade through for clean completion feel
        Navigator.of(context).pushAndRemoveUntil(
          ConnectedPageTransitions.fadeThrough(page: const HomeScreen()),
          (route) => false, // This removes all previous routes
        );
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background elements
          _buildBackgroundElements(),
          
          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    _buildSuccessIcon(),
                    
                    const SizedBox(height: 40),
                    
                    // Thank You Text
                    _buildThankYouText(),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle Text
                    _buildSubtitleText(),
                    
                    const SizedBox(height: 60),
                    
                    // Continue Button (if provided)
                    if (widget.onContinue != null) _buildContinueButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Transform.scale(
          scale: _backgroundScaleAnimation.value,
          child: Stack(
            children: [
              // Top right large partial circle
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Top left small full circle
              Positioned(
                top: 50,
                left: -30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Bottom left large partial circle
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Bottom right small partial circle
              Positioned(
                bottom: 100,
                right: -40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconScaleAnimation.value,
          child: Opacity(
            opacity: _iconOpacityAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 4,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 60,
                weight: 900,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThankYouText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: Opacity(
            opacity: _textOpacityAnimation.value,
            child: Text(
              widget.title ?? 'Thank You',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitleText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: Opacity(
            opacity: _textOpacityAnimation.value,
            child: Text(
              widget.subtitle ?? 'Your Account has been created',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    if (widget.onContinue == null) {
      return const SizedBox.shrink();
    }
    
    return AnimationUtils.animatedButton(
      onPressed: widget.onContinue!,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Continue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
