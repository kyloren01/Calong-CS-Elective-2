import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_form.dart';
import 'sign_up_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
  }

  void _openSignUp() {
    ref.read(authControllerProvider.notifier).clearMessages();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignUpPage()));
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isBusy;
    return AuthForm(
      formKey: _formKey,
      title: 'Log in',
      fields: [
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
          validator: (value) =>
              (value ?? '').isEmpty ? 'Enter your password' : null,
          onSubmitted: _submit,
        ),
      ],
      submitLabel: 'Log in',
      submitAction: AuthAction.signIn,
      onSubmit: _submit,
      switchLabel: 'No account yet? Sign up',
      onSwitch: _openSignUp,
    );
  }
}
