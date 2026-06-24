import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget jobCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(width: 180, height: 20),
          SizedBox(height: 10),
          ShimmerLoader(width: 80, height: 24),
          SizedBox(height: 10),
          ShimmerLoader(width: 140, height: 16),
          SizedBox(height: 20),
          ShimmerLoader(width: double.infinity, height: 48, borderRadius: 8),
        ],
      ),
    );
  }

  static Widget profileSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ShimmerLoader(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 16),
          const ShimmerLoader(width: 150, height: 24),
          const SizedBox(height: 8),
          const ShimmerLoader(width: 120, height: 16),
          const SizedBox(height: 32),
          const ShimmerLoader(
              width: double.infinity, height: 80, borderRadius: 16),
          const SizedBox(height: 24),
          ...List.generate(
              5,
              (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerLoader(
                        width: double.infinity, height: 60, borderRadius: 12),
                  )),
        ],
      ),
    );
  }
}
