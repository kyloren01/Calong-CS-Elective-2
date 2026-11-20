import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/product_repository.dart';
import 'data/supabase_product_repository.dart';
import 'screens/setup_required_screen.dart';
import 'screens/shop_screen.dart';
import 'state/shop_cubit.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(const SetupRequiredApp());
    return;
  }
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (error) {
    runApp(SetupRequiredApp(problem: 'Supabase could not start: $error'));
    return;
  }
  runApp(
    ShopApp(repository: SupabaseProductRepository(Supabase.instance.client)),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key, required this.repository});

  /// Supabase in the app, an in-memory fake in tests.
  final ProductRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopCubit(repository: repository)..load(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shopping',
        theme: buildShopTheme(Brightness.light),
        darkTheme: buildShopTheme(Brightness.dark),
        home: const ShopScreen(),
      ),
    );
  }
}
