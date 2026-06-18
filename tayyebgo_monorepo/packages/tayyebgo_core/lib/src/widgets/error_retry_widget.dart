import 'package:flutter/material.dart';
import '../theme/tayyebgo_theme.dart';
import '../../presentation/theme/app_radius.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: TayyebGoTheme.errorColor),
            ),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TayyebGoTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(message,
                style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TayyebGoTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
