import 'package:flutter/material.dart';

/// A rounded, softly-shadowed text field used for the email/phone and
/// password inputs on the login screen. When [isPassword] is true, an
/// eye icon is shown to toggle obscuring the text.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.icon,
    required this.hintText,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = false;

  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kHint = Color(0xFFA79DB3);

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPurple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2E1A47)),
        decoration: InputDecoration(
          prefixIcon: Icon(widget.icon, color: kPurple, size: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: kPurple,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: kHint, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        ),
      ),
    );
  }
}