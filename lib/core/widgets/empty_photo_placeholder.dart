import 'package:flutter/material.dart';
import 'package:styleiq/core/theme/app_theme.dart';

/// Dashed-border placeholder shown when no photo has been selected yet.
class EmptyPhotoPlaceholder extends StatelessWidget {
  final String message;
  final IconData icon;
  final double height;

  const EmptyPhotoPlaceholder({
    super.key,
    required this.message,
    this.icon = Icons.image_outlined,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mediumGrey.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppTheme.mediumGrey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mediumGrey),
            ),
          ),
        ],
      ),
    );
  }
}
