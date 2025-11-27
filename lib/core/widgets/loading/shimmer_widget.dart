import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../app/colors.dart';

/// A shimmer effect widget for loading states
class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  }) : shape = null;

  const ShimmerWidget.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = const CircleBorder();

  const ShimmerWidget.custom({
    super.key,
    required this.width,
    required this.height,
    required this.shape,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
    final highlightColor = isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: baseColor,
          shape: shape ?? RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

/// A container with shimmer loading effect
class ShimmerContainer extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerContainer({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
    final highlightColor = isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
