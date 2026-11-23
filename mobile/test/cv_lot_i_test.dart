// Lot I du CV : couleur du PDF, mots du métier, doublon d'envoi, présentation orale, PDF balisé.

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_followup.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_pitch.dart';
import 'package:jobboard_revision/logic/cv_translate.dart';
import 'package:jobboard_revision/logic/cv_version.dart';
import 'package:jobboard_revision/widgets/cv_export_panel.dart';

import 'cv_pdf_test.dart';
import 'support/cv_samples.dart';

void main() {
  group('couleur du PDF visuel', () {
    test('la couleur choisie est celle du bandeau', () {
      final vDocument = buildCvDocument(sampleProfile, sampleVersion);
      final vGreen = String.fromCharCodes(renderCv(vDocument, 'pdf-visuel', pAccent: 0x2E7D32).bytes);
      final vDefault = String.fromCharCodes(renderCv(vDocument, 'pdf-visuel').bytes);

      expect(vGreen, contains('0.18 0.49 0.20 rg'));
      expect(vDefault, isNot(contains('0.18 0.49 0.20 rg')));
    });

    test('la couleur de la version fait l\'aller-retour', () {
      final vBack = CvVersion.fromJson(sampleVersion.copyWith(accent: 0xB3261E).toJson());

      expect(vBack.accent, 0xB3261E);
      expect(cvAccents, contains(0xB3261E));
    });
  });

  test('le dictionnaire du métier n\'a pas de mot en double', () {
    final vFrom = [for (final vItem in defaultWordings) vItem.from];

    expect(vFrom.length, greaterThanOrEqualTo(20));
    expect(vFrom.toSet().length, vFrom.length);
  });

  group('doublon d\'envoi', () {
    final vNow = DateTime(2026, 11, 23);
    final vSent = [
      {'at': '2026-11-10T09:00:00', 'company': 'Exemple SA', 'title': 'Développeur Java'},
      {'at': '2026-09-01T09:00:00', 'company': 'Autre SA', 'title': 'Technicien'},
    ];

    test('retrouve un envoi récent à la même entreprise pour le même poste', () {
      expect(recentDuplicate(vSent, 'exemple sa', 'Développeur Java', vNow), isNotNull);
    });

    test('ignore un envoi ancien, un autre poste ou une entreprise inconnue', () {
      expect(recentDuplicate(vSent, 'Autre SA', 'Technicien', vNow), isNull);
      expect(recentDuplicate(vSent, 'Exemple SA', 'Technicien', vNow), isNull);
      expect(recentDuplicate(vSent, '', 'Développeur Java', vNow), isNull);
    });
  });

  group('présentation de trente secondes', () {
    test('tient en moins de quatre-vingt-dix mots et reste fidèle au parcours', () {
      final vPitch = buildPitch(
        sampleProfile,
        sampleVersion.copyWith(pivot: 'Je suis passé de la maintenance au développement. Le reste est long.'),
        pCompany: 'Exemple SA',
        pJob: 'Développeur Java',
      );

      expect(vPitch, startsWith('Bonjour, je m’appelle Camille Durand.'));
      expect(vPitch, contains('Je suis passé de la maintenance au développement.'));
      expect(vPitch, isNot(contains('Le reste est long')));
      expect(vPitch, contains('Le poste de Développeur Java chez Exemple SA m’intéresse.'));
      expect(vPitch.split(RegExp(r'\s+')).length, lessThanOrEqualTo(90));
      expect(pitchSeconds(vPitch), lessThanOrEqualTo(40));
    });
  });

  group('PDF balisé', () {
    test('un titre, des titres de section et un arbre de structure', () {
      final vPdf = pdfOf(buildCvDocument(sampleProfile, sampleVersion));

      expect(vPdf, contains('/MarkInfo << /Marked true >>'));
      expect(vPdf, contains('/StructTreeRoot'));
      expect(RegExp(r'/S /H1').allMatches(vPdf), hasLength(1));
      expect(RegExp(r'/S /H2').allMatches(vPdf).length, greaterThanOrEqualTo(3));
    });

    test('les puces sont du décor, pas du contenu', () {
      final vPdf = pdfOf(buildCvDocument(sampleProfile, sampleVersion));

      expect(vPdf, contains('/Artifact BMC'));
    });

    test('chaque repère de contenu a son élément de structure', () {
      final vPdf = pdfOf(buildCvDocument(sampleProfile, sampleVersion), pStyle: CvPdfStyle.visual);
      final vMarks = RegExp(r'BDC BT').allMatches(vPdf).length;
      final vElements = RegExp(r'/Type /StructElem /S /(?!Document)').allMatches(vPdf).length;

      expect(vElements, vMarks);
    });

    test('le texte se lit toujours dans l\'ordre', () {
      final vTexts = pdfTexts(pdfOf(buildCvDocument(sampleProfile, sampleVersion)));

      expect(vTexts.first, 'Camille Durand');
    });
  });
}
