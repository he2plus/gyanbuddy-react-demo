import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer placeholder widget for loading states
/// Used primarily as a placeholder for CachedNetworkImage while loading
class ShimmerImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final BoxShape shape;

  const ShimmerImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDarkMode ? Colors.grey[600]! : Colors.grey[100]!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle 
              ? BorderRadius.circular(borderRadius) 
              : null,
        ),
      ),
    );
  }
}

/// A circular shimmer placeholder for avatar-like images
class ShimmerCirclePlaceholder extends StatelessWidget {
  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerCirclePlaceholder({
    super.key,
    required this.size,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerImagePlaceholder(
      width: size,
      height: size,
      shape: BoxShape.circle,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}

