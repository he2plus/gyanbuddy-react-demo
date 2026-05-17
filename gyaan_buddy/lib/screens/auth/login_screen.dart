import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/user/user_bloc.dart';
import '../../services/posthog_service.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/vibration_button.dart';
import '../../widgets/web_connectivity_widget.dart';
import '../../utils/web_size_utils.dart';
import '../../widgets/web_safe_area.dart';
import '../../widgets/web/web_login_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  // Theme color for login screen
  static const Color _themeColor = Color(0xFF4A90E2);
  
  // Circle animation controller
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  // Helper function to create light/pastel versions of color for gradients
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Colors.white,
    ];
  }

  List<Color> _getBottomGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
    ];
  }

  @override
  void initState() {
    super.initState();
    // Track screen view
    PostHogService.screen('login_screen');
    
    // Initialize circle animation
    _circleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _circleAnimation = Tween<double>(
      begin: -20.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use web-specific layout with split-screen design on web
    if (kIsWeb) {
      return WebLoginLayout(
        formContent: _buildWebLoginForm(),
      );
    }
    
    // Mobile layout
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WebConnectivityWidget(
        onRetry: () async {
          // Retry login if needed
          if (_formKey.currentState?.validate() == true) {
            final fcmToken = await NotificationService().getFCMToken();
            final loginData = {
              'username': _emailController.text.trim(),
              'password': _passwordController.text,
              if (fcmToken != null) 'fcm_token': fcmToken,
            };
            context.read<UserBloc>().add(LoginUser(loginData));
          }
        },
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

              print(
                  'LoginScreen: User authenticated - loggedInOnce: ${state.user.loggedInOnce}');
              // Check if user has logged in before
              if (state.user.loggedInOnce) {
                print('LoginScreen: Returning user, navigating to home');
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
                print('LoginScreen: New user, navigating to confirmation');
                // Show welcome message for new user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Welcome! Please complete your profile setup.'),
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
            final topGradientColors = _getGradientColors(_themeColor);
            final bottomGradientColors = _getBottomGradientColors(_themeColor);
            
            return Stack(
              children: [
                // White base background
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                  ),
                ),
                // Top gradient (1/4 of screen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: topGradientColors,
                        stops: const [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0],
                      ),
                    ),
                  ),
                ),
                // Bottom gradient (1/3 of screen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.33,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: bottomGradientColors,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Circular shapes overlay
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _circleAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Large circle in top right
                          Positioned(
                            top: -100 + _circleAnimation.value,
                            right: -100,
                            child: Container(
                              width: WebSize.width(context, 300),
                              height: WebSize.width(context, 300),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _themeColor.withOpacity(0.15),
                              ),
                            ),
                          ),
                          // Small circle in upper left
                          Positioned(
                            top: 240 - _circleAnimation.value * 0.5,
                            left: 40,
                            child: Container(
                              width: WebSize.width(context, 120),
                              height: WebSize.width(context, 120),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _themeColor.withOpacity(0.25),
                              ),
                            ),
                          ),
                          // Small circle in lower right
                          Positioned(
                            bottom: 240 + _circleAnimation.value * 0.3,
                            right: 20,
                            child: Container(
                              width: WebSize.width(context, 50),
                              height: WebSize.width(context, 50),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _themeColor.withOpacity(0.25),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Content
                WebSafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(WebSize.width(context, 24)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            WebSize.height(context, 48),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/boy.png',
                            width: WebSize.width(context, 100),
                            height: WebSize.height(context, 170),
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: WebSize.height(context, 20)),

                          // Title
                          Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: WebSize.fontSize(context, 32),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: WebSize.height(context, 8)),

                          // Subtitle
                          Text(
                            'Sign to your account',
                            style: TextStyle(
                              fontSize: WebSize.fontSize(context, 16),
                              color: Colors.grey,
                            ),
                          ),
                        // Form section with proper spacing
                        SizedBox(height: WebSize.height(context, 10)),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: kIsWeb ? 400 : double.infinity,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  SizedBox(height: WebSize.height(context, 40)),

                                  // Admission Number Field
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Admission Number',
                                      hintText: 'XXXXXXXXXXXX',
                                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(WebSize.radius(context, 12))),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your admission number';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: WebSize.height(context, 20)),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: Icon(Icons.lock, color: Colors.grey),
                                      suffixIcon: VibrationIconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () async {
                                          // await SoundService().playButtonClick();
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                        vibrationType: VibrationType.light,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(WebSize.radius(context, 12))),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: WebSize.height(context, 30)),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: WebSize.height(context, 56),
                                    child: VibrationButton(
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
                                                    'admission_number': _emailController.text.trim(),
                                                    'timestamp': DateTime.now().toIso8601String(),
                                                  },
                                                );

                                                final fcmToken = await NotificationService().getFCMToken();
                                                final loginData = {
                                                  'username': _emailController.text.trim(),
                                                  'password': _passwordController.text,
                                                  if (fcmToken != null) 'fcm_token': fcmToken,
                                                };
                                                context.read<UserBloc>().add(LoginUser(loginData));
                                              }
                                            },
                                      vibrationType: VibrationType.success,
                                      child: state is UserLoading
                                          ? SizedBox(
                                              height: WebSize.width(context, 20),
                                              width: WebSize.width(context, 20),
                                              child: CircularProgressIndicator(
                                                strokeWidth: WebSize.width(context, 2),
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Log In',
                                              style: TextStyle(
                                                fontSize: WebSize.fontSize(context, 18),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: WebSize.height(context, 16)),

                                  // Request an account
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('GyaanBuddy Team will contact you soon!'),
                                            backgroundColor: Color(0xFF4A90E2),
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Request an account?',
                                        style: TextStyle(
                                          fontSize: WebSize.fontSize(context, 16),
                                          color: _themeColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Forgot Password Link
                                  Visibility(
                                    visible: false,
                                    child: VibrationTextButton(
                                      onPressed: () {
                                        // Forgot password functionality not implemented
                                      },
                                      vibrationType: VibrationType.light,
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom spacing
                        SizedBox(height: WebSize.height(context, 40)),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Web-specific login form with modern styling
  Widget _buildWebLoginForm() {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserAuthenticated) {
          // Track successful login
          PostHogService.capture('login_successful', properties: {
            'user_id': state.user.id.toString(),
            'user_type': state.user.userType.toString(),
            'is_new_user': !state.user.loggedInOnce,
            'timestamp': DateTime.now().toIso8601String(),
            'platform': 'web',
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

          if (state.user.loggedInOnce) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful! Welcome back!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome! Please complete your profile setup.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
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
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome text
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D29),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your learning journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Admission Number Field
                        _buildWebTextField(
                          controller: _emailController,
                          label: 'Admission Number',
                          hint: 'Enter your admission number',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your admission number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        _buildWebTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 56,
                            child: ElevatedButton(
                              onPressed: state is UserLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        // await SoundService().playButtonClick();
                                        PostHogService.capture(
                                          'login_attempted',
                                          properties: {
                                            'admission_number': _emailController.text.trim(),
                                            'timestamp': DateTime.now().toIso8601String(),
                                            'platform': 'web',
                                          },
                                        );

                                        final loginData = {
                                          'username': _emailController.text.trim(),
                                          'password': _passwordController.text,
                                        };
                                        context.read<UserBloc>().add(LoginUser(loginData));
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF365DEA),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: const Color(0xFF365DEA).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: state is UserLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Request an account
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('GyaanBuddy Team will contact you soon!'),
                                  backgroundColor: Color(0xFF365DEA),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: const Text(
                                'Request an account?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF365DEA),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Contact support
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Handle support
                            },
                            child: Text(
                              'Need help? Contact Support',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Web-specific text field with modern styling
  Widget _buildWebTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D29),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1D29),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.grey[500],
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF365DEA),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE74C3C),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
