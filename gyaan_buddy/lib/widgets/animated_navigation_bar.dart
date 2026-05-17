import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vibration/vibration.dart';

class AnimatedNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavigationItem> items;

  const AnimatedNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  State<AnimatedNavigationBar> createState() => _AnimatedNavigationBarState();
}

class _AnimatedNavigationBarState extends State<AnimatedNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int _animatingIndex = -1;

  @override
  void initState() {
    super.initState();
    
    // Bounce animation for selected tab
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(AnimatedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _triggerBounceAnimation(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _triggerBounceAnimation(int index) {
    setState(() {
      _animatingIndex = index;
    });
    
    _bounceController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _animatingIndex = -1;
        });
      }
    });
  }

  void _onItemTap(int index) {
    if (index != widget.selectedIndex) {
      widget.onItemSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get bottom padding for gesture navigation
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final floatingMargin = 20.w;
    final extraTopHeight = 2.h; // Extra height above the nav bar for smooth fade
    final totalHeight = extraTopHeight + 48.h + (bottomPadding > 0 ? bottomPadding + 2.h : 12.h);
    
    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Glass blur backdrop container behind navigation bar
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    // Glass effect with ultra-smooth fade-in from top
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.02),
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.20),
                      ],
                      stops: const [0.0, 0.1, 0.2, 0.35, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Navigation bar on top
          Positioned(
            left: floatingMargin,
            right: floatingMargin,
            top: extraTopHeight,
            bottom: bottomPadding > 0 ? bottomPadding + 2.h : 12.h,
            child: SizedBox(
              height: 48.h,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Main pill container with glass effect
                  Positioned(
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            // Glass effect with subtle transparency
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28.r),
                            // Frosted glass border
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              // Outer glow shadow
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 32.r,
                                spreadRadius: 0,
                                offset: Offset(0, 12.h),
                              ),
                              // Inner soft shadow
                              BoxShadow(
                                color: Colors.white.withOpacity(0.15),
                                blurRadius: 1.r,
                                spreadRadius: 0,
                                offset: Offset(0, -1.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: widget.items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isSelected = index == widget.selectedIndex;

                              return _buildNavItem(index, item, isSelected);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Floating selected circle with glass effect and bounce animation
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: _getSelectedPosition(widget.selectedIndex),
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        final scale = _animatingIndex == widget.selectedIndex
                            ? _bounceAnimation.value
                            : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: _buildSelectedCircle(widget.items[widget.selectedIndex]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getSelectedPosition(int index) {
    // Calculate position based on index
    // Account for floating margins (20.w on each side)
    final floatingMargin = 20.w;
    final containerWidth = MediaQuery.of(context).size.width - (floatingMargin * 2);
    final pillWidth = containerWidth; // pill is now centered (left: 0, right: 0)
    final itemCount = widget.items.length;
    
    // Calculate the center position for each item within the pill
    // spaceEvenly distributes items with equal space around them
    final itemSpacing = pillWidth / itemCount;
    final itemCenterOffset = itemSpacing / 2;
    
    // Position of item center within the pill
    final positionInPill = (index * itemSpacing) + itemCenterOffset;
    
    // Center the circle (48.w / 2 = 24.w)
    return positionInPill - 24.w;
  }

  Widget _buildSelectedCircle(NavigationItem item) {
    return GestureDetector(
      onTap: () {
        Vibration.vibrate(duration: 50);
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              // Glass effect with subtle white overlay
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.20),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                  offset: Offset(0, 6.h),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 1.r,
                  offset: Offset(0, -1.h),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getIconData(item),
                size: item.size ?? 32.w,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(NavigationItem item) {
    // Map labels to appropriate Material icons
    switch (item.label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded; // More rounded, modern look
      case 'subject':
      case 'subjects':
        return Icons.auto_stories_rounded; // Better for educational content
      case 'leaderboard':
      case 'dashboard':
        return Icons.emoji_events_rounded; // Trophy/award icon for leaderboard
      case 'mission':
      case 'missions':
        return Icons.assignment_rounded; // Assignment icon for missions
      case 'you':
      case 'profile':
        return Icons.account_circle_rounded; // More complete profile icon
      default:
        return Icons.circle;
    }
  }

  Widget _buildNavItemIcon(NavigationItem item) {
    return Icon(
      _getIconData(item),
      size: item.size ?? 24.w,
      color: const Color(0xFF1F2937),
    );
  }

  Widget _buildNavItem(int index, NavigationItem item, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Vibration.vibrate(duration: 50);
        _onItemTap(index);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 0.0 : 1.0,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Center(
            child: _buildNavItemIcon(item),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String imagePath;
  final String label;
  final double? size;

  NavigationItem({
    required this.imagePath,
    required this.label,
    this.size,
  });
}
