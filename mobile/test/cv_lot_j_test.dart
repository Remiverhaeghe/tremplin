// Lot J du CV : rappels de relance, délais de réponse, export tableur, questions à poser.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_export_csv.dart';
import 'package:jobboard_revision/logic/cv_followup.dart';
import 'package:jobboard_revision/logic/cv_prep.dart';
import 'package:jobboard_revision/logic/cv_stats.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_track_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

final now = DateTime(2026, 11, 23, 12);

Map<String, dynamic> sent(String pAt,
        {String outcome = '', String company = 'Exemple SA', String answered = ''}) =>
    {
      'id': pAt + company,
      'at': pAt,
      'version': 'Développeur',
      'company': company,
      'title': 'Développeur Java',
      'format': 'pdf-sobre',
      if (outcome.isNotEmpty) 'outcome': outcome,
      if (answered.isNotEmpty) 'answered_at': answered,
    };

Future<(RevisionState, FakeReminders)> buildState() async {
  final vReminders = FakeReminders();
  final vState = RevisionState(MemoryRevisionStore(), reminders: vReminders);
  await vState.load();
  await vState.importCvProfile(jsonEncode(sampleProfile.toJson()));
  await vState.saveCvVersions([sampleVersion]);

  return (vState, vReminders);
}

void main() {
  group('rappels de relance', () {
    test('un rappel à 9 h sept jours après l\'envoi', () {
      final vAlerts = followUpAlerts([sent('2026-11-20T10:00:00')], now);

      expect(vAlerts, hasLength(1));
      expect(vAlerts.first.at, DateTime(2026, 11, 27, 9));
      expect(vAlerts.first.body, contains('Exemple SA'));
    });

    test('une candidature en retard est rappelée le lendemain à 9 h', () {
      final vAlerts = followUpAlerts([sent('2026-11-01T10:00:00')], now);

      expect(vAlerts.single.at, DateTime(2026, 11, 24, 9));
    });

    test('pas de rappel pour une candidature qui a une réponse ou une relance', () {
      final vAlerts = followUpAlerts([
        sent('2026-11-20T10:00:00', outcome: 'refus'),
        {...sent('2026-11-20T10:00:00', company: 'Autre SA'), 'followed_up': '2026-11-27'},
      ], now);

      expect(vAlerts, isEmpty);
    });

    test('au plus pMax rappels, les plus proches d\'abord', () {
      final vAlerts = followUpAlerts([
        sent('2026-11-22T10:00:00', company: 'B SA'),
        sent('2026-11-20T10:00:00', company: 'A SA'),
        sent('2026-11-21T10:00:00', company: 'C SA'),
      ], now, pMax: 2);

      expect(vAlerts.map((pItem) => pItem.body), [contains('A SA'), contains('C SA')]);
    });

    test('l\'état replanifie les rappels à chaque envoi', () async {
      final (vState, vReminders) = await buildState();

      await vState.recordCvSent(
        pVersion: sampleVersion,
        pFormat: 'txt',
        pCompany: 'Exemple SA',
        pTitle: 'Développeur Java',
        pAt: DateTime.now(),
      );

      expect(vReminders.followUps.last, hasLength(1));

      await vState.updateCvSent('${vState.cvSent.first['id']}', {'outcome': 'refus'});

      expect(vReminders.followUps.last, isEmpty);
    });
  });

  group('délais de réponse', () {
    test('moyenne par entreprise, les plus rapides d\'abord', () {
      final vDelays = responseDelays([
        sent('2026-11-01T10:00:00', outcome: 'reponse', answered: '2026-11-11T10:00:00'),
        sent('2026-11-05T10:00:00',
            outcome: 'reponse', answered: '2026-11-07T10:00:00', company: 'Rapide SA'),
        sent('2026-11-10T10:00:00', outcome: 'reponse', answered: '2026-11-20T10:00:00'),
        sent('2026-11-12T10:00:00', company: 'Sans réponse SA'),
      ]);

      expect(vDelays.map((pItem) => pItem.company), ['Rapide SA', 'Exemple SA']);
      expect(vDelays.last.days, 10);
    });

    test('la réponse notée garde sa date', () async {
      final (vState, _) = await buildState();
      await vState.recordCvSent(
        pVersion: sampleVersion,
        pFormat: 'txt',
        pCompany: 'Exemple SA',
        pTitle: 'Développeur Java',
        pAt: DateTime.now(),
      );

      await vState.updateCvSent('${vState.cvSent.first['id']}', {'outcome': 'reponse'});

      expect('${vState.cvSent.first['answered_at']}', isNotEmpty);
    });

    test('une offre compte comme un entretien dans les statistiques', () {
      final vStats = cvStats([sent('2026-11-01T10:00:00', outcome: 'offre')]);

      expect(vStats.interviews, 1);
      expect(cvOutcomes, contains('offre'));
    });
  });

  group('export tableur', () {
    test('en-tête, ordre des colonnes et BOM', () {
      final vCsv = sentToCsv([
        sent('2026-11-01T10:00:00', outcome: 'reponse', answered: '2026-11-04T10:00:00'),
      ]);
      final vLines = vCsv.trim().split('\r\n');

      expect(vCsv.startsWith('\u{FEFF}Date;Entreprise'), isTrue);
      expect(vLines[1],
          startsWith('2026-11-01;Exemple SA;Développeur Java;Développeur;pdf-sobre;reponse;;3'));
    });

    test('les points-virgules et guillemets sont protégés', () {
      final vCsv = sentToCsv([sent('2026-11-01T10:00:00', company: 'A; "B" SA')]);

      expect(vCsv, contains('"A; ""B"" SA"'));
    });
  });

  group('questions à poser', () {
    test('une question sur les premières semaines et une sur la suite', () {
      final vAsk = questionsToAsk('Développeur Java Spring Kafka', sampleProfile, sampleVersion,
          pCompany: 'Exemple SA');

      expect(vAsk.first, contains('premières semaines'));
      expect(vAsk.last, contains('prochaines étapes'));
      expect(vAsk.length, lessThanOrEqualTo(6));
    });

    test('pMax limite la liste', () {
      expect(questionsToAsk('Java', sampleProfile, sampleVersion, pMax: 2), hasLength(2));
    });
  });

  group('bilan du mois', () {
    test('compte ce qui est parti ce mois-là et ce que ça a donné', () {
      final vSent = [
        sent('2026-11-02T09:00:00', outcome: 'entretien'),
        sent('2026-11-10T09:00:00', outcome: 'refus'),
        sent('2026-11-12T09:00:00', outcome: 'offre'),
        sent('2026-11-20T09:00:00', outcome: 'reponse'),
        sent('2026-11-21T09:00:00'),
        sent('2026-10-30T09:00:00', outcome: 'offre'),
      ];

      expect(
        cvMonthSummary(vSent, '2026-11'),
        (month: '2026-11', sent: 5, answered: 4, interviews: 1, offers: 1, refusals: 1, waiting: 1),
      );
      expect(cvMonthSummary(vSent, '2026-09').sent, 0);
      expect(cvMonthKey(DateTime(2026, 3, 5)), '2026-03');
    });
  });

  group('écran de suivi', () {
    testWidgets('tableau, délais et export du tableur', (pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
      final (vState, _) = await buildState();
      await vState.recordCvSent(
        pVersion: sampleVersion,
        pFormat: 'txt',
        pCompany: 'Exemple SA',
        pTitle: 'Développeur Java',
        pAt: DateTime(2026, 11, 1),
      );
      String? vName;

      await pTester.pumpWidget(
        MaterialApp(
          home: CvTrackScreen(
            state: vState,
            now: now,
            send: (pBytes, pName, pMime) async => vName = pName,
          ),
        ),
      );

      expect(find.text('Tableau des candidatures'), findsOneWidget);
      expect(find.text('Pas de réponse (1)'), findsOneWidget);

      await pTester.tap(find.text('Exporter le suivi en tableur'));
      await pTester.pump();

      expect(vName, 'candidatures.csv');
    });

    testWidgets('un geste partage le bilan du mois, sans nom d\'entreprise', (pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
      final (vState, _) = await buildState();
      await vState.recordCvSent(
        pVersion: sampleVersion,
        pFormat: 'txt',
        pCompany: 'Exemple SA',
        pTitle: 'Développeur Java',
        pAt: DateTime(2026, 11, 1),
      );
      String? vName;
      String? vText;

      await pTester.pumpWidget(
        MaterialApp(
          home: CvTrackScreen(
            state: vState,
            now: now,
            send: (pBytes, pName, pMime) async {
              vName = pName;
              vText = utf8.decode(pBytes);
            },
          ),
        ),
      );
      await pTester.tap(find.text('Partager le bilan du mois'));
      await pTester.pump();

      expect(vName, 'bilan-2026-11.txt');
      expect(vText, contains('1 envoyées'));
      expect(vText, contains('1 sans réponse'));
      expect(vText, isNot(contains('Exemple SA')));
    });
  });
}
