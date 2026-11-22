import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_exception.dart';
import '../models/profile.dart';
import '../providers/auth_controller.dart';
import '../providers/cart_provider.dart';
import '../providers/session_providers.dart';
import '../utils/validators.dart';
import '../widgets/async_view.dart';
import '../widgets/auth_form.dart' show ButtonSpinner;
import '../widgets/confirm_dialog.dart';
import '../widgets/message_view.dart';
import '../widgets/product_card.dart' show Pill;

/// Who is signed in, and signing out. Customers can change their name.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final items = ref.read(cartProvider).itemCount;
    if (items > 0) {
      final leave = await confirm(
        context,
        title: 'Sign out?',
        message:
            'Signing out empties your cart ($items '
            '${items == 1 ? 'item' : 'items'}).',
        confirmLabel: 'Sign out',
      );
      if (!leave) return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Signing out can fail, for example without internet.
    ref.listen(authControllerProvider.select((state) => state.error), (
      _,
      error,
    ) {
      if (error != null) showMessage(context, error);
    });
    final theme = Theme.of(context);
    final signingOut =
        ref.watch(authControllerProvider).busy == AuthAction.signOut;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: AsyncView(
        value: ref.watch(profileProvider),
        onRetry: () => ref.invalidate(profileProvider),
        data: (profile) => profile == null
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: _Details(profile: profile),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: signingOut
                              ? null
                              : () => _signOut(context, ref),
                          icon: signingOut
                              ? const ButtonSpinner()
                              : const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text(
            profile.displayName[0].toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        if (profile.email case final email? when email != profile.displayName)
          Text(
            email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 12),
        Pill(
          profile.isAdmin ? 'Admin' : 'Customer',
          background: theme.colorScheme.secondaryContainer,
          foreground: theme.colorScheme.onSecondaryContainer,
        ),
        // The database lets only customers edit their own profile.
        if (!profile.isAdmin) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final saved = await showDialog<bool>(
                context: context,
                builder: (_) => _NameDialog(profile: profile),
              );
              if (saved ?? false) showMessageOn(messenger, 'Name saved.');
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit name'),
          ),
        ],
      ],
    );
  }
}

class _NameDialog extends ConsumerStatefulWidget {
  const _NameDialog({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends ConsumerState<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.profile.firstName);
  late final _lastName = TextEditingController(text: widget.profile.lastName);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref
        .read(profileSaveProvider.notifier)
        .saveName(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
        );
    if (error == null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileSaveProvider);
    return AlertDialog(
      title: const Text('Edit name'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstName,
                enabled: !saving.isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) =>
                    Validators.required(value, 'Enter your first name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                enabled: !saving.isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (value) =>
                    Validators.required(value, 'Enter your last name'),
              ),
              if (saving.error case final error?) ...[
                const SizedBox(height: 12),
                Notice(messageFor(error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving.isLoading ? null : _save,
          child: saving.isLoading ? const ButtonSpinner() : const Text('Save'),
        ),
      ],
    );
  }
}
