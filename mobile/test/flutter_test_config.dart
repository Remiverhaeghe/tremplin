// Tests en français, quelle que soit la langue de la machine qui les lance : les textes
// attendus sont ceux de app_fr.arb.

import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() pTestMain) async {
  final vDispatcher = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
  vDispatcher
    ..localeTestValue = const Locale('fr', 'FR')
    ..localesTestValue = const [Locale('fr', 'FR')];

  await pTestMain();
}
