import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import '../state/auth_cubit.dart';
import '../state/auth_state.dart';
import '../state/shop_cubit.dart';
import 'shop_screen.dart';
import 'sign_in_screen.dart';

/// Shows the sign-in screen until someone signs in, then the shop.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.products});

  final ProductRepository products;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      // Only signing in or out changes the screen, not spinners or messages.
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.user?.id != current.user?.id,
      builder: (context, state) => switch (state.status) {
        AuthStatus.unknown => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.signedOut => const SignInScreen(),
        AuthStatus.signedIn => BlocProvider(
          // Each person who signs in starts with a fresh shop state.
          key: ValueKey(state.user?.id),
          create: (_) => ShopCubit(repository: products)..load(),
          child: const ShopScreen(),
        ),
      },
    );
  }
}
