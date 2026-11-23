// Captures d'écran de l'appli mobile sur des données fictives, pour le README et le
// portfolio. Lancées par le workflow Captures ; les PNG sortent dans test/captures/png.
@Tags(['captures'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/main.dart';
import 'package:jobboard_revision/screens/dive_log_screen.dart';
import 'package:jobboard_revision/screens/dive_result_screen.dart';

import '../widget_test.dart' show buildState;

/// Polices de Flutter : sans elles, les tests dessinent des carrés à la place du texte.
Future<void> loadFonts() async {
  final vRoot = Platform.environment['FLUTTER_ROOT'];
  if (vRoot == null) {
    fail('FLUTTER_ROOT doit pointer vers le SDK Flutter pour charger les polices');
  }
  final vFiles =
      Directory('$vRoot/bin/cache/artifacts/material_fonts').listSync().whereType<File>().toList();
  ByteData vRead(File pFile) => ByteData.sublistView(pFile.readAsBytesSync());
  bool vNamed(File pFile, String pStart) =>
      pFile.uri.pathSegments.last.toLowerCase().startsWith(pStart);

  final vRoboto = FontLoader('Roboto');
  for (final vFile in vFiles.where((pFile) => vNamed(pFile, 'roboto-'))) {
    vRoboto.addFont(Future.value(vRead(vFile)));
  }
  await vRoboto.load();
  final vIcons = FontLoader('MaterialIcons')
    ..addFont(Future.value(vRead(vFiles.firstWhere((pFile) => vNamed(pFile, 'materialicons')))));
  await vIcons.load();
}

Future<void> capture(String pName) =>
    expectLater(find.byType(MaterialApp).first, matchesGoldenFile('png/$pName.png'));

/// Laisse passer les animations sans attendre qu'elles s'arrêtent : certaines tournent en boucle.
Future<void> settle(WidgetTester pTester) async {
  for (var vStep = 0; vStep < 20; vStep++) {
    await pTester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadFonts);

  testWidgets('accueil, bilan de plongée et carnet de la semaine', (pTester) async {
    // Écran d'un téléphone courant : 1080 × 2340 pixels
    pTester.view.physicalSize = const Size(1080, 2340);
    pTester.view.devicePixelRatio = 3;
    addTearDown(pTester.view.reset);
    debugDisableShadows = false;

    final vToday = DateTime(2026, 11, 20);
    final vState = await pTester.runAsync(() async {
      final rState = await buildState();
      // Une semaine de révision fictive, avec un jour sans
      const vAnswers = {16: (6, 5), 17: (9, 6), 18: (4, 4), 20: (7, 6), 10: (5, 3), 12: (3, 2)};
      for (final MapEntry(key: vDay, value: (vCount, vRight)) in vAnswers.entries) {
        for (var vIndex = 0; vIndex < vCount; vIndex++) {
          await rState.recordDive(vIndex < vRight, pAt: DateTime(2026, 11, vDay, 9, vIndex));
        }
      }
      return rState;
    });

    await pTester.pumpWidget(RevisionApp(state: vState!));
    await settle(pTester);
    await capture('mobile-accueil');

    final vNavigator = pTester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(
      vNavigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const DiveResultScreen(
            title: 'Docker',
            dive: (answered: 8, correct: 7, before: 1.2, after: 1.9),
          ),
        ),
      ),
    );
    await settle(pTester);
    await capture('mobile-bilan-plongee');
    vNavigator.pop();
    await settle(pTester);

    unawaited(
      vNavigator.push(
        MaterialPageRoute<void>(builder: (_) => DiveLogScreen(state: vState, today: vToday)),
      ),
    );
    await settle(pTester);
    await capture('mobile-carnet-plongee');
    // Remis avant le contrôle des variables de dessin, fait avant les addTearDown
    debugDisableShadows = true;
  });
}
