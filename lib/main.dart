import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'state/shop_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  late final _router = createAppRouter(onToggleTheme: _toggleTheme);

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopStore(),
      child: MaterialApp.router(
      title: 'Flutter Shopee',
      debugShowCheckedModeBanner: false,
      theme: buildShopTheme(Brightness.light),
      darkTheme: buildShopTheme(Brightness.dark),
      themeMode: _themeMode,
      routerConfig: _router,
      ),
    );
  }
}
