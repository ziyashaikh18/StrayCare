import 'package:flutter/material.dart';

/// A simple 3-dot page indicator with a highlighted active dot.
class PageIndicatorDots extends StatelessWidget {
  const PageIndicatorDots({
    super.key,
    this.count = 3,
    this.activeIndex = 1,
    this.activeColor = const Color(0xFFEC4A7A),
    this.inactiveColor = const Color(0x66FFFFFF),
  });

  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 9,
          width: isActive ? 24 : 9,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}