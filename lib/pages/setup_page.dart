import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/message_view.dart';

/// Shown instead of the shop when the Supabase URL or key is missing.
class SetupApp extends StatelessWidget {
  const SetupApp({super.key, this.problem});

  /// Why Supabase could not start, if it was configured but failed.
  final String? problem;

  static const _steps = [
    'Open supabase.json in the project folder. If it is missing, copy '
        'supabase.example.json.',
    'Paste the Project URL and the publishable key from the Connect button '
        'in the Supabase dashboard.',
    'Run: flutter run --dart-define-from-file=supabase.json\n'
        'In VS Code, press F5 instead.',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
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
                        const BrandMark(size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Connect to Supabase',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The shop needs your Supabase project URL and '
                          'publishable (anon) key.',
                        ),
                        const SizedBox(height: 20),
                        for (final (index, step) in _steps.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  child: Text(
                                    '${index + 1}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: SelectableText(step)),
                              ],
                            ),
                          ),
                        if (problem case final problem?) Notice(problem),
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
