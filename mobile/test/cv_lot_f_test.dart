// Lot F du CV : textes des supports publics, modèles par secteur, cohérence avec le parcours.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_supports.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_supports_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

void main() {
  group('texte du profil GitHub', () {
    test('reprend le poste et les premières compétences', () {
      expect(githubBio(sampleProfile, sampleVersion), 'Développeuse Java · Java, SQL, API REST');
    });

    test('est coupé avant la limite, à un mot entier', () {
      final vBio = githubBio(sampleProfile, sampleVersion, pMax: 30);

      expect(vBio.length, lessThanOrEqualTo(30));
      expect(vBio, endsWith('…'));
    });
  });

  group('page du portfolio', () {
    test('garde les projets et leur lien, sans téléphone ni courriel', () {
      final vPage = portfolioPage(sampleProfile, sampleVersion);

      expect(vPage, startsWith('# Camille Durand'));
      expect(vPage, contains('[Calculatrice](https://example.org/calc)'));
      expect(vPage, isNot(contains('camille.durand@example.org')));
      expect(vPage, isNot(contains('+33 6 00 00 00 00')));
    });
  });

  group('modèles par secteur', () {
    test('chaque secteur garde les mots à remplir', () {
      for (final vSector in cvSectors) {
        final vKit = sectorKit(vSector);

        expect(vKit.hook, contains('{poste}'), reason: vSector);
        expect(vKit.hook, contains('{entreprise}'), reason: vSector);
        expect(vKit.closing, contains('{telephone}'), reason: vSector);
      }
    });
  });

  group('cohérence des supports', () {
    test('un texte fidèle ne signale rien', () {
      const vText = 'Développeuse Java. Mon projet Calculatrice est en ligne.';

      expect(supportDrift(sampleProfile, sampleVersion, vText), isEmpty);
    });

    test('signale le poste absent, le projet oublié et le chiffre inconnu', () {
      final vKinds = [
        for (final vItem in supportDrift(sampleProfile, sampleVersion, 'Développeur web, 12 ans'))
          vItem.kind,
      ];

      expect(vKinds, [
        CvDriftKind.headlineMissing,
        CvDriftKind.projectMissing,
        CvDriftKind.unknownFigure,
      ]);
    });

    test('un texte vide ne signale rien', () {
      expect(supportDrift(sampleProfile, sampleVersion, '  '), isEmpty);
    });
  });

  testWidgets('l\'écran compare un texte publié au parcours', (pTester) async {
    pTester.view
      ..physicalSize = const Size(900, 4000)
      ..devicePixelRatio = 1;
    addTearDown(pTester.view.reset);
    final vState = RevisionState(MemoryRevisionStore(), reminders: FakeReminders());
    await vState.load();
    await vState.importCvProfile(jsonEncode(sampleProfile.toJson()));
    await vState.saveCvVersions([sampleVersion]);

    await pTester.pumpWidget(MaterialApp(home: CvSupportsScreen(state: vState)));
    await pTester.enterText(find.byType(TextField), 'Développeur web');
    await pTester.pumpAndSettle();

    expect(find.text('Le projet « Calculatrice » n\'est pas cité.'), findsOneWidget);
    expect(find.text('Texte du profil GitHub'), findsOneWidget);
  });
}
