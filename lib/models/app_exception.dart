enum AppErrorKind {
  /// Row Level Security (or a missing privilege) refused the request.
  permissionDenied,

  /// Supabase could not be reached in time.
  network,

  /// The database refused the values, for example not enough stock.
  rejected,

  unknown,
}

/// A failure whose [message] can be shown to the person using the app.
class AppException implements Exception {
  const AppException(this.message, {this.kind = AppErrorKind.unknown});

  final String message;
  final AppErrorKind kind;

  @override
  String toString() => message;
}

/// The text to show for any error.
String messageFor(Object error) =>
    error is AppException ? error.message : 'Something went wrong: $error';

AppErrorKind errorKindOf(Object error) =>
    error is AppException ? error.kind : AppErrorKind.unknown;
