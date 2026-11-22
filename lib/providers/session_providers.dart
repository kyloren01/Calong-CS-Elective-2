import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_user.dart';
import '../models/profile.dart';
import 'action_notifier.dart';
import 'service_providers.dart';

/// The signed-in account, kept in sync with Supabase Auth. Null when signed
/// out. Riverpod cancels the subscription when the app closes.
final sessionProvider = StreamProvider<SessionUser?>(
  (ref) => ref.watch(authServiceProvider).userChanges,
);

/// Who is signed in. Everything that belongs to one person (cart, orders,
/// filters) watches this, so it starts fresh when someone else signs in.
/// Token refreshes don't change it.
final userIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider).value?.id,
);

/// The signed-in person's profile and role, or null when there is none.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return ref.watch(profileServiceProvider).fetchProfile(userId);
});

/// Whether admin controls may be shown. While a new person's profile is
/// still loading, the previous person's role must not count.
///
/// Hiding controls is only for convenience: Row Level Security is what
/// really stops a customer from changing the catalog.
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider).value;
  return profile != null &&
      profile.isAdmin &&
      profile.id == ref.watch(userIdProvider);
});

/// Saves the customer's own name.
final profileSaveProvider =
    NotifierProvider.autoDispose<ProfileSaveNotifier, AsyncValue<void>>(
      ProfileSaveNotifier.new,
    );

class ProfileSaveNotifier extends ActionNotifier {
  Future<Object?> saveName({
    required String firstName,
    required String lastName,
  }) => run(() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref
        .read(profileServiceProvider)
        .updateName(userId, firstName: firstName, lastName: lastName);
    if (ref.mounted) ref.invalidate(profileProvider);
  });
}
