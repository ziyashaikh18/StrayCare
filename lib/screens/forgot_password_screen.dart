import 'package:flutter/material.dart';

import '../widgets/app_text_field.dart';
import '../widgets/bottom_wave_clipper.dart';
import '../widgets/primary_gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kWaveColor = Color(0xFFE9DCF3);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    // TODO: Implement password reset
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: kBackground,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Container(color: kBackground),

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
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - bottomPadding,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.white,
                            elevation: 2,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: kPurple,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 110,
                            height: 110,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Forgot Password?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: kDeepPurple,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Don't worry! Enter your email address\nand we'll send you a password reset link.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kSubtitleGray,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 35),

                        AppTextField(
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          hintText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 30),

                        PrimaryGradientButton(
                          label: 'Send Reset Link',
                          onPressed: _sendResetLink,
                        ),

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Center(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kSubtitleGray,
                                ),
                                children: [
                                  TextSpan(text: 'Remember your password? '),
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: kPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}