import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/auth_repository.dart';
import 'data/product_repository.dart';
import 'data/supabase_auth_repository.dart';
import 'data/supabase_product_repository.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_required_screen.dart';
import 'state/auth_cubit.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(const SetupRequiredApp());
    return;
  }
  try {
    // Also finishes a GitHub sign-in when the browser returns to the app.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (error) {
    runApp(SetupRequiredApp(problem: 'Supabase could not start: $error'));
    return;
  }
  final client = Supabase.instance.client;
  runApp(
    ShopApp(
      auth: SupabaseAuthRepository(client.auth),
      products: SupabaseProductRepository(client),
    ),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key, required this.auth, required this.products});

  /// Supabase in the app, in-memory fakes in tests.
  final AuthRepository auth;
  final ProductRepository products;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(repository: auth)..start(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shopping',
        theme: buildShopTheme(Brightness.light),
        darkTheme: buildShopTheme(Brightness.dark),
        home: AuthGate(products: products),
      ),
    );
  }
}
