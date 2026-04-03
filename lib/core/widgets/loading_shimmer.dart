import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading placeholder
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius,
    this.isCircle = false,
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
          borderRadius: isCircle
              ? null
              : borderRadius ?? BorderRadius.circular(8),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// Shimmer for text loading
class TextShimmer extends StatelessWidget {
  final double width;
  final double height;
  final int lines;

  const TextShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
          child: LoadingShimmer(
            width: index < lines - 1 ? width : width * 0.7,
            height: height,
          ),
        ),
      ),
    );
  }
}

/// Shimmer for score card loading
class ScoreCardShimmer extends StatelessWidget {
  const ScoreCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            LoadingShimmer(
              width: double.infinity,
              height: 150,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),
            // Score circle
            const LoadingShimmer(
              width: 120,
              height: 120,
              isCircle: true,
            ),
            const SizedBox(height: 24),
            // Dimension bars
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoadingShimmer(
                      width: 200,
                      height: 16,
                    ),
                    const SizedBox(height: 8),
                    LoadingShimmer(
                      width: double.infinity,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // Strengths section
            LoadingShimmer(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),
            // Suggestions section
            LoadingShimmer(
              width: double.infinity,
              height: 150,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for image loading
class ImageShimmer extends StatelessWidget {
  final double width;
  final double height;

  const ImageShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
