import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Centered icon + message with optional retry. Used for error and empty states.
class MessageView extends StatelessWidget {
  const MessageView({
    required this.icon,
    required this.message,
    this.onRetry,
    super.key,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
