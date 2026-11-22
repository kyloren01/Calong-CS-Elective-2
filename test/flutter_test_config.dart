import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file. Loads the app's own font, so texts have
/// their real width and layout problems show up in the tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final font = FontLoader('Plus Jakarta Sans');
  for (final weight in [400, 600, 700, 800]) {
    final file = File('assets/fonts/PlusJakartaSans-$weight.ttf');
    font.addFont(
      file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
    );
  }
  await font.load();
  await testMain();
}
