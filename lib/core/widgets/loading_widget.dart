import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SurakshaLoading extends StatelessWidget {
  final double size;
  const SurakshaLoading({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'लोड हुँदैछ...', 
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class SurakshaShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SurakshaShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
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
}
