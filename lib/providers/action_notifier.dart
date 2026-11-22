import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_exception.dart';

/// Base for providers that make one change, such as saving or deleting. The
/// state tells the UI whether the change is running or failed.
abstract class ActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Runs [action] unless one is already running. Returns null when it
  /// worked, or the error, which the state keeps as well.
  @protected
  Future<Object?> run(Future<void> Function() action) async {
    if (state.isLoading) {
      return const AppException('Still saving. Please wait a moment.');
    }
    // Finish the change even if the page that started it was closed.
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      await action();
      if (ref.mounted) state = const AsyncData(null);
      return null;
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(error, stackTrace);
      return error;
    } finally {
      link.close();
    }
  }
}
