import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_form.dart';

/// Creates an email account. Every new account starts as a customer: the
/// database trigger decides the role, so it can't be chosen here.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signUp(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  void _backToLogin() {
    ref.read(authControllerProvider.notifier).clearMessages();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isBusy;
    return AuthForm(
      formKey: _formKey,
      title: 'Sign up',
      fields: [
        TextFormField(
          controller: _firstName,
          enabled: !busy,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, 'Enter your first name'),
          decoration: const InputDecoration(
            labelText: 'First name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        TextFormField(
          controller: _lastName,
          enabled: !busy,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.familyName],
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, 'Enter your last name'),
          decoration: const InputDecoration(
            labelText: 'Last name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        TextFormField(
          controller: _email,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          validator: Validators.email,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        PasswordField(
          controller: _password,
          label: 'Password',
          enabled: !busy,
          autofillHint: AutofillHints.newPassword,
          validator: Validators.newPassword,
        ),
        PasswordField(
          controller: _repeat,
          label: 'Repeat password',
          enabled: !busy,
          autofillHint: AutofillHints.newPassword,
          validator: (value) =>
              value == _password.text ? null : 'The passwords are different',
          onSubmitted: _submit,
        ),
      ],
      submitLabel: 'Create account',
      submitAction: AuthAction.signUp,
      onSubmit: _submit,
      switchLabel: 'Already have an account? Log in',
      onSwitch: _backToLogin,
    );
  }
}
