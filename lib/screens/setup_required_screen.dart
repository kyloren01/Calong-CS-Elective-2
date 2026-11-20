import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown instead of the shop when the Supabase URL or key is missing.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key, this.problem});

  /// Why Supabase could not start, if it was configured but failed.
  final String? problem;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopping',
      theme: buildShopTheme(Brightness.light),
      darkTheme: buildShopTheme(Brightness.dark),
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.storage_rounded,
                          size: 48,
                          color: AppColors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connect to Supabase',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The shop needs your Supabase project URL and '
                          'publishable (anon) key.',
                        ),
                        const SizedBox(height: 16),
                        const _Step(
                          number: 1,
                          text:
                              'Open supabase.json in the project folder. If it '
                              'is missing, copy supabase.example.json.',
                        ),
                        const _Step(
                          number: 2,
                          text:
                              'Paste the Project URL and the publishable key '
                              'from the Connect button in the Supabase '
                              'dashboard.',
                        ),
                        const _Step(
                          number: 3,
                          text:
                              'Run: flutter run --dart-define-from-file=supabase.json\n'
                              'In VS Code, press F5 instead.',
                        ),
                        if (problem != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            problem!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: SelectableText(text)),
      ],
    ),
  );
}
