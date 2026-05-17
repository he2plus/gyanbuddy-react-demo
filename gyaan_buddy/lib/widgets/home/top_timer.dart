import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/study_timer.dart';

class TopTimer extends StatefulWidget {
  final StudyTimer studyTimer;
  final Color? backgroundColor;

  const TopTimer({
    super.key,
    required this.studyTimer,
    this.backgroundColor,
  });

  @override
  State<TopTimer> createState() => _TopTimerState();
}

class _TopTimerState extends State<TopTimer> {
  @override
  void initState() {
    super.initState();
    widget.studyTimer.addListener(_onTimerChanged);
  }

  @override
  void dispose() {
    widget.studyTimer.removeListener(_onTimerChanged);
    super.dispose();
  }

  void _onTimerChanged() {
    setState(() {
      // Rebuild the widget when timer changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kIsWeb ? 45 : 45.h,
      padding: EdgeInsets.symmetric(
        vertical: kIsWeb ? 8 : 8.h,
        horizontal: kIsWeb ? 16 : 16.w,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: kIsWeb ? 4 : 4.r,
            offset: Offset(0, kIsWeb ? 2 : 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: kIsWeb ? 20 : 20.w,
          ),
          SizedBox(width: kIsWeb ? 8 : 8.w),
          Text(
            widget.studyTimer.formatTime(),
            style: TextStyle(
              color: Colors.white,
              fontSize: kIsWeb ? 18 : 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: kIsWeb ? 16 : 16.w),
          GestureDetector(
            onTap: widget.studyTimer.stop,
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: kIsWeb ? 20 : 20.w,
            ),
          ),
        ],
      ),
    );
  }
} 