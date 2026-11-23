// Lot B du CV : tenir sur une page, garde-fou de vérité, plusieurs offres d'un coup.

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_batch.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_fit.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_truth.dart';
import 'package:jobboard_revision/logic/cv_version.dart';
import 'package:jobboard_revision/revision_state.dart';

import 'support/cv_samples.dart';
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

List<String> lines(String pPrefix, int pCount) => [
      for (var vIndex = 0; vIndex < pCount; vIndex++) '$pPrefix $vIndex',
    ];

CvDocument bigDocument() => CvDocument(
      name: 'Camille Durand',
      headline: 'Développeuse',
      contactLines: const ['camille@example.org', '+33 6 00 00 00 00'],
      sections: [
        CvSectionText(
          section: CvSection.experience,
          heading: 'Expériences professionnelles',
          blocks: [
            for (var vJob = 0; vJob < 3; vJob++)
              CvBlock(
                title: 'Poste $vJob',
                detail: 'Entreprise $vJob',
                dates: '20${10 + vJob}',
                lines: lines('Mission du poste $vJob numéro', 10),
              ),
          ],
        ),
        CvSectionText(
          section: CvSection.projects,
          heading: 'Projets',
          blocks: [
            for (var vProject = 0; vProject < 5; vProject++)
              CvBlock(title: 'Projet $vProject', lines: lines('Détail du projet $vProject', 3)),
          ],
        ),
        CvSectionText(
          section: CvSection.education,
          heading: 'Formation',
          blocks: const [CvBlock(title: 'BTS Exemple', dates: '2008')],
        ),
        CvSectionText(
          section: CvSection.strengths,
          heading: 'Atouts',
          blocks: [CvBlock(lines: lines('Atout', 4))],
        ),
        CvSectionText(
          section: CvSection.interests,
          heading: "Centres d'intérêt",
          blocks: [CvBlock(lines: lines('Intérêt', 3))],
        ),
      ],
    );

void main() {
  group('tenir sur une page', () {
    test('le nombre de pages suit le contenu', () {
      expect(cvPageCount(buildCvDocument(sampleProfile, sampleVersion)), 1);
      expect(cvPageCount(bigDocument()), greaterThan(1));
    });

    test('un CV qui tient déjà n\'est pas touché', () {
      final vDocument = buildCvDocument(sampleProfile, sampleVersion);
      final vFit = fitDocument(vDocument, 1);

      expect(vFit.removed, isEmpty);
      expect(vFit.fits, isTrue);
      expect(vFit.document.plainText, vDocument.plainText);
    });

    test('on retire d\'abord les intérêts et les atouts, jamais les postes ni la formation', () {
      final vFit = fitDocument(bigDocument(), 1);
      final vText = vFit.document.plainText;

      expect(vFit.fits, isTrue);
      expect(cvPageCount(vFit.document), 1);
      expect(vFit.removed.take(2), ['interests', 'strengths']);
      for (final vKept in ['Poste 0', 'Poste 1', 'Poste 2', 'BTS Exemple', 'Camille Durand']) {
        expect(vText, contains(vKept));
      }
      expect(vText, isNot(contains("Centres d'intérêt")));
    });

    test('les anciens postes perdent leurs détails avant les récents', () {
      final vFit = fitDocument(bigDocument(), 1);
      final vText = vFit.document.plainText;

      expect(vText, contains('Mission du poste 0 numéro 9'));
      expect(vText, isNot(contains('Mission du poste 2 numéro 9')));
    });

    test('si rien ne suffit, le document le dit et garde l\'essentiel', () {
      final vHuge = CvDocument(
        name: 'Camille Durand',
        headline: '',
        contactLines: const [],
        sections: [
          CvSectionText(
            section: CvSection.experience,
            heading: 'Expériences professionnelles',
            blocks: [
              for (var vJob = 0; vJob < 40; vJob++)
                CvBlock(title: 'Poste $vJob', dates: '2010', lines: const ['Ligne']),
            ],
          ),
        ],
      );
      final vFit = fitDocument(vHuge, 1);

      expect(vFit.fits, isFalse);
      expect(vFit.document.plainText, contains('Poste 39'));
    });
  });

  group('garde-fou de vérité', () {
    const vProfile = CvProfile(
      experiences: [
        CvExperience(
          id: 'maint',
          title: 'Maintenance',
          lines: ['Réduction de 30 % des arrêts', 'Planification des interventions'],
        ),
      ],
      projects: [
        CvProject(id: 'ok', name: 'Public', url: 'https://github.com/exemple/public'),
        CvProject(id: 'vide', name: 'Sans lien'),
        CvProject(id: 'site', name: 'Autre site', url: 'https://example.org/projet'),
        CvProject(id: 'chiffre', name: 'Outil', url: 'https://github.com/exemple/outil', lines: [
          'Utilisé par 12 personnes',
          'Java Swing',
        ]),
      ],
    );

    test('un projet sans lien public ou hors GitHub est signalé', () {
      final vIssues = checkTruth(vProfile);

      expect(
        vIssues
            .where((pItem) => pItem.kind == CvTruthKind.projectWithoutUrl)
            .map((pItem) => pItem.itemId),
        ['vide'],
      );
      expect(
        vIssues
            .where((pItem) => pItem.kind == CvTruthKind.projectNotOnGithub)
            .map((pItem) => pItem.itemId),
        ['site'],
      );
    });

    test('un chiffre dans une phrase est signalé, pas une phrase sans chiffre', () {
      final vFigures = checkTruth(vProfile).where((pItem) => pItem.kind == CvTruthKind.figure);

      expect(vFigures.map((pItem) => pItem.text), [
        'Réduction de 30 % des arrêts',
        'Utilisé par 12 personnes',
      ]);
    });

    test('un chiffre confirmé n\'est plus signalé', () {
      final vConfirmed = {cvClaimKey('  réduction de 30 %  des arrêts')};
      final vFigures = checkTruth(vProfile, pConfirmed: vConfirmed)
          .where((pItem) => pItem.kind == CvTruthKind.figure);

      expect(vFigures.map((pItem) => pItem.text), ['Utilisé par 12 personnes']);
    });

    test('la confirmation est gardée sur le téléphone', () async {
      final vStore = MemoryRevisionStore();
      final vState = RevisionState(vStore, reminders: FakeReminders());
      await vState.load();
      await vState.confirmCvClaim('Réduction de 30 % des arrêts');

      final vAgain = RevisionState(vStore, reminders: FakeReminders());
      await vAgain.load();

      expect(vAgain.cvConfirmedClaims, {cvClaimKey('Réduction de 30 % des arrêts')});
    });
  });

  group('plusieurs offres', () {
    const vWeb = CvVersion(
      id: 'web',
      label: 'Web',
      sections: [CvSection.skills],
      skillIds: ['web'],
    );
    const vJava = CvVersion(
      id: 'java',
      label: 'Java',
      sections: [CvSection.skills],
      skillIds: ['java'],
    );
    const vProfile = CvProfile(
      skills: [
        CvSkillGroup(id: 'web', title: 'Web', items: ['Vue', 'Symfony', 'CSS']),
        CvSkillGroup(id: 'java', title: 'Java', items: ['Java', 'Maven', 'SQL']),
      ],
    );
    String textOf(CvVersion pVersion) => buildCvDocument(vProfile, pVersion).plainText;

    test('les offres sont séparées par une ligne de tirets', () {
      final vOffers = splitOffers('Offre A\nSymfony\n---\n\n  ---  \nOffre B\nJava Maven\n-----\n');

      expect(vOffers, ['Offre A\nSymfony', 'Offre B\nJava Maven']);
      expect(splitOffers('   '), isEmpty);
    });

    test('chaque offre reçoit la version la plus proche et ses mots manquants', () {
      final vMatches = matchOffers(
        ['Développeur Symfony\nSymfony Vue Docker', 'Développeur Java\nJava Maven SQL Kafka'],
        [vWeb, vJava],
        textOf,
      );

      expect(vMatches.map((pItem) => pItem.version.id).toSet(), {'web', 'java'});
      final vWebOffer = vMatches.firstWhere((pItem) => pItem.index == 0);
      expect(vWebOffer.version.id, 'web');
      expect(vWebOffer.title, 'Développeur Symfony');
      expect(vWebOffer.missing, contains('docker'));
      expect(vWebOffer.missing, isNot(contains('symfony')));
      final vJavaOffer = vMatches.firstWhere((pItem) => pItem.index == 1);
      expect(vJavaOffer.version.id, 'java');
      expect(vJavaOffer.missing, contains('kafka'));
    });

    test('les offres les mieux couvertes viennent en premier', () {
      final vMatches = matchOffers(
        ['Poste\nKafka Docker Terraform', 'Poste\nSymfony Vue CSS'],
        [vWeb],
        textOf,
      );

      expect(vMatches.first.index, 1);
      expect(vMatches.first.coverage, greaterThan(vMatches.last.coverage));
    });

    test('sans version, aucune offre n\'est analysée', () {
      expect(matchOffers(['Poste'], [], textOf), isEmpty);
    });
  });
}
