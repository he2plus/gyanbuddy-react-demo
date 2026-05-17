import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../../services/posthog_service.dart';
import '../../services/vibration_service.dart';
import '../../services/notification_service.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _admissionController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Primary button color as specified
  static const Color _primaryButtonColor = Color(0xFF00167A);

  @override
  void initState() {
    super.initState();
    // Track screen view
    PostHogService.screen('new_login_screen');
  }


  @override
  void dispose() {
    _admissionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserAuthenticated) {
              // Track successful login
              PostHogService.capture('login_successful', properties: {
                'user_id': state.user.id.toString(),
                'user_type': state.user.userType.toString(),
                'is_new_user': !state.user.loggedInOnce,
                'timestamp': DateTime.now().toIso8601String(),
              });

              // Identify user in PostHog
              PostHogService.identify(
                userId: state.user.id.toString(),
                userProperties: {
                  'admission_number': state.user.username,
                  'user_type': state.user.userType.toString(),
                  'logged_in_once': state.user.loggedInOnce,
                  'created_at': state.user.createdAt?.toIso8601String(),
                },
              );

              // Check if user has logged in before
              if (state.user.loggedInOnce) {
                // Show success message for returning user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login successful! Welcome back!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pushReplacementNamed('/home');
              } else {
                // Show welcome message for new user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Welcome! Please complete your profile setup.'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Navigate to confirmation screen for new users
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pushReplacementNamed('/confirmation');
                });
              }
            } else if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      SizedBox(
                        height: 110.h,
                      ),
                      Center(
                        child: Image.asset(
                          'assets/images/login_logo.png',
                          width: 230.w,
                          scale: 40,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      const SizedBox(height: 30),

                        // Title
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Log In to your account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Admission Number TextField
                      TextField(
                        controller: _admissionController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Admission Number',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF00167A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password TextField with icons
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF00167A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Log In Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state is UserLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    // await SoundService().playButtonClick();
                                    await VibrationService().successVibration();

                                          // Track login attempt
                                          PostHogService.capture(
                                            'login_attempted',
                                            properties: {
                                              'admission_number': _admissionController.text.trim(),
                                              'timestamp': DateTime.now().toIso8601String(),
                                            },
                                          );

                                    final fcmToken = await NotificationService().getFCMToken();
                                    final loginData = {
                                      'username': _admissionController.text.trim(),
                                      'password': _passwordController.text,
                                      if (fcmToken != null) 'fcm_token': fcmToken,
                                    };
                                    context.read<UserBloc>().add(LoginUser(loginData));
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryButtonColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            disabledBackgroundColor:
                                _primaryButtonColor.withOpacity(0.6),
                          ),
                          child: state is UserLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  disabledBackgroundColor:
                                      _primaryButtonColor.withValues(alpha: 0.6),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Request an account
                      // Center(
                      //   child: GestureDetector(
                      //     onTap: () {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //           content: Text('GyanBuddy Team will contact you soon!'),
                      //           backgroundColor: Color(0xFF00167A),
                      //           duration: Duration(seconds: 3),
                      //         ),
                      //       );
                      //     },
                      //     child: const Text(
                      //       'Request an account?',
                      //       style: TextStyle(
                      //         fontSize: 16,
                      //         color: Color(0xFF00167A),
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}
