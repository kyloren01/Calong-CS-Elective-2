/// The Supabase project to connect to, read at build time so the key stays
/// out of git.
///
/// Put the values in `supabase.json` (gitignored) and run:
///   flutter run --dart-define-from-file=supabase.json
/// The VS Code launch configuration in `.vscode/launch.json` does this for you.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');

  /// The publishable key (`sb_publishable_...`) or the legacy anon key.
  /// Never use the secret or service_role key in an app.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// The deep link that brings Android and iOS back from the GitHub sign-in
  /// page. It is registered in AndroidManifest.xml and Info.plist, and must
  /// be added to Supabase under Authentication → URL Configuration.
  static const mobileRedirectUrl = 'io.supabase.shopping://login-callback/';
}
