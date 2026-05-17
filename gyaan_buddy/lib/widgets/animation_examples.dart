import 'package:flutter/material.dart';
import 'animated_screen_layout.dart';
import '../utils/game_animations.dart';

/// Example widget demonstrating different app bar and body animation options
class AnimationExamples extends StatefulWidget {
  const AnimationExamples({super.key});

  @override
  State<AnimationExamples> createState() => _AnimationExamplesState();
}

class _AnimationExamplesState extends State<AnimationExamples> {
  int _selectedExample = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Example selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedExample = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedExample == 0 ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Basic'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedExample = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedExample == 1 ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Bouncy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedExample = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedExample == 2 ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Simple'),
                  ),
                ),
              ],
            ),
          ),
          
          // Example content
          Expanded(
            child: _buildExampleContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleContent() {
    switch (_selectedExample) {
      case 0:
        return _buildBasicExample();
      case 1:
        return _buildBouncyExample();
      case 2:
        return _buildSimpleExample();
      default:
        return _buildBasicExample();
    }
  }

  Widget _buildBasicExample() {
    return AnimatedScreenLayout(
      appBar: _buildAppBar(),
      body: _buildBody(),
      animationDuration: const Duration(milliseconds: 600),
      animationCurve: Curves.easeOutCubic,
      enableStaggeredAnimation: true,
      staggerDelay: const Duration(milliseconds: 100),
    );
  }

  Widget _buildBouncyExample() {
    return BouncyAnimatedScreenLayout(
      appBar: _buildAppBar(),
      body: _buildBody(),
      animationDuration: const Duration(milliseconds: 800),
      enableBounceEffect: true,
      bounceIntensity: 0.1,
    );
  }

  Widget _buildSimpleExample() {
    return SimpleAnimatedScreenLayout(
      appBar: _buildAppBar(),
      body: _buildBody(),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Text(
              'Animated App Bar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Animation Examples',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Individual animation examples
          _buildAnimationCard(
            title: 'App Bar Slide From Top',
            child: GameAnimations.appBarSlideFromTop(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('This app bar slides from top!'),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildAnimationCard(
            title: 'Body Slide From Bottom',
            child: GameAnimations.bodySlideFromBottom(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('This body slides from bottom!'),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildAnimationCard(
            title: 'Particle Burst Effect',
            child: GameAnimations.particleBurst(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Tap for particle burst!'),
              ),
              onComplete: () => print('Particle animation complete!'),
              particleColor: Colors.purple,
              particleCount: 15,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildAnimationCard(
            title: 'Bounce Animation',
            child: GameAnimations.bounceAnimation(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Tap to bounce!'),
              ),
              onTap: () => print('Bounced!'),
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Features:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('• App bar slides from top'),
          const Text('• Body slides from bottom'),
          const Text('• Staggered animations'),
          const Text('• Smooth fade transitions'),
          const Text('• Customizable duration and curves'),
          const Text('• Bounce effects available'),
        ],
      ),
    );
  }

  Widget _buildAnimationCard({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
