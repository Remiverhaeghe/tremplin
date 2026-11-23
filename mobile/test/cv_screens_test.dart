// CV sur le téléphone : parcours importé, versions, envois, et écrans pour exporter.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_apply_screen.dart';
import 'package:jobboard_revision/screens/cv_batch_screen.dart';
import 'package:jobboard_revision/screens/cv_letter_screen.dart';
import 'package:jobboard_revision/screens/cv_templates_screen.dart';
import 'package:jobboard_revision/screens/cv_screen.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

RevisionState buildState() => RevisionState(MemoryRevisionStore(), reminders: FakeReminders());

String profileJson([CvProfile pProfile = sampleProfile]) => jsonEncode(pProfile.toJson());

const offer = <String, dynamic>{
  'title': 'Développeur Java',
  'company': 'Exemple SA',
  'url': 'https://example.org/offre',
  'description': 'Java, SQL et API REST pour une application métier.',
};

void main() {
  group('état', () {
    test('un texte qui n\'est pas un parcours est refusé', () async {
      final vState = buildState();
      await vState.load();

      expect(await vState.importCvProfile('pas du json'), isFalse);
      expect(await vState.importCvProfile('{}'), isFalse);
      expect(vState.cvProfile.isEmpty, isTrue);
      expect(vState.cvVersions, isEmpty);
    });

    test('un parcours importé crée les versions de départ, une seule fois', () async {
      final vState = buildState();
      await vState.load();

      expect(await vState.importCvProfile(profileJson()), isTrue);
      expect(vState.cvProfile.contact.name, 'Camille Durand');
      final vIds = vState.cvVersions.map((pItem) => pItem.id).toList();
      expect(vIds, ['developpeur', 'industrie']);

      await vState.removeCvVersion('industrie');
      await vState.importCvProfile(profileJson());
      expect(vState.cvVersions.map((pItem) => pItem.id), ['developpeur']);
    });

    test('une version se modifie, se crée et se supprime', () async {
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(profileJson());

      await vState.saveCvVersion(
        vState.cvVersions.first.copyWith(headline: 'Développeuse Java', summary: 'Accroche'),
      );
      await vState.saveCvVersion(sampleVersion);

      expect(vState.cvVersions.first.headline, 'Développeuse Java');
      expect(vState.cvVersions, hasLength(3));
      await vState.removeCvVersion(sampleVersion.id);
      expect(vState.cvVersions, hasLength(2));
    });

    test('le parcours et les versions survivent à un redémarrage', () async {
      final vStore = MemoryRevisionStore();
      final vState = RevisionState(vStore, reminders: FakeReminders());
      await vState.load();
      await vState.importCvProfile(profileJson());

      final vAgain = RevisionState(vStore, reminders: FakeReminders());
      await vAgain.load();

      expect(vAgain.cvProfile.contact.email, 'camille.durand@example.org');
      expect(vAgain.cvVersions, hasLength(2));
    });

    test('les envois sont notés du plus récent au plus ancien, avec une limite', () async {
      final vState = buildState();
      await vState.load();

      for (var vIndex = 0; vIndex < maxCvSent + 5; vIndex++) {
        await vState.recordCvSent(
          pVersion: sampleVersion,
          pFormat: 'pdf-sobre',
          pCompany: 'Entreprise $vIndex',
          pAt: DateTime(2026, 11, 23, 10, 0, vIndex % 60),
        );
      }

      expect(vState.cvSent, hasLength(maxCvSent));
      expect(vState.cvSent.first['company'], 'Entreprise ${maxCvSent + 4}');
      expect(vState.cvSent.first['version'], sampleVersion.label);
    });
  });

  group('écrans', () {
    Future<void> bigScreen(WidgetTester pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
    }

    testWidgets('sans parcours, l\'écran propose de l\'importer', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();

      await pTester.pumpWidget(MaterialApp(home: CvScreen(state: vState)));
      expect(find.text('Importe d\'abord ton parcours pour créer des CV.'), findsOneWidget);

      await pTester.tap(find.text('Importer mon parcours'));
      await pTester.pumpAndSettle();
      await pTester.enterText(find.byType(TextField), 'n\'importe quoi');
      await pTester.tap(find.text('Importer'));
      await pTester.pumpAndSettle();
      expect(find.textContaining('n\'est pas un parcours'), findsOneWidget);

      await pTester.enterText(find.byType(TextField), profileJson());
      await pTester.tap(find.text('Importer'));
      await pTester.pumpAndSettle();

      expect(find.text('Camille Durand'), findsOneWidget);
      expect(find.text('Développeur'), findsOneWidget);
      expect(find.text('Industrie et méthodes'), findsOneWidget);
    });

    testWidgets('postuler : le CV part avec un nom propre et l\'envoi est noté', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(profileJson());
      final vSent = <({Uint8List bytes, String name, String mime})>[];

      await pTester.pumpWidget(
        MaterialApp(
          home: CvApplyScreen(
            state: vState,
            offer: offer,
            send: (pBytes, pName, pMime) async =>
                vSent.add((bytes: pBytes, name: pName, mime: pMime)),
          ),
        ),
      );
      await pTester.pumpAndSettle();

      expect(find.text('Mots absents : ajoute-les seulement s\'ils sont vrais'), findsOneWidget);
      expect(find.text('java'), findsOneWidget);

      await pTester.tap(find.text('PDF sobre (logiciels de tri)'));
      await pTester.pumpAndSettle();

      expect(vSent, hasLength(1));
      expect(vSent.single.name, startsWith('Camille-Durand-CV-'));
      expect(vSent.single.name, endsWith('-Exemple-Sa.pdf'));
      expect(vSent.single.mime, 'application/pdf');
      expect(String.fromCharCodes(vSent.single.bytes.take(5)), '%PDF-');
      expect(vState.cvSent.single['company'], 'Exemple SA');
      expect(vState.cvSent.single['format'], 'pdf-sobre');
      expect(vState.cvSent.single['tailored'], isTrue);
    });

    testWidgets('un CV sans courriel ne peut pas partir', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(
        profileJson(
          CvProfile(
            contact: const CvContact(name: 'Camille Durand', phone: '+33 6 00 00 00 00'),
            experiences: sampleProfile.experiences,
            education: sampleProfile.education,
          ),
        ),
      );

      await pTester.pumpWidget(
        MaterialApp(home: CvApplyScreen(state: vState, offer: offer, send: (_, __, ___) async {})),
      );
      await pTester.pumpAndSettle();

      final vButton = pTester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'PDF sobre (logiciels de tri)'),
      );
      expect(vButton.onPressed, isNull);
      expect(find.textContaining('Export bloqué'), findsOneWidget);
    });

    testWidgets('un chiffre à défendre est signalé puis confirmé', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(
        profileJson(
          CvProfile(
            contact: sampleProfile.contact,
            experiences: const [
              CvExperience(
                id: 'a',
                title: 'Maintenance',
                dates: '2010 - 2019',
                lines: ['Réduction de 30 % des arrêts'],
              ),
            ],
            projects: const [CvProject(id: 'p', name: 'Outil', url: 'https://example.org/outil')],
          ),
        ),
      );

      await pTester.pumpWidget(MaterialApp(home: CvScreen(state: vState)));

      expect(find.textContaining('Lien qui n\'est pas un dépôt GitHub : Outil'), findsOneWidget);
      expect(find.textContaining('« Réduction de 30 % des arrêts »'), findsOneWidget);

      await pTester.tap(find.text('Je le confirme'));
      await pTester.pumpAndSettle();

      expect(find.textContaining('« Réduction de 30 % des arrêts »'), findsNothing);
      expect(find.textContaining('Lien qui n\'est pas un dépôt GitHub'), findsOneWidget);
    });

    testWidgets('plusieurs offres collées : chacune a sa version, un appui ouvre l\'envoi',
        (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(profileJson());

      await pTester.pumpWidget(MaterialApp(home: CvBatchScreen(state: vState)));
      await pTester.enterText(
        find.byType(TextField),
        'Développeur Java\nJava SQL API REST\n---\nTechnicien maintenance\nMaintenance planification',
      );
      await pTester.tap(find.text('Analyser'));
      await pTester.pumpAndSettle();

      expect(find.text('Développeur Java'), findsOneWidget);
      expect(find.text('Technicien maintenance'), findsOneWidget);

      await pTester.tap(find.text('Développeur Java'));
      await pTester.pumpAndSettle();

      expect(find.text('Postuler : Développeur Java'), findsOneWidget);
    });

    testWidgets('limiter à une page garde un PDF d\'une page', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(profileJson());
      final vSent = <Uint8List>[];

      await pTester.pumpWidget(
        MaterialApp(
          home: CvApplyScreen(
            state: vState,
            offer: offer,
            send: (pBytes, _, __) async => vSent.add(pBytes),
          ),
        ),
      );
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('1 page'));
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('PDF visuel (envoi par courriel)'));
      await pTester.pumpAndSettle();

      expect(vSent, hasLength(1));
      expect(latin1.decode(vSent.single), contains('/Count 1'));
    });

    testWidgets('la lettre se remplit, se relit et part en PDF', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(profileJson());
      final vSent = <String>[];

      await pTester.pumpWidget(
        MaterialApp(
          home: CvLetterScreen(
            state: vState,
            offer: offer,
            send: (_, pName, __) async => vSent.add(pName),
          ),
        ),
      );
      await pTester.pumpAndSettle();

      TextEditingController field() =>
          pTester.widget<TextField>(find.byType(TextField)).controller!;
      expect(field().text, startsWith('Je candidate au poste de Développeur Java chez Exemple SA.'));
      expect(find.text('Rien à signaler.'), findsOneWidget);

      await pTester.enterText(find.byType(TextField), 'Je me permets de vous écrire.');
      await pTester.pumpAndSettle();
      expect(find.textContaining('Formule toute faite'), findsOneWidget);

      await pTester.tap(find.text('Message'));
      await pTester.pumpAndSettle();
      expect(field().text, contains('Mon CV est en pièce jointe.'));

      await pTester.tap(find.text('PDF'));
      await pTester.pumpAndSettle();
      expect(vSent, ['Camille-Durand-Lettre-Exemple-Sa.pdf']);
    });

    testWidgets('les modèles se gardent et la réponse copiée porte l\'entreprise', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(profileJson());

      await pTester.pumpWidget(MaterialApp(home: CvTemplatesScreen(state: vState, offer: offer)));
      await pTester.pumpAndSettle();

      expect(find.text('Pourquoi Exemple SA ?'), findsOneWidget);
      expect(find.text('Pourquoi le poste de Développeur Java ?'), findsOneWidget);

      await pTester.enterText(
        find.widgetWithText(TextField, 'Pourquoi Exemple SA ?'),
        'Parce que {entreprise} fait de la maintenance.',
      );
      await pTester.tap(find.text('Garder'));
      await pTester.pumpAndSettle();

      expect(
        vState.cvAnswers.firstWhere((pItem) => pItem.id == 'why-company').text,
        'Parce que {entreprise} fait de la maintenance.',
      );
    });
  });
}
