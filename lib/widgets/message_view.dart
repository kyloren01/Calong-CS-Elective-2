import 'package:flutter/material.dart';

import '../models/app_exception.dart';

/// A centred icon, title, and text, for empty and error states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.secondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
              if (secondaryAction != null) ...[
                const SizedBox(height: 8),
                secondaryAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (label case final label?) ...[
          const SizedBox(height: 16),
          Text(label),
        ],
      ],
    ),
  );
}

/// A failure that takes the place of the content. Permission, connection,
/// and other problems each look and read differently.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.secondaryAction,
  });

  final Object error;
  final VoidCallback? onRetry;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final (icon, title) = switch (errorKindOf(error)) {
      AppErrorKind.permissionDenied => (
        Icons.lock_outline_rounded,
        'Permission denied',
      ),
      AppErrorKind.network => (Icons.cloud_off_rounded, 'No connection'),
      _ => (Icons.error_outline_rounded, 'Something went wrong'),
    };
    return MessageView(
      icon: icon,
      title: title,
      message: messageFor(error),
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
      secondaryAction: secondaryAction,
    );
  }
}

/// Shown when a page is opened without the right role.
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key});

  @override
  Widget build(BuildContext context) => MessageView(
    icon: Icons.lock_outline_rounded,
    title: 'Permission denied',
    message: 'Only admins can open this page.',
    action: Navigator.of(context).canPop()
        ? FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go back'),
          )
        : null,
  );
}

/// A coloured box for a message inside a form or page.
class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.isError = true, this.action});

  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// A short message at the bottom of the screen.
void showMessage(BuildContext context, String message) =>
    showMessageOn(ScaffoldMessenger.of(context), message);

/// The same, for use after waiting for something.
void showMessageOn(ScaffoldMessengerState messenger, String message) =>
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
