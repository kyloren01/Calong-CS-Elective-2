import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../../providers/session_providers.dart';
import '../../widgets/message_view.dart';
import '../admin/admin_shell.dart';
import '../customer/customer_shell.dart';
import 'login_page.dart';

/// Decides what the app shows: the login page, the customer's shop, or the
/// admin's tools. It follows the session and the role in the profile.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.hasValue) {
      return Scaffold(
        body: session.hasError && !session.isLoading
            ? ErrorView(
                error: session.error!,
                onRetry: () => ref.invalidate(sessionProvider),
              )
            : const LoadingView(),
      );
    }
    final user = session.value;
    if (user == null) return const LoginPage();

    final loaded = ref.watch(profileProvider);
    final profile = loaded.value;
    // While a profile loads or fails, Riverpod still remembers the previous
    // one. It only counts when it belongs to the person signed in now.
    if (profile != null && profile.id == user.id) {
      return profile.isAdmin
          ? AdminShell(key: ValueKey(profile.id))
          : CustomerShell(key: ValueKey(profile.id));
    }
    return Scaffold(
      body: switch (loaded) {
        AsyncValue(isLoading: true) => const LoadingView(
          label: 'Opening the shop…',
        ),
        AsyncValue(:final error?) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileProvider),
          secondaryAction: const _SignOutButton(),
        ),
        _ => MessageView(
          icon: Icons.person_off_outlined,
          title: 'No profile found',
          message:
              'Your account has no profile yet. Run supabase/final_exam.sql '
              'in the Supabase SQL Editor, then try again.',
          action: FilledButton(
            onPressed: () => ref.invalidate(profileProvider),
            child: const Text('Try again'),
          ),
          secondaryAction: const _SignOutButton(),
        ),
      },
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: ref.read(authControllerProvider.notifier).signOut,
    child: const Text('Sign out'),
  );
}
