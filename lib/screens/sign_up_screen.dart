import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'verify_email_screen.dart';
import '../config/api_config.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/social_login_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //========================
  // Text Controllers
  //========================
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  //========================
  // State Variables
  //========================
  bool _isTermsAccepted = false;
  bool _isSubmitting = false;

  //========================
  // App Colors
  //========================
  static const Color kBackground = Color(0xFFF7EEF9);
  static const Color kCardColor = Color(0xFFFBF8FD);

  static const Color kDeepPurple = Color(0xFF3E1E68);
  static const Color kPurple = Color(0xFF7D4BB6);
  

  static const Color kSubtitleGray = Color(0xFF8E849B);
  static const Color kBorder = Color(0xFFE9DFF3);

  static const Color kWaveColor = Color(0xFFF0E3FA);

  //========================
  // Dispose Controllers
  //========================
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //========================
  // Button Actions
  //========================
  Future<void> _handleSignUp() async {
  if (_isSubmitting) return;
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final phone = _phoneController.text.trim();
  final password = _passwordController.text;
  final confirmPassword = _confirmPasswordController.text;

  if (name.isEmpty ||
      email.isEmpty ||
      phone.isEmpty ||
      password.isEmpty ||
      confirmPassword.isEmpty) {
    _showMessage('Please fill in all fields.');
    return;
  }

  if (!_isTermsAccepted) {
    _showMessage('Please accept the Terms of Service and Privacy Policy.');
    return;
  }

  if (password != confirmPassword) {
    _showMessage('Passwords do not match.');
    return;
  }

  if (password.length < 6) {
    _showMessage('Password must contain at least 6 characters.');
    return;
  }

  setState(() => _isSubmitting = true);
  try {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (!mounted) return;
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
      );
    } else {
      _showMessage(data['message']?.toString() ?? 'Unable to create account.');
    }
  } on Exception catch (error) {
    if (mounted) _showMessage('Unable to create account: $error');
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}

void _showMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

  void _handleGoogleSignIn() {
    // TODO: Google Sign In
  }

  void _handleAppleSignIn() {
    // TODO: Apple Sign In
  }

  void _goToLogin() {
    Navigator.pop(context);
  }
  void _showTermsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Terms of Service'),
      content: const SingleChildScrollView(
        child: Text(
          '• Use StrayCare responsibly.\n\n'
          '• Do not submit fake rescue reports.\n\n'
          '• Respect other users.\n\n'
          '• We may update these terms from time to time.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showPrivacyDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacy Policy'),
      content: const SingleChildScrollView(
        child: Text(
          'We only collect the information necessary to provide StrayCare services. '
          'Your data is kept secure and is not sold to third parties.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Bottom Wave
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 170,
            child: ClipPath(
              clipper: const _BottomWaveClipper(),
              child: Container(
                color: kWaveColor,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 450,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: _BackButton(
                              onTap: () => Navigator.pop(context),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Logo Section
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const Positioned(
                                left: 12,
                                top: 35,
                                child: _PawDecoration(opacity: 0.10),
                              ),
                              const Positioned(
                                right: 12,
                                top: 35,
                                child: _PawDecoration(opacity: 0.10),
                              ),
                              Column(
                                children: [
                                  Image.asset(
  'assets/images/logo.png',
  width: 105,
  height: 105,
  fit: BoxFit.contain,
),

                                  
                                      
                                    
                                  

                                  const SizedBox(height: 16),

                                  const Text(
                                    'Create Your Account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: kDeepPurple,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  const Text(
                                    'Join us and be a part of the mission.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: kSubtitleGray,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Form Fields
                          _FieldCard(
                            child: AppTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hintText: 'Full Name',
                            ),
                          ),

                          const SizedBox(height: 14),

                          _FieldCard(
                            child: AppTextField(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              hintText: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),

                          const SizedBox(height: 14),

                          _FieldCard(
                            child: AppTextField(
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              hintText: 'Phone Number',
                              keyboardType: TextInputType.phone,
                            ),
                          ),

                          const SizedBox(height: 14),

                          _FieldCard(
                            child: AppTextField(
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              hintText: 'Password',
                              isPassword: true,
                            ),
                          ),

                          const SizedBox(height: 14),

                          _FieldCard(
                            child: AppTextField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline,
                              hintText: 'Confirm Password',
                              isPassword: true,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Terms & Conditions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.scale(
                                scale: 0.95,
                                child: Checkbox(
                                  value: _isTermsAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _isTermsAccepted = value ?? false;
                                    });
                                  },
                                  activeColor: kPurple,
                                  side: const BorderSide(
                                    color: kBorder,
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 13,
              color: kSubtitleGray,
              height: 1.4,
            ),
            children: [
              const TextSpan(
                text: 'I agree to the ',
              ),

              TextSpan(
                text: 'Terms of Service',
                style: const TextStyle(
                  color: kPurple,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = _showTermsDialog,
              ),

              const TextSpan(
                text: ' and ',
              ),

              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(
                  color: kPurple,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = _showPrivacyDialog,
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
                              

                          const SizedBox(height: 12),

                          PrimaryGradientButton(
                            label: 'Sign Up',
                            onPressed: _isSubmitting ? () {} : _handleSignUp,
                          ),

                          const SizedBox(height: 20),

                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFDCCBE8),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: kSubtitleGray,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFDCCBE8),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

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

                          const SizedBox(height: 22),

                          GestureDetector(
                            onTap: _goToLogin,
                            child: const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kSubtitleGray,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Already have an account? ',
                                  ),
                                  TextSpan(
                                    text: 'Login',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.arrow_back,
            color: Color(0xFF7D4BB6),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PawDecoration extends StatelessWidget {
  const _PawDecoration({
    required this.opacity,
  });

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: const Icon(
        Icons.pets,
        color: Color(0xFF7D4BB6),
        size: 34,
      ),
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  const _BottomWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.25);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.05,
      size.width * 0.5,
      size.height * 0.22,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.38,
      size.width,
      size.height * 0.18,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}