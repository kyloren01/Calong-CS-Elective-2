import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../providers/auth_controller.dart';
import 'brand.dart';
import 'message_view.dart';

/// The frame the login and sign-up pages share: the brand, the page's own
/// fields, the Google button, and any message from Supabase.
class AuthForm extends ConsumerWidget {
  const AuthForm({
    super.key,
    required this.formKey,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.submitAction,
    required this.onSubmit,
    required this.switchLabel,
    required this.onSwitch,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final List<Widget> fields;
  final String submitLabel;

  /// Which action shows its spinner on the submit button.
  final AuthAction submitAction;
  final VoidCallback onSubmit;

  /// Such as "No account yet? Sign up".
  final String switchLabel;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final googleAvailable = controller.googleAvailable;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark(size: 64)),
                  const SizedBox(height: 16),
                  Text(
                    AppConfig.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(title, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 16),
                          for (final field in fields) ...[
                            field,
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 4),
                          FilledButton(
                            onPressed: state.isBusy ? null : onSubmit,
                            child: state.busy == submitAction
                                ? const ButtonSpinner()
                                : Text(submitLabel),
                          ),
                          const SizedBox(height: 16),
                          const _OrDivider(),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: state.isBusy || !googleAvailable
                                ? null
                                : controller.signInWithGoogle,
                            icon: state.busy == AuthAction.google
                                ? const ButtonSpinner()
                                : const GoogleLogo(),
                            label: const Text('Continue with Google'),
                          ),
                          if (!googleAvailable) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Google sign-in works in the web and mobile '
                              'versions. Use email here.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state.error case final error?) ...[
                    const SizedBox(height: 16),
                    Notice(error),
                  ],
                  if (state.info case final info?) ...[
                    const SizedBox(height: 16),
                    Notice(info, isError: false),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isBusy ? null : onSwitch,
                    child: Text(switchLabel),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: Theme.of(context).textTheme.bodySmall),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

/// A password box with a show/hide button.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.enabled = true,
    this.autofillHint = AutofillHints.password,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String? value) validator;
  final bool enabled;
  final String autofillHint;

  /// Set on the last field, so Enter submits the form.
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: !_visible,
    autofillHints: [widget.autofillHint],
    textInputAction: widget.onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    validator: widget.validator,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: _visible ? 'Hide password' : 'Show password',
        onPressed: () => setState(() => _visible = !_visible),
        icon: Icon(
          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
  );
}

/// A small spinner that fits inside a button.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
