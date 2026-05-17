import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/vibration_service.dart';
import '../../widgets/animated_screen_layout.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: kIsWeb ? 24 : 24.sp,
          ),
          onPressed: () async {
            await VibrationService().navigationVibration();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Credits',
          style: TextStyle(
            color: Colors.black87,
            fontSize: kIsWeb ? 20 : 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(kIsWeb ? 24 : 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: kIsWeb ? 20 : 20.h),

              // App Logo
              Container(
                width: kIsWeb ? 120 : 120.w,
                height: kIsWeb ? 120 : 120.w,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      spreadRadius: kIsWeb ? 2 : 2.r,
                      blurRadius: kIsWeb ? 15 : 15.r,
                      offset: Offset(0, kIsWeb ? 5 : 5.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/final_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school,
                        size: kIsWeb ? 60 : 60.sp,
                        color: Colors.green,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: kIsWeb ? 24 : 24.h),

              // App Name
              Text(
                'GyanBuddy',
                style: TextStyle(
                  fontSize: kIsWeb ? 32 : 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: kIsWeb ? 8 : 8.h),

              Text(
                'A Smarter way to learn',
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : 16.sp,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: kIsWeb ? 40 : 40.h),

              // About GyanBuddy
              _buildCreditsCard(
                context,
                title: 'About GyanBuddy',
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : 16.w,
                      vertical: kIsWeb ? 12 : 12.h,
                    ),
                    child: Text(
                      'GyanBuddy is a learning platform designed to make education engaging and fun. '
                      'Built with passion and dedication to help students learn effectively through '
                      'interactive quizzes, missions, and gamified learning experiences.',
                      style: TextStyle(
                        fontSize: kIsWeb ? 14 : 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(height: kIsWeb ? 20 : 20.h),

              // Special Thanks
              _buildCreditsCard(
                context,
                title: 'Special Thanks',
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : 16.w,
                      vertical: kIsWeb ? 12 : 12.h,
                    ),
                    child: Text(
                      'Thank you to all the users, educators, and supporters who believe in making '
                      'quality education accessible to everyone. Your feedback and encouragement '
                      'drive us to keep improving GyanBuddy.',
                      style: TextStyle(
                        fontSize: kIsWeb ? 14 : 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(height: kIsWeb ? 20 : 20.h),

              // Our Team
              _buildCreditsCard(
                context,
                title: 'Our Team',
                children: [
                  _buildCreditItem(
                    context,
                    name: 'Rehan Sareen',
                    role: 'Founder, CEO',
                    icon: Icons.business,
                  ),
                  _buildCreditItem(
                    context,
                    name: 'Parul Nagpal',
                    role: 'Academic Advisor',
                    icon: Icons.school,
                  ),
                  _buildCreditItem(
                    context,
                    name: 'Sanskriti Vaidya',
                    role: 'Brand Identity Designer',
                    icon: Icons.palette,
                  ),
                  _buildCreditItem(
                    context,
                    name: 'Bhavya Bharadwaj',
                    role: 'AI Specialist',
                    icon: Icons.psychology,
                  ),
                  _buildCreditItem(
                    context,
                    name: 'Mridul Saxena',
                    role: 'Developer',
                    icon: Icons.code,
                  ),
                  _buildCreditItem(
                    context,
                    name: 'Aayush Sharma',
                    role: 'Developer',
                    icon: Icons.code,
                  ),
                  _buildCreditItem(
                    context,
                    name: 'Rahul Srivastava',
                    role: 'Developer',
                    icon: Icons.code,
                  ),
                  // _buildCreditItem(
                  //   context,
                  //   name: 'Sushant Malik',
                  //   role: 'Developer',
                  //   icon: Icons.code,
                  // ),
                ],
              ),
              SizedBox(height: kIsWeb ? 40 : 40.h),

              // Footer
              Text(
                'Made with ❤️ for learners everywhere',
                style: TextStyle(
                  fontSize: kIsWeb ? 14 : 14.sp,
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: kIsWeb ? 8 : 8.h),
              Text(
                '© ${DateTime.now().year} GyanBuddy',
                style: TextStyle(
                  fontSize: kIsWeb ? 12 : 12.sp,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(height: kIsWeb ? 30 : 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditsCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: kIsWeb ? 1 : 1.r,
            blurRadius: kIsWeb ? 10 : 10.r,
            offset: Offset(0, kIsWeb ? 2 : 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 20 : 20.w,
              vertical: kIsWeb ? 16 : 16.h,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kIsWeb ? 16 : 16.r),
                topRight: Radius.circular(kIsWeb ? 16 : 16.r),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: kIsWeb ? 18 : 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCreditItem(
    BuildContext context, {
    required String name,
    required String role,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 16 : 16.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: Row(
        children: [
          Container(
            width: kIsWeb ? 50 : 50.w,
            height: kIsWeb ? 50 : 50.w,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: kIsWeb ? 24 : 24.sp,
            ),
          ),
          SizedBox(width: kIsWeb ? 16 : 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: kIsWeb ? 16 : 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: kIsWeb ? 4 : 4.h),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
