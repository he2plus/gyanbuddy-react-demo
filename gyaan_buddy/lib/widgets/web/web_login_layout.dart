import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Web-specific login layout with stunning split-screen design
class WebLoginLayout extends StatefulWidget {
  final Widget formContent;

  const WebLoginLayout({
    super.key,
    required this.formContent,
  });

  @override
  State<WebLoginLayout> createState() => _WebLoginLayoutState();
}

class _WebLoginLayoutState extends State<WebLoginLayout>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _floatAnimation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_gradientController);
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1000;
    final isMediumScreen = screenSize.width > 700;

    return Scaffold(
      body: Row(
        children: [
          // Left side - Immersive Branding
          if (isMediumScreen)
            Expanded(
              flex: isWideScreen ? 6 : 5,
              child: _buildBrandingSection(context),
            ),
          
          // Right side - Login Form
          Expanded(
            flex: isWideScreen ? 4 : (isMediumScreen ? 5 : 1),
            child: _buildFormSection(context, isMediumScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        // Animated gradient colors
        final gradientProgress = _gradientAnimation.value;
        final color1 = Color.lerp(
          const Color(0xFF0A0E21),
          const Color(0xFF1A1F3D),
          math.sin(gradientProgress * math.pi * 2) * 0.5 + 0.5,
        )!;
        final color2 = Color.lerp(
          const Color(0xFF1A1F3D),
          const Color(0xFF0D1025),
          math.cos(gradientProgress * math.pi * 2) * 0.5 + 0.5,
        )!;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
          child: Stack(
            children: [
              // Animated mesh gradient background
              _buildMeshGradient(),
              
              // Floating orbs
              _buildFloatingOrbs(),
              
              // Particle system
              _buildParticles(),
              
              // Grid lines
              _buildGridOverlay(),
              
              // Main content
              _buildMainContent(context),
              
              // Bottom wave
              _buildBottomWave(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeshGradient() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: _MeshGradientPainter(
              animation: _floatAnimation.value,
              gradientProgress: _gradientAnimation.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Large primary orb
            Positioned(
              top: 80 + _floatAnimation.value,
              right: 60,
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.4),
                        const Color(0xFF8B5CF6).withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Secondary orb
            Positioned(
              bottom: 150 - _floatAnimation.value * 0.7,
              left: 80,
              child: Transform.scale(
                scale: 1.1 - (_pulseAnimation.value - 1) * 0.5,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.35),
                        const Color(0xFF34D399).withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Accent orb
            Positioned(
              top: 300 + _floatAnimation.value * 0.5,
              left: 200,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF59E0B).withOpacity(0.3),
                      const Color(0xFFFBBF24).withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(progress: _particleAnimation.value),
        );
      },
    );
  }

  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * 0.95 + 0.05,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF818CF8),
                              Color(0xFF6366F1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/boy.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gyaan Buddy',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Learning Reimagined',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const Spacer(),
            
            // Main headline with animation
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value * 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFE0E7FF),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Master Your\nLearning Journey',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Interactive quizzes, personalized paths, and\nreal-time progress tracking.',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 50),
            
            // Stats row
            _buildStatsRow(),
            
            const Spacer(),
            
            // Feature pills
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFeaturePill(Icons.bolt_rounded, 'Quick Quizzes', const Color(0xFF6366F1)),
                _buildFeaturePill(Icons.emoji_events_rounded, 'Leaderboards', const Color(0xFFF59E0B)),
                _buildFeaturePill(Icons.insights_rounded, 'Analytics', const Color(0xFF10B981)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem('10K+', 'Students'),
        const SizedBox(width: 40),
        _buildStatItem('500+', 'Quizzes'),
        const SizedBox(width: 40),
        _buildStatItem('98%', 'Success'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomWave() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _WavePainter(),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, bool isMediumScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMediumScreen
            ? const BorderRadius.only(
                topLeft: Radius.circular(50),
                bottomLeft: Radius.circular(50),
              )
            : null,
        boxShadow: isMediumScreen
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(-10, 0),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Subtle pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _SubtlePatternPainter(),
            ),
          ),
          // Form content
          widget.formContent,
        ],
      ),
    );
  }
}

// Custom painters
class _MeshGradientPainter extends CustomPainter {
  final double animation;
  final double gradientProgress;

  _MeshGradientPainter({required this.animation, required this.gradientProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          -0.5 + math.sin(gradientProgress * math.pi * 2) * 0.3,
          -0.3 + math.cos(gradientProgress * math.pi * 2) * 0.3,
        ),
        radius: 1.5,
        colors: [
          const Color(0xFF6366F1).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.gradientProgress != gradientProgress;
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + progress * size.height * (0.5 + random.nextDouble() * 0.5)) % size.height;
      final radius = 1.0 + random.nextDouble() * 2.0;
      final opacity = 0.1 + random.nextDouble() * 0.2;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF0A0E21).withOpacity(0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.3,
        size.width * 0.5, size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.7,
        size.width, size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SubtlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F5F9).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
