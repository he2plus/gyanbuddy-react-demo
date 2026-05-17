# 🎮 Game-Like Animation Guide

This guide covers all the enhanced animations and interactive elements added to make your Flutter app feel more engaging and game-like.

## 🚀 Quick Start

To see all animations in action, navigate to the demo screen:
```dart
Navigator.pushNamed(context, '/animation-demo');
```

## ✨ Core Animation Utilities

### GameAnimations Class

The main utility class providing easy-to-use animation widgets:

#### 1. Particle Burst Effect
```dart
GameAnimations.particleBurst(
  child: YourWidget(),
  onComplete: () => print('Animation complete!'),
  particleColor: Colors.amber,
  particleCount: 20,
  duration: Duration(milliseconds: 1500),
)
```

#### 2. Floating Animation
```dart
GameAnimations.floatingAnimation(
  child: YourWidget(),
  amplitude: 8.0,
  duration: Duration(seconds: 2),
  curve: Curves.easeInOut,
)
```

#### 3. Bounce Animation
```dart
GameAnimations.bounceAnimation(
  onTap: () => print('Tapped!'),
  child: YourWidget(),
  scale: 0.95,
  duration: Duration(milliseconds: 150),
)
```

#### 4. Shake Animation
```dart
GameAnimations.shakeAnimation(
  child: YourWidget(),
  duration: Duration(milliseconds: 500),
)
```

#### 5. Pulse Animation
```dart
GameAnimations.pulseAnimation(
  child: YourWidget(),
  duration: Duration(seconds: 1),
)
```

#### 6. Slide In with Bounce
```dart
GameAnimations.slideInBounce(
  child: YourWidget(),
  begin: Offset(0, 1), // Slide from bottom
  duration: Duration(milliseconds: 600),
)
```

#### 7. Rotate and Scale
```dart
GameAnimations.rotateScale(
  child: YourWidget(),
  rotation: 360, // Degrees
  scale: 1.2,
  duration: Duration(milliseconds: 800),
)
```

## 🎭 Enhanced Page Transitions

### EnhancedTransitions Class

Advanced page transition animations:

#### 1. Hero Transition
```dart
Navigator.push(
  context,
  EnhancedTransitions.heroTransition(
    page: YourPage(),
    tag: 'unique_tag',
    duration: Duration(milliseconds: 400),
  ),
);
```

#### 2. 3D Flip Transition
```dart
Navigator.push(
  context,
  EnhancedTransitions.flipTransition(
    page: YourPage(),
    duration: Duration(milliseconds: 600),
    axis: Axis.y, // or Axis.x
  ),
);
```

#### 3. Scale and Fade Transition
```dart
Navigator.push(
  context,
  EnhancedTransitions.scaleFadeTransition(
    page: YourPage(),
    duration: Duration(milliseconds: 400),
    beginScale: 0.8,
  ),
);
```

#### 4. Slide with Bounce
```dart
Navigator.push(
  context,
  EnhancedTransitions.slideBounceTransition(
    page: YourPage(),
    duration: Duration(milliseconds: 500),
    begin: Offset(1.0, 0.0), // Slide from right
  ),
);
```

#### 5. Parallax Transition
```dart
Navigator.push(
  context,
  EnhancedTransitions.parallaxTransition(
    page: YourPage(),
    duration: Duration(milliseconds: 600),
    parallaxValue: 0.5,
  ),
);
```

#### 6. Morphing Transition
```dart
Navigator.push(
  context,
  EnhancedTransitions.morphingTransition(
    page: YourPage(),
    duration: Duration(milliseconds: 800),
  ),
);
```

#### 7. Staggered Entrance
```dart
Navigator.push(
  context,
  EnhancedTransitions.staggeredEntranceTransition(
    page: YourPage(),
    duration: Duration(milliseconds: 600),
    staggerDelay: Duration(milliseconds: 100),
  ),
);
```

## 🎯 Interactive Game Widgets

### InteractiveCard
A card with 3D tilt effects and smooth animations:
```dart
InteractiveCard(
  onTap: () => print('Card tapped!'),
  elevation: 8.0,
  enableTilt: true,
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Interactive Card'),
  ),
)
```

### GameProgressIndicator
Animated progress bar with glow effects:
```dart
GameProgressIndicator(
  value: 0.7,
  maxValue: 1.0,
  color: Colors.blue,
  height: 16.0,
  showGlow: true,
  animationDuration: Duration(milliseconds: 800),
)
```

### GameFloatingActionButton
FAB with particle effects:
```dart
GameFloatingActionButton(
  onPressed: () => print('FAB pressed!'),
  backgroundColor: Colors.red,
  particleColor: Colors.yellow,
  size: 72.0,
  child: Icon(Icons.add, color: Colors.white),
)
```

### AnimatedCounter
Counter with bounce effects:
```dart
AnimatedCounter(
  value: 42,
  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
  animationDuration: Duration(milliseconds: 500),
  curve: Curves.elasticOut,
)
```

### InteractiveListItem
List item with swipe actions:
```dart
InteractiveListItem(
  onTap: () => print('Item tapped!'),
  trailingActions: [
    Container(
      width: 100,
      color: Colors.red,
      child: Icon(Icons.delete, color: Colors.white),
    ),
  ],
  child: ListTile(
    title: Text('Swipeable Item'),
    subtitle: Text('Swipe left to reveal actions'),
  ),
)
```

## 🎨 Enhanced Hero Widgets

### EnhancedHero
Hero widget with custom flight animations:
```dart
EnhancedHero(
  tag: 'unique_tag',
  flightDuration: Duration(milliseconds: 400),
  flightCurve: Curves.easeInOutCubic,
  child: YourWidget(),
)
```

### SharedElementTransition
Smooth shared element transitions:
```dart
SharedElementTransition(
  tag: 'shared_tag',
  duration: Duration(milliseconds: 400),
  curve: Curves.easeInOutCubic,
  child: YourWidget(),
)
```

## 🔧 Integration Examples

### Enhanced Splash Screen
The main splash screen now includes:
- Floating background elements
- Particle animations
- Smooth logo scaling and rotation
- Staggered text animations
- Enhanced loading indicators

### Enhanced Navigation Bar
The bottom navigation now features:
- 3D transform effects
- Particle burst on tab change
- Floating animations for selected items
- Glow effects and shadows
- Smooth scale transitions

### Quiz Screen Enhancements
Add game-like feedback:
```dart
// Success feedback
GameAnimations.particleBurst(
  child: YourSuccessWidget(),
  onComplete: () => navigateToNext(),
  particleColor: Colors.green,
  particleCount: 30,
);

// Error feedback
GameAnimations.shakeAnimation(
  child: YourErrorWidget(),
  duration: Duration(milliseconds: 500),
);
```

## 🎮 Performance Tips

1. **Use `TickerProviderStateMixin`** for multiple animations
2. **Dispose controllers** properly to prevent memory leaks
3. **Limit particle count** for better performance
4. **Use `AnimatedBuilder`** instead of `setState` when possible
5. **Cache animations** that repeat frequently

## 🎨 Customization

### Animation Curves
```dart
// Built-in curves
Curves.easeInOut
Curves.elasticOut
Curves.bounceOut
Curves.easeOutCubic

// Custom curves
CurveTween(curve: Curves.easeInOut)
```

### Animation Durations
```dart
// Standard durations
Duration(milliseconds: 200)  // Fast
Duration(milliseconds: 300)  // Normal
Duration(milliseconds: 500)  // Slow
Duration(seconds: 1)         // Very slow
```

### Color Schemes
```dart
// Primary colors
Colors.blue
Colors.purple
Colors.green
Colors.orange

// With opacity
Colors.blue.withOpacity(0.8)
```

## 🚀 Advanced Usage

### Combining Multiple Animations
```dart
class CombinedAnimation extends StatefulWidget {
  @override
  State<CombinedAnimation> createState() => _CombinedAnimationState();
}

class _CombinedAnimationState extends State<CombinedAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _controller2 = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _controller1.forward();
    _controller2.forward();
  }
  
  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller1, _controller2]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: YourWidget(),
          ),
        );
      },
    );
  }
}
```

### Custom Particle Systems
```dart
class CustomParticleSystem extends StatefulWidget {
  @override
  State<CustomParticleSystem> createState() => _CustomParticleSystemState();
}

class _CustomParticleSystemState extends State<CustomParticleSystem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _particleAnimations;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _particleAnimations = List.generate(20, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index / 20,
          (index + 1) / 20,
          curve: Curves.easeOut,
        ),
      ));
    });
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            return Positioned(
              left: 100 + 50 * math.cos(index * 0.314),
              top: 100 + 50 * math.sin(index * 0.314),
              child: Opacity(
                opacity: _particleAnimations[index].value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
```

## 🎯 Best Practices

1. **Consistent Timing**: Use standard duration values across your app
2. **Meaningful Feedback**: Animations should provide useful information
3. **Performance First**: Prioritize smooth 60fps animations
4. **Accessibility**: Ensure animations don't interfere with screen readers
5. **User Control**: Allow users to disable animations if needed

## 🔍 Troubleshooting

### Common Issues

1. **Animation not working**: Check if `TickerProviderStateMixin` is added
2. **Memory leaks**: Ensure all `AnimationController`s are disposed
3. **Performance issues**: Reduce particle count or animation complexity
4. **Layout issues**: Use `AnimatedBuilder` instead of `setState`

### Debug Tips

```dart
// Add debug prints to track animation state
print('Animation value: ${_animation.value}');

// Check if widget is mounted
if (mounted) {
  // Safe to call setState
}

// Verify animation controller state
print('Controller status: ${_controller.status}');
```

## 📱 Platform Considerations

### iOS
- Smooth animations with Metal
- Respect user's reduced motion preferences
- Use `Curves.easeInOut` for natural feel

### Android
- Hardware acceleration enabled by default
- Material Design motion principles
- Consider lower-end device performance

### Web
- CSS animations for better performance
- Reduce animation complexity
- Test on different browsers

## 🎬 App Bar and Body Animations

### AnimatedScreenLayout
The new `AnimatedScreenLayout` widget provides smooth app bar and body animations:

#### Basic Usage
```dart
AnimatedScreenLayout(
  appBar: YourAppBarWidget(),
  body: YourBodyWidget(),
  animationDuration: Duration(milliseconds: 600),
  animationCurve: Curves.easeOutCubic,
  enableStaggeredAnimation: true,
  staggerDelay: Duration(milliseconds: 100),
)
```

#### Bouncy Version
```dart
BouncyAnimatedScreenLayout(
  appBar: YourAppBarWidget(),
  body: YourBodyWidget(),
  animationDuration: Duration(milliseconds: 800),
  enableBounceEffect: true,
  bounceIntensity: 0.1,
)
```

#### Simple Version
```dart
SimpleAnimatedScreenLayout(
  appBar: YourAppBarWidget(),
  body: YourBodyWidget(),
  duration: Duration(milliseconds: 400),
)
```

### Individual Animation Methods

#### App Bar Slide From Top
```dart
GameAnimations.appBarSlideFromTop(
  child: YourAppBarWidget(),
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
)
```

#### Body Slide From Bottom
```dart
GameAnimations.bodySlideFromBottom(
  child: YourBodyWidget(),
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
)
```

#### Combined Screen Animation
```dart
GameAnimations.screenSlideAnimation(
  appBar: YourAppBarWidget(),
  body: YourBodyWidget(),
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
  enableStaggered: true,
  staggerDelay: Duration(milliseconds: 100),
)
```

### Integration Examples

#### Home Screen with Animated Layout
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: AnimatedScreenLayout(
      appBar: TopTimer(
        studyTimer: _studyTimer,
        backgroundColor: _currentPageColor,
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 150),
        child: _buildBody(key: ValueKey(_selectedIndex)),
      ),
      animationDuration: Duration(milliseconds: 600),
      enableStaggeredAnimation: true,
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}
```

#### Mission Detail Screen
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: BackgroundContainer(
      child: SafeArea(
        child: AnimatedScreenLayout(
          appBar: _buildTopNavigationBar(context),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildMissionInfoCard(context, content),
                _buildContentByType(context, content),
              ],
            ),
          ),
          animationDuration: Duration(milliseconds: 600),
          enableStaggeredAnimation: true,
          staggerDelay: Duration(milliseconds: 150),
        ),
      ),
    ),
  );
}
```

## 🎉 Conclusion

These animations will transform your app from a static interface to an engaging, game-like experience. The new app bar and body animations provide smooth, professional transitions that enhance user experience. Remember to:

- Start simple and build complexity gradually
- Test on real devices for performance
- Keep animations purposeful and meaningful
- Use staggered animations for better visual flow
- Have fun creating delightful user experiences!

For more examples and advanced techniques, explore the demo screen and experiment with different combinations of animations.
