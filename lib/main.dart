import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'fruit_list.dart';

// GoRouter Configuration with Nested Sub-routes
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const FruitListPage();
      },
      // Nested sub-route under '/' -> resolves to '/fruit/:name'
      routes: <RouteBase>[
        GoRoute(
          path: 'fruit/:name',
          builder: (BuildContext context, GoRouterState state) {
            final name = state.pathParameters['name'] ?? 'Unknown';
            return FruitDetailPage(fruitName: name);
          },
        ),
      ],
    ),
  ],
);

void main() {
  runApp(const MyApp());
}

// App entry widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fruit Router App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
