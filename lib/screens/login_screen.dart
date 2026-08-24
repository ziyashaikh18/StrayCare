import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'sign_up_screen.dart';
import '../widgets/app_text_field.dart';
import '../widgets/bottom_wave_clipper.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/social_login_button.dart';

/// StrayCare login screen: back button, logo/wordmark, welcome copy,
/// email + password fields, forgot-password link, login button, social
/// sign-in options, a sign-up link, and a soft decorative wave at the
/// bottom of the screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);

  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kWaveColor = Color(0xFFE9DCF3);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ),
  );
}

  void _handleGoogleSignIn() {
    // Wire up Google sign-in here.
  }

  void _handleAppleSignIn() {
    // Wire up Apple sign-in here.
  }

  void _goToSignUp() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SignUpScreen(),
    ),
  );
}

  void _goToForgotPassword() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ForgotPasswordScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Soft decorative wave along the very bottom of the screen.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: ClipPath(
              clipper: const BottomWaveClipper(),
              child: Container(color: kWaveColor),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button row.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _BackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      children: [
                        // Logo + wordmark
                        Image.asset(
                          'assets/images/logo.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),

                        const SizedBox(height: 18),

                        // Welcome copy
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: kDeepPurple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Login to continue your mission.',
                          style: TextStyle(fontSize: 14, color: kSubtitleGray),
                        ),
                        const SizedBox(height: 28),

                        // Email field
                        AppTextField(
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          hintText: 'Email or Phone',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        AppTextField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hintText: 'Password',
                          isPassword: true,
                        ),
                        const SizedBox(height: 10),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _goToForgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: kPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login button
                        PrimaryGradientButton(
                          label: 'Login',
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFDCCBE8))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                    color: kSubtitleGray, fontSize: 13),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFDCCBE8))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Social sign-in buttons
Row(
  children: [
    Expanded(
      child: SocialLoginButton(
        imagePath: 'assets/images/google.png',
        label: 'Google',
        onPressed: _handleGoogleSignIn,
      ),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: SocialLoginButton(
        icon: Icons.apple,
        label: 'Apple',
        onPressed: _handleAppleSignIn,
      ),
    ),
  ],
),
const SizedBox(height: 26),
                        // Sign up link
                        GestureDetector(
                          onTap: _goToSignUp,
                          child: RichText(
                            text: const TextSpan(
                              style:
                                  TextStyle(fontSize: 14, color: kSubtitleGray),
                              children: [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: kPurple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back, color: Color(0xFF6A3EA1), size: 20),
        ),
      ),
    );
  }
}
