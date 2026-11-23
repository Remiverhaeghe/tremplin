import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_check.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_export.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_tailor.dart';
import 'package:jobboard_revision/logic/cv_version.dart';

import 'support/cv_samples.dart';

/// Textes des commandes `(…) Tj`, dans l'ordre du fichier, décodés comme un lecteur de PDF.
List<String> pdfTexts(String pPdf) {
  const vBack = {0x92: '’', 0x95: '•', 0x96: '–', 0x9C: 'œ'};
  final rTexts = <String>[];
  for (final vMatch in RegExp(r'\(((?:\\.|[^\\)])*)\) Tj').allMatches(pPdf)) {
    final vRaw = vMatch.group(1)!.replaceAllMapped(RegExp(r'\\(.)'), (pM) => pM.group(1)!);
    rTexts.add(String.fromCharCodes([
      for (final vUnit in vRaw.codeUnits) ...(vBack[vUnit] ?? String.fromCharCode(vUnit)).runes,
    ]));
  }

  return rTexts;
}

String pdfOf(CvDocument pDocument, {CvPdfStyle pStyle = CvPdfStyle.plain}) =>
    latin1.decode(buildCvPdf(pDocument, pStyle: pStyle));

void main() {
  final vDocument = buildCvDocument(sampleProfile, sampleVersion);

  group('PDF', () {
    test('le fichier est un PDF valide : en-tête, table des positions, fin', () {
      final vPdf = pdfOf(vDocument);

      expect(vPdf, startsWith('%PDF-1.4'));
      expect(vPdf.trimRight(), endsWith('%%EOF'));
      final vStart = int.parse(RegExp(r'startxref\n(\d+)').firstMatch(vPdf)!.group(1)!);
      expect(vPdf.substring(vStart), startsWith('xref'));
      final vOffsets = RegExp(r'(\d{10}) 00000 n').allMatches(vPdf).toList();
      expect(vOffsets, isNotEmpty);
      for (var vIndex = 0; vIndex < vOffsets.length; vIndex++) {
        final vAt = int.parse(vOffsets[vIndex].group(1)!);
        expect(vPdf.substring(vAt), startsWith('${vIndex + 1} 0 obj'));
      }
    });

    test('le texte reste du vrai texte, accents compris, dans l\'ordre du CV', () {
      final vText = pdfTexts(pdfOf(vDocument)).join('\n');

      for (final vPart in [
        'Camille Durand',
        'Développeuse Java',
        'camille.durand@example.org',
        'Expériences professionnelles',
        'Responsable de maintenance',
        'Interfaces avec un ERP en SFTP',
        '2020 à aujourd’hui',
      ]) {
        expect(vText, contains(vPart));
      }
      expect(vText.indexOf('Profil'), lessThan(vText.indexOf('Expériences professionnelles')));
      expect(vText.indexOf('Expériences professionnelles'), lessThan(vText.indexOf('Formation')));
    });

    test('les parenthèses et barres obliques du texte sont protégées', () {
      const vDoc = CvDocument(
        name: r'A (B) \ C',
        headline: '',
        contactLines: [],
        sections: [],
      );

      expect(pdfTexts(pdfOf(vDoc)), [r'A (B) \ C']);
    });

    test('le rendu sobre est noir sur blanc, le rendu visuel ajoute un bandeau', () {
      final vPlain = pdfOf(vDocument);
      final vVisual = pdfOf(vDocument, pStyle: CvPdfStyle.visual);

      expect(vPlain, isNot(contains(' re f')));
      expect(vVisual, contains(' re f'));
      List<String> words(String pPdf) => [
            for (final vWord in pdfTexts(pPdf).join(' ').split(RegExp(r'\s+')))
              if (vWord.isNotEmpty && vWord != '|') vWord,
          ];

      expect(words(vVisual), words(vPlain));
    });

    test('un long CV passe sur plusieurs pages sans perdre une ligne', () {
      final vLines = [for (var vIndex = 0; vIndex < 120; vIndex++) 'Tâche numéro $vIndex'];
      final vLong = CvDocument(
        name: 'Camille Durand',
        headline: 'Développeuse',
        contactLines: const ['camille@example.org'],
        sections: [
          CvSectionText(
            section: CvSection.experience,
            heading: 'Expériences professionnelles',
            blocks: [CvBlock(title: 'Poste', dates: '2020', lines: vLines)],
          ),
        ],
      );
      final vPdf = pdfOf(vLong);

      expect(RegExp(r'/Count (\d+)').firstMatch(vPdf)!.group(1), isNot('1'));
      final vText = pdfTexts(vPdf);
      for (final vLine in vLines) {
        expect(vText, contains(vLine));
      }
    });

    test('les lignes tiennent dans la largeur, un mot trop long est coupé', () {
      const vSize = 10.0;
      const vWidth = 200.0;
      final vLines = cvWrap(
        'Un texte assez long pour passer à la ligne ${'x' * 120} et finir',
        vWidth,
        pSize: vSize,
      );

      expect(vLines.length, greaterThan(2));
      for (final vLine in vLines) {
        expect(cvTextWidth(vLine, pSize: vSize), lessThanOrEqualTo(vWidth));
      }
      expect(vLines.join(' ').replaceAll(' ', ''), contains('x' * 120));
    });

    test('les signes hors Latin-1 gardent leur octet Windows-1252', () {
      expect(cvPdfEncode('l’œuvre – 5 €').codeUnits, [
        0x6C, 0x92, 0x9C, 0x75, 0x76, 0x72, 0x65, 0x20, 0x96, 0x20, 0x35, 0x20, 0x80, //
      ]);
      expect(cvPdfEncode('日'), '?');
    });
  });

  group('adapter à une offre', () {
    const vOffer = 'Développeur Java SQL pour une application métier, API REST, Java';
    final vProfile = CvProfile(
      contact: sampleProfile.contact,
      experiences: sampleProfile.experiences,
      projects: const [
        CvProject(id: 'web', name: 'Site vitrine', lines: ['Vue 3, CSS']),
        CvProject(id: 'java', name: 'Calculatrice', lines: ['Java Swing, tests']),
        CvProject(id: 'rest', name: 'Service', lines: ['API REST, SQL']),
      ],
      skills: const [
        CvSkillGroup(id: 'front', title: 'Interface', items: ['Vue', 'CSS']),
        CvSkillGroup(id: 'back', title: 'Serveur', items: ['Java', 'SQL', 'API REST']),
      ],
    );
    const vVersion = CvVersion(
      id: 'dev',
      label: 'Développeur',
      sections: [CvSection.projects, CvSection.skills],
      experienceIds: ['dev', 'maint'],
      projectIds: ['web', 'java', 'rest'],
      skillIds: ['front', 'back'],
    );

    test('les projets et groupes de compétences passent dans l\'ordre de l\'offre', () {
      final vTailored = tailorVersion(vProfile, vVersion, vOffer);

      expect(vTailored.projectIds, ['rest', 'java', 'web']);
      expect(vTailored.skillIds, ['back', 'front']);
    });

    test('rien n\'est ajouté ni retiré, et les expériences gardent leur ordre', () {
      final vTailored = tailorVersion(vProfile, vVersion, vOffer);

      expect(vTailored.experienceIds, vVersion.experienceIds);
      expect(vTailored.projectIds.toSet(), vVersion.projectIds.toSet());
      expect(vTailored.skillIds.toSet(), vVersion.skillIds.toSet());
    });

    test('à égalité, l\'ordre choisi par Rémi est gardé', () {
      final vTailored = tailorVersion(vProfile, vVersion, 'Comptable confirmé');

      expect(vTailored.projectIds, vVersion.projectIds);
    });

    test('un maximum de projets ne garde que les plus proches de l\'offre', () {
      final vTailored = tailorVersion(vProfile, vVersion, vOffer, pMaxProjects: 2);

      expect(vTailored.projectIds, ['rest', 'java']);
    });

    test('la version la plus proche de l\'offre est proposée', () {
      final vOther = vVersion.copyWith(projectIds: ['web'], skillIds: ['front']);
      final vBest = bestVersionFor(
        vOffer,
        [vOther, vVersion],
        (pVersion) => buildCvDocument(vProfile, pVersion).plainText,
      );

      expect(vBest!.version.id, vVersion.id);
      expect(vBest.coverage, greaterThan(0));
      expect(bestVersionFor(vOffer, [], (pVersion) => ''), isNull);
    });
  });

  group('avant l\'export', () {
    test('un CV complet peut partir', () {
      final vReady = cvReadiness(vDocument);

      expect(vReady.canExport, isTrue);
      expect(vReady.warnings, isEmpty);
    });

    test('sans courriel ni dates, l\'export est bloqué', () {
      final vProfile = CvProfile(
        contact: const CvContact(name: 'Camille Durand', phone: '+33 6 00 00 00 00'),
        experiences: const [CvExperience(id: 'a', title: 'Poste', dates: 'récemment')],
        education: sampleProfile.education,
      );
      final vReady = cvReadiness(buildCvDocument(
          vProfile,
          sampleVersion.copyWith(
            experienceIds: ['a'],
          )));

      expect(vReady.canExport, isFalse);
      expect(vReady.blocking, containsAll([CvCheckCode.email, CvCheckCode.dates]));
    });

    test('une accroche manquante avertit sans bloquer', () {
      final vReady = cvReadiness(
        buildCvDocument(sampleProfile, sampleVersion.copyWith(headline: '', summary: '')),
      );

      expect(vReady.canExport, isTrue);
      expect(vReady.warnings, containsAll([CvCheckCode.headline, CvCheckCode.summary]));
    });

    test('le nom du fichier est propre : sans accent ni espace', () {
      expect(cvFileName(sampleProfile, sampleVersion, 'pdf'), 'Camille-Durand-CV-Developpeur.pdf');
      expect(
        cvFileName(sampleProfile, sampleVersion, 'docx', pCompany: 'Société Générale (Lille)'),
        'Camille-Durand-CV-Developpeur-Societe-Generale-Lille.docx',
      );
    });
  });
}
