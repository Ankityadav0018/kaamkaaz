import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final double borderRadius;

  const BrandLogo({
    super.key,
    this.size = 40,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(size * 0.15), // Add 15% padding to zoom out
          child: Image.asset(
            'assets/images/kaamkaaz_app_icon.png',
            fit: BoxFit.contain,
            width: size,
            height: size,
          ),
        ),
      ),
    );
  }
}
