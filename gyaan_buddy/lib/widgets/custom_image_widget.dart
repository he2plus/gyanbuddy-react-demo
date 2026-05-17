import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomImageWidget extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final BorderRadius? borderRadius;

  const CustomImageWidget({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16.w),
      margin: margin,
      decoration: decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
      child: child,
    );
  }
} 