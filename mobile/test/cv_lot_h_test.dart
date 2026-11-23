// Lot H du CV : tout consultable et exportable hors ligne.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_answers.dart';
import 'package:jobboard_revision/logic/cv_dossier.dart';
import 'package:jobboard_revision/logic/cv_letter.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_backup_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

void main() {
  test('le dossier réunit parcours, versions, candidatures et modèles', () {
    final vText = buildDossier(
      pProfile: sampleProfile,
      pVersions: [sampleVersion],
      pSent: [
        {
          'at': '2026-11-20T09:00:00',
          'company': 'Exemple SA',
          'title': 'Développeur',
          'version': 'Développeur',
          'outcome': 'entretien'
        },
      ],
      pKit: const LetterKit(),
      pAnswers: startingAnswers(sampleProfile),
      pNow: DateTime(2026, 11, 23),
    );

    expect(vText, contains('Dossier CV de Camille Durand'));
    expect(vText, contains('==== Version : Développeur ===='));
    expect(vText, contains('2026-11-20 · Exemple SA · Développeur · CV Développeur · entretien'));
    expect(vText, contains('==== Modèles de lettre ===='));
    expect(vText, contains('==== Réponses aux formulaires ===='));
  });

  test('le code du CV n\'ouvre aucune connexion réseau', () {
    final vFiles = [
      ...Directory('lib/logic')
          .listSync()
          .whereType<File>()
          .where((pFile) => pFile.path.contains('cv_')),
      ...Directory('lib/screens')
          .listSync()
          .whereType<File>()
          .where((pFile) => pFile.path.contains('cv_')),
      ...Directory('lib/state')
          .listSync()
          .whereType<File>()
          .where((pFile) => pFile.path.contains('cv_')),
    ];

    expect(vFiles, isNotEmpty);
    for (final vFile in vFiles) {
      final vSource = vFile.readAsStringSync();

      expect(vSource, isNot(contains('package:http')), reason: vFile.path);
      expect(vSource, isNot(contains('HttpClient')), reason: vFile.path);
      expect(vSource, isNot(contains('api_client')), reason: vFile.path);
    }
  });

  testWidgets('l\'écran exporte le dossier en texte', (pTester) async {
    pTester.view
      ..physicalSize = const Size(900, 4000)
      ..devicePixelRatio = 1;
    addTearDown(pTester.view.reset);
    final vState = RevisionState(MemoryRevisionStore(), reminders: FakeReminders());
    await vState.load();
    await vState.importCvProfile(jsonEncode(sampleProfile.toJson()));
    final vSent = <String>[];

    await pTester.pumpWidget(
      MaterialApp(
        home: CvBackupScreen(
          state: vState,
          send: (pBytes, pName, _) async => vSent.add('$pName|${utf8.decode(pBytes)}'),
        ),
      ),
    );
    await pTester.tap(find.text('Exporter tout en texte'));
    await pTester.pumpAndSettle();

    expect(vSent.single, startsWith('cv-dossier.txt|Dossier CV de Camille Durand'));
  });
}
