import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_flutter_ui/main.dart' show noRetry;
import 'package:my_first_flutter_ui/providers/session_providers.dart';

import 'fake_backend.dart';

/// Providers connected to [backend], with the session followed the way the
/// app's root widget does.
Future<ProviderContainer> openContainer(FakeBackend backend) async {
  final container = ProviderContainer.test(
    overrides: backend.overrides,
    retry: noRetry,
  );
  container.listen(userIdProvider, (_, _) {});
  await container.read(sessionProvider.future);
  return container;
}

/// Lets waiting stream events and timers run.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));
