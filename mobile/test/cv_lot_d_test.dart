// Lot D du CV : habilitations, virage de métier, mots du secteur, ajout d'un projet.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_letter.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_translate.dart';
import 'package:jobboard_revision/logic/cv_version.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/screens/cv_add_screen.dart';
import 'package:jobboard_revision/screens/cv_apply_screen.dart';

import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

const profile = CvProfile(
  contact: CvContact(
    name: 'Camille Durand',
    email: 'camille.durand@example.org',
    phone: '+33 6 00 00 00 00',
  ),
  experiences: [
    CvExperience(
      id: 'maint',
      title: 'Technicien',
      company: 'Usine Exemple',
      dates: '2010 - 2019',
      lines: ['Contrôles périodiques des machines', 'Dépannage des lignes de production'],
    ),
  ],
  certifications: [
    CvCertification(id: 'hab', title: 'Habilitation électrique B1V', detail: 'Organisme Exemple', dates: '2021'),
  ],
  projects: [
    CvProject(id: 'p1', name: 'Calculatrice', url: 'https://github.com/exemple/calc', lines: ['Dépannage des formules']),
  ],
);

const version = CvVersion(
  id: 'ind',
  label: 'Industrie',
  summary: 'Dix ans de dépannage en usine.',
  pivot: 'Je suis passé de la maintenance au développement par les outils internes.',
  sections: [
    CvSection.summary,
    CvSection.experience,
    CvSection.projects,
    CvSection.certifications,
  ],
  experienceIds: ['maint'],
  projectIds: ['p1'],
);

RevisionState buildState() => RevisionState(MemoryRevisionStore(), reminders: FakeReminders());

void main() {
  group('habilitations', () {
    test('elles font un aller-retour JSON et ont leur section', () {
      final vBack = CvProfile.tryParse(jsonEncode(profile.toJson()))!;
      final vDocument = buildCvDocument(vBack, version);
      final vSection = vDocument.sections.firstWhere((pItem) => pItem.section == CvSection.certifications);

      expect(vSection.heading, 'Habilitations et permis');
      expect(vSection.blocks.single.title, 'Habilitation électrique B1V');
      expect(vSection.blocks.single.detail, 'Organisme Exemple');
      expect(vDocument.plainText, contains('Habilitations et permis'));
    });

    test('les versions de départ ne gardent la section que si le parcours en a', () {
      expect(
        startingVersions(profile).every((pItem) => pItem.sections.contains(CvSection.certifications)),
        isTrue,
      );
      expect(
        startingVersions(const CvProfile(contact: CvContact(name: 'A'))).any(
          (pItem) => pItem.sections.contains(CvSection.certifications),
        ),
        isFalse,
      );
    });
  });

  group('virage et mots choisis', () {
    test('une ancienne version sans ces champs se lit toujours', () {
      final vOld = CvVersion.fromJson({'id': 'a', 'label': 'Ancienne'});

      expect(vOld.pivot, '');
      expect(vOld.wording, isEmpty);
    });

    test('le virage et les mots choisis survivent à un aller-retour JSON', () {
      final vVersion = version.copyWith(wording: {'dépannage': 'maintenance corrective'});
      final vBack = CvVersion.fromJson(jsonDecode(jsonEncode(vVersion.toJson())) as Map<String, Object?>);

      expect(vBack.pivot, version.pivot);
      expect(vBack.wording, {'dépannage': 'maintenance corrective'});
    });

    test('un mot choisi remplace l\'ancien partout, sans toucher le nom ni la casse du reste', () {
      final vDocument = buildCvDocument(
        profile,
        version.copyWith(wording: {'dépannage': 'maintenance corrective', '': 'zzz'}),
      );
      final vText = vDocument.plainText;

      expect(vText, contains('maintenance corrective des lignes de production'));
      expect(vText, contains('Dix ans de maintenance corrective en usine.'));
      expect(vText, contains('maintenance corrective des formules'));
      expect(vText, isNot(contains('zzz')));
      expect(vDocument.name, 'Camille Durand');
      expect(applyWording('DÉPANNAGE express', {'dépannage': 'x'}), 'x express');
    });

    test('la lettre complète reprend le virage après l\'accroche, pas la courte', () {
      List<String> letter(LetterLength pLength) => buildLetter(
            pProfile: profile,
            pVersion: version,
            pKit: const LetterKit(),
            pLength: pLength,
            pCompany: 'Exemple SA',
            pJob: 'Technicien',
          );

      final vFull = letter(LetterLength.full);
      expect(vFull[1], version.summary);
      expect(vFull[2], version.pivot);
      expect(letter(LetterLength.short).join(), isNot(contains(version.pivot)));
    });

    test('les mots du secteur ne sont proposés que s\'ils sont dans l\'offre et dans le CV', () {
      final vFound = suggestWordings('Technicien de maintenance préventive et ordonnancement', profile);

      expect(vFound.map((pItem) => pItem.to), ['maintenance préventive']);
      expect(suggestWordings('Poste de comptable', profile), isEmpty);
      expect(
        suggestWordings(
          'Maintenance préventive',
          profile,
          pApplied: {'contrôles périodiques': 'maintenance préventive'},
        ),
        isEmpty,
      );
      expect(suggestWordings('MAINTENANCE PRÉVENTIVE', profile), hasLength(1));
      expect(suggestWordings('Maintenance corrective', const CvProfile()), isEmpty);
    });
  });

  group('ajout au parcours', () {
    test('un projet rejoint les versions qui ont une section Projets', () async {
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(jsonEncode(profile.toJson()));
      await vState.saveCvVersion(version.copyWith(sections: [CvSection.experience]));
      await vState.saveCvVersion(CvVersion.fromJson({...version.toJson(), 'id': 'dev'}));

      await vState.addCvProject(const CvProject(id: 'p2', name: 'Atelier', url: 'https://github.com/exemple/atelier'));

      expect(vState.cvProfile.projects.map((pItem) => pItem.id), ['p1', 'p2']);
      final vVersions = {for (final vItem in vState.cvVersions) vItem.id: vItem};
      expect(vVersions['dev']!.projectIds, ['p1', 'p2']);
      expect(vVersions['ind']!.projectIds, ['p1']);
    });

    test('une habilitation ajoute sa section aux versions qui ne l\'avaient pas', () async {
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(jsonEncode(profile.toJson()));
      await vState.saveCvVersion(const CvVersion(id: 'x', label: 'Sans', sections: [CvSection.summary, CvSection.languages]));

      await vState.addCvCertification(const CvCertification(id: 'permis', title: 'Permis B'));

      final vSans = vState.cvVersions.firstWhere((pItem) => pItem.id == 'x');
      expect(vSans.sections, [CvSection.summary, CvSection.certifications, CvSection.languages]);
      expect(vState.cvProfile.certifications.map((pItem) => pItem.title), contains('Permis B'));
    });
  });

  group('écrans', () {
    Future<void> bigScreen(WidgetTester pTester) async {
      pTester.view
        ..physicalSize = const Size(900, 4000)
        ..devicePixelRatio = 1;
      addTearDown(pTester.view.reset);
    }

    testWidgets('le formulaire ajoute un projet et refuse un nom vide', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(jsonEncode(profile.toJson()));

      await pTester.pumpWidget(MaterialApp(home: CvAddScreen(state: vState)));
      await pTester.tap(find.text('Garder'));
      await pTester.pumpAndSettle();
      expect(find.text('Indique au moins un nom.'), findsOneWidget);

      await pTester.enterText(find.widgetWithText(TextField, 'Nom'), 'Atelier');
      await pTester.enterText(
        find.widgetWithText(TextField, 'Lien public du projet'),
        'https://github.com/exemple/atelier',
      );
      await pTester.enterText(
        find.widgetWithText(TextField, 'Ce qu\'il fait, une ligne par phrase'),
        'Une appli de travaux\nEn Flutter',
      );
      await pTester.tap(find.text('Garder'));
      await pTester.pumpAndSettle();

      final vAdded = vState.cvProfile.projects.last;
      expect(vAdded.name, 'Atelier');
      expect(vAdded.lines, ['Une appli de travaux', 'En Flutter']);
    });

    testWidgets('un mot du secteur accepté change le CV envoyé', (pTester) async {
      await bigScreen(pTester);
      final vState = buildState();
      await vState.load();
      await vState.importCvProfile(jsonEncode(profile.toJson()));
      final vSent = <String>[];

      await pTester.pumpWidget(
        MaterialApp(
          home: CvApplyScreen(
            state: vState,
            offer: const {
              'title': 'Technicien',
              'company': 'Exemple SA',
              'description': 'Maintenance préventive des lignes.',
            },
            send: (pBytes, _, __) async => vSent.add(utf8.decode(pBytes)),
          ),
        ),
      );
      await pTester.pumpAndSettle();

      expect(find.text('Mots du métier à reprendre'), findsOneWidget);
      await pTester.tap(find.text('Utiliser'));
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('Texte brut'));
      await pTester.pumpAndSettle();

      expect(vSent.single, contains('maintenance préventive des machines'));
      expect(vSent.single, isNot(contains('Contrôles périodiques')));
    });
  });
}
