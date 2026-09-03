import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../widgets/app_text_field.dart';
import '../widgets/bottom_wave_clipper.dart';
import '../widgets/primary_gradient_button.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;

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

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _message('Enter your email address.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _message(data['message']?.toString() ?? 'Reset code requested.');
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)));
      } else {
        _message(data['message']?.toString() ?? 'Could not request a reset code.');
      }
    } on Exception catch (error) {
      if (mounted) _message('Unable to request reset code: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                          onPressed: _isSubmitting ? () {} : _sendResetLink,
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