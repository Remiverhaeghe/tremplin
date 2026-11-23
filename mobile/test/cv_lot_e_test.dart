// Lot E du CV : écart de compétences, avant / après, lecture du PDF, offres au-delà du profil.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_diff.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_gap.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_readback.dart';
import 'package:jobboard_revision/logic/cv_stretch.dart';
import 'package:jobboard_revision/logic/cv_version.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_apply_screen.dart';
import 'package:jobboard_revision/screens/cv_batch_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

RevisionState buildState() => RevisionState(MemoryRevisionStore(), reminders: FakeReminders());

void main() {
  group('écart de compétences', () {
    test('garde les mots demandés deux fois et absents du CV', () {
      final vGap = skillGap(
        ['Développeur Kubernetes Java', 'Ingénieur Kubernetes Terraform Java'],
        'Java SQL',
      );

      expect([for (final vItem in vGap) vItem.word], ['kubernetes']);
      expect(vGap.single.offers, 2);
    });

    test('un mot présent dans une seule offre ne compte pas', () {
      expect(skillGap(['Terraform'], ''), isEmpty);
    });
  });

  group('avant / après', () {
    test('marque les lignes retirées et ajoutées', () {
      final vDiff = diffLines('a\nb\nc', 'a\nc\nd');

      expect([for (final vLine in vDiff) '${vLine.kind.name}:${vLine.text}'],
          ['same:a', 'removed:b', 'same:c', 'added:d']);
    });

    test('deux textes identiques ne donnent aucun écart', () {
      expect(diffLines('a\nb', 'a\nb').every((pLine) => pLine.kind == CvDiffKind.same), isTrue);
    });
  });

  group('lecture du PDF', () {
    test('le texte du PDF se relit, accents compris', () {
      final vDocument = buildCvDocument(sampleProfile, sampleVersion);
      final vRead = atsReadback(vDocument, buildCvPdf(vDocument));

      expect(vRead.text, contains('Camille Durand'));
      expect(vRead.text, contains('Développeuse Java'));
      expect(vRead.missing, isNot(contains('developpeuse')));
    });

    test('un signe que la police ne sait pas écrire est signalé', () {
      final vProfile = CvProfile(
        contact: const CvContact(name: 'Camille → Durand', email: 'camille@example.org'),
        experiences: sampleProfile.experiences,
      );
      final vDocument = buildCvDocument(vProfile, sampleVersion);
      final vRead = atsReadback(vDocument, buildCvPdf(vDocument));

      expect(vRead.missing, contains('→'));
    });
  });

  group('au-delà du profil', () {
    test('lit les années et le niveau demandés', () {
      expect(yearsAsked('5 ans d’expérience minimum'), 5);
      expect(yearsAsked('Expérience souhaitée : 3 ans'), 3);
      expect(yearsAsked('Poste à pourvoir'), 0);
      expect(degreeAsked('Bac+5 en informatique'), 5);
      expect(degreeAsked('Profil ingénieur'), 5);
    });

    test('compare avec la version et la formation', () {
      const vOffer = 'Développeur confirmé, 5 ans d’expérience, bac+5';
      final vKinds = [
        for (final vItem in stretchSignals(vOffer, sampleProfile, pYears: 2)) vItem.kind
      ];

      expect(vKinds, [CvStretchKind.years, CvStretchKind.seniority, CvStretchKind.degree]);
    });

    test('sans années indiquées, seul le diplôme est comparé', () {
      final vKinds = [
        for (final vItem in stretchSignals('Confirmé, 5 ans d’expérience, bac+5', sampleProfile))
          vItem.kind,
      ];

      expect(vKinds, [CvStretchKind.degree]);
    });

    test('une offre à la portée du profil ne signale rien', () {
      expect(stretchSignals('2 ans d’expérience, bac+2', sampleProfile, pYears: 6), isEmpty);
    });
  });

  group('écrans', () {
    Future<void> bigScreen(WidgetTester pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
    }

    testWidgets('la candidature signale une offre trop haute pour la version', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(jsonEncode(sampleProfile.toJson()));
      await vState.saveCvVersions([sampleVersion.copyWith(years: 2)]);

      await pTester.pumpWidget(
        MaterialApp(
          home: CvApplyScreen(
            state: vState,
            offer: const {
              'title': 'Développeur Java',
              'company': 'Exemple SA',
              'description': 'Profil confirmé, 5 ans d’expérience.',
            },
          ),
        ),
      );
      await pTester.pumpAndSettle();

      expect(find.text('Cette offre vise plus haut que ton profil'), findsOneWidget);
      expect(find.text('Avant / après adaptation'), findsOneWidget);
    });

    testWidgets('le lot d’offres montre l’écart de compétences', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(jsonEncode(sampleProfile.toJson()));

      await pTester.pumpWidget(MaterialApp(home: CvBatchScreen(state: vState)));
      await pTester.enterText(
        find.byType(TextField),
        'Développeur Kubernetes\n---\nIngénieur Kubernetes',
      );
      await pTester.tap(find.text('Analyser'));
      await pTester.pumpAndSettle();

      expect(find.text('kubernetes : 2 offres'), findsOneWidget);
    });
  });
}
