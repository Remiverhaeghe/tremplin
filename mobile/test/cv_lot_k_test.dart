// Lot K du CV : titres en anglais, contacts, formations, tableau de la semaine, simulation.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_agenda.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_version.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_agenda_screen.dart';
import 'package:jobboard_revision/screens/cv_simulation_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

final now = DateTime(2026, 11, 23, 12);

Future<RevisionState> buildState() async {
  final rState = RevisionState(MemoryRevisionStore(), reminders: FakeReminders());
  await rState.load();
  await rState.importCvProfile(jsonEncode(sampleProfile.toJson()));
  await rState.saveCvVersions([sampleVersion]);

  return rState;
}

void main() {
  group('CV en anglais', () {
    test('les titres de section passent en anglais, pas le contenu', () {
      final vFrench = buildCvDocument(sampleProfile, sampleVersion);
      final vEnglish = buildCvDocument(sampleProfile, sampleVersion.copyWith(language: 'en'));

      expect(vFrench.sections.map((pItem) => pItem.heading), contains('Compétences'));
      expect(vEnglish.sections.map((pItem) => pItem.heading), contains('Skills'));
      expect(vEnglish.sections.map((pItem) => pItem.heading), isNot(contains('Compétences')));
      expect(vEnglish.plainText, contains(sampleProfile.experiences.first.title));
    });

    test('la langue fait l\'aller-retour et une valeur inconnue revient au français', () {
      final vBack = CvVersion.fromJson(sampleVersion.copyWith(language: 'en').toJson());

      expect(vBack.language, 'en');
      expect(CvVersion.fromJson({...sampleVersion.toJson(), 'language': 'de'}).language, 'fr');
      expect(CvVersion.fromJson({...sampleVersion.toJson()}..remove('language')).language, 'fr');
    });
  });

  group('tableau de la semaine', () {
    final vSent = [
      {'id': 'a', 'at': '2026-11-18T10:00:00', 'company': 'Exemple SA', 'title': 'Dev'},
      {'id': 'b', 'at': '2026-11-22T10:00:00', 'company': 'Autre SA', 'title': 'Dev'},
      {'id': 'c', 'at': '2026-11-10T10:00:00', 'company': 'Close SA', 'outcome': 'refus'},
    ];

    test('relances, contacts et formations dans l\'ordre des jours', () {
      final vPlan = weekPlan(
        pSent: vSent,
        pContacts: const [CvContact(id: '1', name: 'Alice Test', nextAt: '2026-11-24')],
        pTrainings: const [
          CvTraining(id: '2', title: 'Cours Docker', dueAt: '2026-11-26'),
          CvTraining(id: '3', title: 'Cours fini', dueAt: '2026-11-26', state: 'done'),
          CvTraining(id: '4', title: 'Cours lointain', dueAt: '2027-02-01'),
        ],
        pNow: now,
      );

      expect(vPlan.map((pItem) => pItem.kind), ['followup', 'contact', 'training']);
      expect(vPlan.first.day, DateTime(2026, 11, 25));
      expect(vPlan.map((pItem) => pItem.label), isNot(contains('Close SA · ')));
    });

    test('ce qui est en retard est ramené à aujourd\'hui', () {
      final vPlan = weekPlan(
        pSent: const [],
        pContacts: const [CvContact(id: '1', name: 'Alice Test', nextAt: '2026-11-01')],
        pTrainings: const [],
        pNow: now,
      );

      expect(vPlan.single.day, DateTime(2026, 11, 23));
    });
  });

  group('contacts et formations', () {
    test('ils sont gardés dans la sauvegarde chiffrée', () async {
      final vFrom = await buildState();
      await vFrom
          .saveCvContacts(const [CvContact(id: '1', name: 'Alice Test', company: 'Exemple SA')]);
      await vFrom
          .saveCvTrainings(const [CvTraining(id: '2', title: 'Cours Docker', state: 'doing')]);
      final vTo = RevisionState(MemoryRevisionStore(), reminders: FakeReminders());
      await vTo.load();

      final vSealed = await vFrom.exportCvBackup('mot-de-passe-1', pIterations: 1000);

      expect(await vTo.importCvBackup(vSealed, 'mot-de-passe-1'), isTrue);
      expect(vTo.cvContacts.single.name, 'Alice Test');
      expect(vTo.cvTrainings.single.state, 'doing');
    });

    test('un état de formation inconnu revient à « à faire »', () {
      expect(CvTraining.fromJson({'id': 'x', 'title': 'T', 'state': 'zzz'}).state, 'todo');
    });
  });

  group('simulation', () {
    test('la présentation d\'abord, le tirage suit la graine', () {
      final vFirst = simulationQuestions(
          'Développeur Java Spring Kafka', sampleProfile, sampleVersion,
          pSeed: 1);
      final vAgain = simulationQuestions(
          'Développeur Java Spring Kafka', sampleProfile, sampleVersion,
          pSeed: 1);

      expect(vFirst.first, startsWith('Présentez-vous'));
      expect(vFirst, vAgain);
      expect(vFirst.length, lessThanOrEqualTo(5));
    });
  });

  group('écrans', () {
    Future<void> bigScreen(WidgetTester pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
    }

    testWidgets('l\'agenda montre la semaine et les contacts', (pTester) async {
      await bigScreen(pTester);
      final vState = await buildState();
      await vState.saveCvContacts(const [
        CvContact(id: '1', name: 'Alice Test', company: 'Exemple SA', nextAt: '2026-11-24'),
      ]);

      await pTester.pumpWidget(MaterialApp(home: CvAgendaScreen(state: vState, now: now)));

      expect(find.text('Reprendre contact avec Alice Test'), findsOneWidget);
      expect(find.text('Alice Test · Exemple SA'), findsOneWidget);

      await pTester.tap(find.text('Contact fait'));
      await pTester.pumpAndSettle();

      expect(vState.cvContacts.single.lastAt, '2026-11-23');
    });

    testWidgets('la simulation passe d\'une question à la suivante jusqu\'à la fin',
        (pTester) async {
      await bigScreen(pTester);
      final vState = await buildState();

      await pTester.pumpWidget(
        MaterialApp(
          home: CvSimulationScreen(
            state: vState,
            offer: const {'title': 'Développeur Java', 'company': 'Exemple SA'},
            seed: 3,
          ),
        ),
      );

      expect(find.textContaining('Présentez-vous'), findsOneWidget);

      for (var vStep = 0; vStep < 5; vStep++) {
        if (find.text('Question suivante').evaluate().isEmpty) {
          break;
        }
        await pTester.tap(find.text('Question suivante'));
        await pTester.pump();
      }

      expect(find.textContaining('Simulation terminée'), findsOneWidget);
    });
  });
}
