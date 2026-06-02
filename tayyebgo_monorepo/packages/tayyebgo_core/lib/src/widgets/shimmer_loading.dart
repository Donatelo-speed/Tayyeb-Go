import 'package:flutter/material.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_spacing.dart';

class ShimmerLoading extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;
  final bool isAuthShimmer;

  const ShimmerLoading({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 88,
    this.padding = const EdgeInsets.all(16),
    this.isAuthShimmer = false,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAuthShimmer) {
      return _buildAuthShimmer();
    }
    return ListView.builder(
      padding: widget.padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.itemCount,
      itemBuilder: (_, i) => _buildShimmerCard(),
    );
  }

  Widget _buildAuthShimmer() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _shimmerCircle(80),
            const SizedBox(height: 24),
            _shimmerLine(180, 20),
            const SizedBox(height: 8),
            _shimmerLine(140, 14),
            const SizedBox(height: 40),
            _shimmerBox(double.infinity, 52, 16),
            const SizedBox(height: 16),
            _shimmerBox(double.infinity, 52, 16),
            const SizedBox(height: 24),
            _shimmerBox(double.infinity, 52, 16),
            const SizedBox(height: 24),
            _shimmerLine(140, 14),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          _shimmerBox(44, 44, 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerLine(140, 14),
                const SizedBox(height: 8),
                _shimmerLine(200, 12),
              ],
            ),
          ),
          _shimmerBox(60, 20, 6),
        ]),
      ),
    );
  }

  Widget _shimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(-_animation.value, 0),
          end: Alignment(_animation.value, 0),
          colors: [
            AppColors.divider.withValues(alpha: 0.3),
            AppColors.divider.withValues(alpha: 0.6),
            AppColors.divider.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, double radius) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-_animation.value, 0),
          end: Alignment(_animation.value, 0),
          colors: [
            AppColors.divider.withValues(alpha: 0.3),
            AppColors.divider.withValues(alpha: 0.6),
            AppColors.divider.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLine(double w, double h) {
    return _shimmerBox(w, h, 4);
  }
}
