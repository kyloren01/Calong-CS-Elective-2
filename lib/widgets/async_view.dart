import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_exception.dart';
import 'message_view.dart';

/// Shows the loading, error, or data state of a provider. While newer data
/// loads, the previous data stays on screen.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.data,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    if (value.isLoading && (value.hasError || !value.hasValue)) {
      return const LoadingView();
    }
    if (value.error case final error?) {
      return ErrorView(error: error, onRetry: onRetry);
    }
    return data(value.requireValue);
  }
}

/// The same for a small part of a page, such as a row of chips.
class InlineAsyncView<T> extends StatelessWidget {
  const InlineAsyncView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.data,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    if (value.isLoading && (value.hasError || !value.hasValue)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }
    if (value.error case final error?) {
      return Notice(
        messageFor(error),
        action: TextButton(onPressed: onRetry, child: const Text('Try again')),
      );
    }
    return data(value.requireValue);
  }
}
