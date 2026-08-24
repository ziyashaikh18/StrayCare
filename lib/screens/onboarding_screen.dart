import 'package:flutter/material.dart';

import '../widgets/gradient_action_button.dart';
import 'login_screen.dart';

/// StrayCare "Get Started" onboarding screen.
/// The paw prints, cat, curved panel, tagline and page-indicator dots are
/// all part of the single background artwork. This widget only floats the
/// logo/wordmark near the top and the CTA button + sign-in link near the
/// bottom on top of it.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPink = Color(0xFFEC4A7A);

  void _goToLogin(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    

    return Scaffold(
      body: Stack(
        children: [
          // Background artwork: paw prints, cat, curved panel, tagline,
          // and page-indicator dots are all baked into this single image.
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Logo + wordmark, floated over the blank space at the top.
          Positioned(
  top: 80,
  left: 0,
  right: 0,
  child: Center(
    child: Image.asset(
      'assets/images/logo.png',
      width: 150,
      height: 150,
    ),
  ),
),

          // CTA button + sign-in link, floated over the blank purple
          // space at the bottom of the background artwork.
          Positioned(
            left: 24,
            right: 24,
            bottom: size.height * 0.05,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientActionButton(
  label: 'Get Started',
  onPressed: () => _goToLogin(context),
),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _goToLogin(context),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      children: [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(
                            color: kPink,
                            fontWeight: FontWeight.w600,
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

