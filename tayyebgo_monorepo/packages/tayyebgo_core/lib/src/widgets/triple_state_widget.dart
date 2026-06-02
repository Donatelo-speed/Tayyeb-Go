import 'package:flutter/material.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_spacing.dart';
import '../../presentation/shared_widgets/animated_button.dart';
import 'shimmer_loading.dart';

enum TripleState { loading, error, success }

class TripleStateWidget extends StatelessWidget {
  final TripleState state;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final int shimmerItemCount;
  final bool isAuthShimmer;
  final Widget? successOverlay;
  final bool showSuccessAnimation;

  const TripleStateWidget({
    super.key,
    required this.state,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.shimmerItemCount = 3,
    this.isAuthShimmer = false,
    this.successOverlay,
    this.showSuccessAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case TripleState.loading:
        return ShimmerLoading(
          itemCount: shimmerItemCount,
          isAuthShimmer: isAuthShimmer,
        );
      case TripleState.error:
        return _buildErrorState();
      case TripleState.success:
        if (showSuccessAnimation) {
          return Stack(
            children: [
              child,
              if (successOverlay != null) successOverlay!,
            ],
          );
        }
        return child;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.15),
                    AppColors.error.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connection Lost',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong.\nPlease check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AnimatedButton(
                height: 48,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                onPressed: onRetry,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Try Again'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
