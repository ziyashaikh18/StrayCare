import 'package:flutter/material.dart';

/// Clips a container to a single gentle wave along its top edge - used as
/// a soft decorative band at the bottom of the login screen.
class BottomWaveClipper extends CustomClipper<Path> {
  const BottomWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.95,
      size.width * 0.52, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.78, size.height * 0.1,
      size.width, size.height * 0.45,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}