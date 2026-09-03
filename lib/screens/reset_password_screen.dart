import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (code.isEmpty || password.length < 6) {
      _message('Enter the reset code and a password of at least 6 characters.');
      return;
    }
    if (password != _confirmController.text) {
      _message('Passwords do not match.');
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': widget.email,
              'code': code,
              'newPassword': password,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _message(data['message']?.toString() ?? 'Password reset successfully.');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      } else {
        _message(data['message']?.toString() ?? 'Password reset failed.');
      }
    } on Exception catch (error) {
      if (mounted) _message('Unable to reset password: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FA),
      appBar: AppBar(title: const Text('Reset Password'), backgroundColor: Colors.transparent, foregroundColor: const Color(0xFF2E1A47)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Enter the reset code sent to ${widget.email}.', style: const TextStyle(color: Color(0xFF8D8398))),
          const SizedBox(height: 20),
          _field(_codeController, 'Reset Code'),
          _field(_passwordController, 'New Password', password: true),
          _field(_confirmController, 'Confirm Password', password: true),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submitting ? null : _reset, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6A3EA1), padding: const EdgeInsets.symmetric(vertical: 15)), child: Text(_submitting ? 'Resetting...' : 'Reset Password')),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool password = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          obscureText: password,
          keyboardType: password ? TextInputType.text : TextInputType.number,
          decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
        ),
      );
}
