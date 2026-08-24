import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    this.icon,
    this.imagePath,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  final IconData? icon;
  final String? imagePath;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  static const Color kDeepPurple = Color(0xFF2E1A47);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE7DEF0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  width: 22,
                  height: 22,
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? kDeepPurple,
                ),

              const SizedBox(width: 8),

              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kDeepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}