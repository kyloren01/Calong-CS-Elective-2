import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/supabase_config.dart';
import 'pages/auth/auth_gate.dart';
import 'pages/setup_page.dart';
import 'providers/session_providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(const SetupApp());
    return;
  }
  try {
    // Also finishes a Google sign-in when the browser returns to the app.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (error) {
    runApp(SetupApp(problem: 'Supabase could not start: $error'));
    return;
  }
  runApp(
    const ProviderScope(
      // Riverpod would silently retry failed loads for a while. Showing the
      // error with a "Try again" button is clearer.
      retry: noRetry,
      child: ShopApp(),
    ),
  );
}

Duration? noRetry(int retryCount, Object error) => null;

class ShopApp extends ConsumerStatefulWidget {
  const ShopApp({super.key});

  @override
  ConsumerState<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends ConsumerState<ShopApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Followed from here because pages under another page stop listening.
    // When the session ends, pages opened on top of the shop must close.
    ref.listen(userIdProvider, (previous, next) {
      if (previous != next) {
        _navigator.currentState?.popUntil((route) => route.isFirst);
      }
    });

    return MaterialApp(
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      title: AppConfig.name,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const AuthGate(),
    );
  }
}
