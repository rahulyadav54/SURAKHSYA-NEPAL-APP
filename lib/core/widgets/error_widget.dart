import 'package:flutter/material.dart';
import 'custom_button.dart';

class SurakshaErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool isFullScreen;

  const SurakshaErrorWidget({
    super.key,
    this.title = 'केही गल्ती भयो', 
    required this.message,
    this.onRetry,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: isFullScreen ? 60 : 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: (isFullScreen
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SurakshaButton(
                text: 'पुनः प्रयास गर्नुहोस्', 
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        body: SafeArea(child: content),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.05),
      child: content,
    );
  }
}
