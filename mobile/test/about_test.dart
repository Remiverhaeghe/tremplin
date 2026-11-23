// Écran « À propos » : version suivie de pubspec.yaml, langue choisie, entrée du menu Plus.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/l10n/texts.dart';
import 'package:jobboard_revision/logic/app_info.dart';
import 'package:jobboard_revision/screens/about_screen.dart';
import 'package:jobboard_revision/screens/hub_tabs.dart';

import 'widget_test.dart' show buildState;

void main() {
  test('La version affichée suit celle de pubspec.yaml', () {
    final vLine = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((pLine) => pLine.startsWith('version:'));

    expect(vLine.split(':').last.trim().split('+').first, appVersion);
  });

  test('La langue choisie se lit dans la langue affichée', () {
    final vFrench = lookupAppLocalizations(const Locale('fr'));
    final vEnglish = lookupAppLocalizations(const Locale('en'));

    expect(languageName(vFrench, 'system'), 'Comme le téléphone');
    expect(languageName(vEnglish, 'system'), 'Same as the phone');
    expect(languageName(vFrench, 'en'), 'English');
  });

  testWidgets('Le menu Plus mène à l écran À propos', (pTester) async {
    final vState = await pTester.runAsync(buildState);

    await pTester.pumpWidget(MaterialApp(home: MoreTab(state: vState!, onExam: null)));
    await pTester.scrollUntilVisible(find.text('À propos'), 200);
    await pTester.tap(find.text('À propos'));
    await pTester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(find.text('Comme le téléphone'), findsOneWidget);
    expect(find.text(sourceUrl), findsOneWidget);
  });
}
