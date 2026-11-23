// Lot G du CV : relances, historique figé, préparation d'entretien, statistiques, sauvegarde.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_backup.dart';
import 'package:jobboard_revision/logic/cv_followup.dart';
import 'package:jobboard_revision/logic/cv_prep.dart';
import 'package:jobboard_revision/logic/cv_stats.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_prep_screen.dart';
import 'package:jobboard_revision/screens/cv_track_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

final now = DateTime(2026, 11, 23, 12);

Map<String, dynamic> sent(String pId, String pAt,
        {String outcome = '', String company = 'Exemple SA'}) =>
    {
      'id': pId,
      'at': pAt,
      'version': 'Développeur',
      'company': company,
      'title': 'Développeur Java',
      'outcome': outcome,
      'followed_up': '',
    };

Future<RevisionState> buildState() async {
  final rState = RevisionState(MemoryRevisionStore(), reminders: FakeReminders());
  await rState.load();
  await rState.importCvProfile(jsonEncode(sampleProfile.toJson()));
  await rState.saveCvVersions([sampleVersion]);

  return rState;
}

void main() {
  group('relances', () {
    test('garde les envois anciens, sans réponse ni relance', () {
      final vDue = followUpsDue([
        sent('a', '2026-11-10T09:00:00'),
        sent('b', '2026-11-22T09:00:00'),
        sent('c', '2026-11-01T09:00:00', outcome: 'refus'),
        sent('d', '2026-11-02T09:00:00', company: ''),
        {...sent('e', '2026-11-03T09:00:00'), 'followed_up': '2026-11-12'},
      ], now);

      expect([for (final vItem in vDue) vItem['id']], ['a']);
    });

    test('le message cite l\'entreprise et le poste', () {
      final vText =
          followUpMessage(pName: 'Camille Durand', pCompany: 'Exemple SA', pTitle: 'Développeur');

      expect(vText, contains('le poste de Développeur chez Exemple SA'));
      expect(vText, endsWith('Camille Durand'));
    });
  });

  group('statistiques', () {
    test('compte par version, par mois et par réponse', () {
      final vStats = cvStats([
        {...sent('a', '2026-10-05T09:00:00'), 'outcome': 'entretien'},
        sent('b', '2026-11-05T09:00:00', outcome: 'refus'),
        sent('c', '2026-11-06T09:00:00'),
      ]);

      expect(vStats.total, 3);
      expect(vStats.answered, 2);
      expect(vStats.interviews, 1);
      expect(vStats.byVersion.single.sent, 3);
      expect(vStats.byMonth, {'2026-10': 1, '2026-11': 2});
    });
  });

  group('préparation d\'entretien', () {
    test('une question par mot de l\'offre, avec la ligne du parcours quand elle existe', () {
      final vQuestions = prepQuestions('Développeur Java Kubernetes', sampleProfile, sampleVersion,
          pCompany: 'Exemple SA');
      final vKinds = {for (final vItem in vQuestions) '${vItem.kind}:${vItem.subject}': vItem.hint};

      expect(vKinds.containsKey('why-company:Exemple SA'), isTrue);
      expect(vKinds['used:java'], isNotEmpty);
      expect(vKinds['learn:kubernetes'], isEmpty);
    });

    test('la question sur le virage vient de la version', () {
      final vQuestions = prepQuestions(
          'Java', sampleProfile, sampleVersion.copyWith(pivot: 'Je viens de la maintenance.'));

      expect(vQuestions.map((pItem) => pItem.kind), contains('pivot'));
    });
  });

  group('sauvegarde chiffrée', () {
    test('se rouvre avec le bon mot de passe seulement', () async {
      final vSealed = await sealCv({'a': 1}, 'mot-de-passe-1', pIterations: 1000);

      expect(vSealed, isNot(contains('mot-de-passe-1')));
      expect(await openCv(vSealed, 'mot-de-passe-1'), {'a': 1});
      expect(await openCv(vSealed, 'autre-mot-de-passe'), isNull);
      expect(await openCv('pas une sauvegarde', 'mot-de-passe-1'), isNull);
    });

    test('restaure le parcours sur un autre téléphone', () async {
      final vFrom = await buildState();
      final vTo = RevisionState(MemoryRevisionStore(), reminders: FakeReminders());
      await vTo.load();

      final vSealed = await vFrom.exportCvBackup('mot-de-passe-1', pIterations: 1000);

      expect(await vTo.importCvBackup(vSealed, 'faux'), isFalse);
      expect(vTo.cvProfile.isEmpty, isTrue);
      expect(await vTo.importCvBackup(vSealed, 'mot-de-passe-1'), isTrue);
      expect(vTo.cvProfile.contact.name, 'Camille Durand');
      expect(vTo.cvVersions.single.label, 'Développeur');
    });
  });

  group('envois notés', () {
    test('garde le texte figé, le fichier et la réponse', () async {
      final vState = await buildState();

      await vState.recordCvSent(
        pVersion: sampleVersion,
        pFormat: 'pdf-sobre',
        pCompany: 'Exemple SA',
        pTitle: 'Développeur Java',
        pSnapshot: 'CV tel que parti',
        pFile: 'cv.pdf',
      );
      final vId = '${vState.cvSent.single['id']}';
      await vState.addCvSentFile('Exemple SA', 'Développeur Java', 'lettre.pdf');
      await vState.updateCvSent(vId, {'outcome': 'entretien'});

      final vEntry = vState.cvSent.single;
      expect(vEntry['snapshot'], 'CV tel que parti');
      expect(vEntry['files'], ['cv.pdf', 'lettre.pdf']);
      expect(vEntry['outcome'], 'entretien');
    });

    test('le texte figé ne reste que sur les envois récents', () async {
      final vState = await buildState();

      for (var vIndex = 0; vIndex < maxCvSnapshots + 2; vIndex++) {
        await vState.recordCvSent(
            pVersion: sampleVersion, pFormat: 'txt', pCompany: 'E$vIndex', pSnapshot: 'texte');
      }
      final vSent = vState.cvSent;

      expect(vSent.first['snapshot'], 'texte');
      expect(vSent.last['snapshot'], '');
    });
  });

  group('écrans', () {
    Future<void> bigScreen(WidgetTester pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
    }

    testWidgets('le suivi propose la relance puis la retire', (pTester) async {
      await bigScreen(pTester);
      final vState = await buildState();
      await vState.recordCvSent(
        pVersion: sampleVersion,
        pFormat: 'txt',
        pCompany: 'Exemple SA',
        pTitle: 'Développeur Java',
        pAt: DateTime(2026, 11, 1),
      );

      await pTester.pumpWidget(MaterialApp(home: CvTrackScreen(state: vState, now: now)));
      expect(find.text('Exemple SA · Développeur Java'), findsWidgets);
      expect(find.text('Aucune relance à faire.'), findsNothing);

      await pTester.tap(find.text('Relance faite'));
      await pTester.pumpAndSettle();

      expect(find.text('Aucune relance à faire.'), findsOneWidget);
    });

    testWidgets('la préparation montre la question sur l\'entreprise', (pTester) async {
      await bigScreen(pTester);
      final vState = await buildState();

      await pTester.pumpWidget(
        MaterialApp(
          home: CvPrepScreen(
            state: vState,
            offer: const {
              'title': 'Développeur Java',
              'company': 'Exemple SA',
              'description': 'Java Kubernetes'
            },
          ),
        ),
      );

      expect(find.text('Pourquoi Exemple SA ?'), findsOneWidget);
    });
  });
}
