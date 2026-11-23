// Rendu visuel du CV : photo ronde, étoiles de niveau, pastilles de contact, frise.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';

import 'cv_pdf_test.dart';
import 'support/cv_samples.dart';

/// JPEG minimal : en-tête SOF0 de 16 sur 16 points, ce qui suffit à lire ses dimensions.
final jpeg = base64Encode([
  0xFF, 0xD8, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x10, 0x00, 0x10, 0x03, //
  0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01, 0xFF, 0xD9,
]);

CvProfile withExtras({String photo = '', int level = 0}) => CvProfile.fromJson({
      ...sampleProfile.toJson(),
      if (photo.isNotEmpty) 'photo': photo,
      'skills': [
        {'id': 's1', 'title': 'Développement', 'items': ['Java', 'SQL'], 'level': level},
      ],
    });

void main() {
  test('le niveau et la photo font l\'aller-retour du parcours', () {
    final vBack = CvProfile.fromJson(withExtras(photo: jpeg, level: 4).toJson());

    expect(vBack.photo, jpeg);
    expect(vBack.skills.single.level, 4);
    expect(CvProfile.fromJson({'skills': [{'id': 'a', 'title': 'B', 'level': 9}]}).skills.single.level, 5);
  });

  test('un texte qui n\'est pas une photo JPEG est ignoré', () {
    expect(photoBytes('pas du base 64 !'), isEmpty);
    expect(photoBytes(base64Encode([1, 2, 3, 4, 5, 6])), isEmpty);
    expect(photoBytes(jpeg), isNotEmpty);
  });

  test('la photo n\'est dans le document que si la version la demande', () {
    final vProfile = withExtras(photo: jpeg);

    expect(buildCvDocument(vProfile, sampleVersion).photo, isEmpty);
    expect(buildCvDocument(vProfile, sampleVersion.copyWith(withPhoto: true)).photo, isNotEmpty);
  });

  test('le PDF visuel embarque la photo, le sobre jamais', () {
    final vDocument = buildCvDocument(withExtras(photo: jpeg), sampleVersion.copyWith(withPhoto: true));
    final vVisual = pdfOf(vDocument, pStyle: CvPdfStyle.visual);

    expect(vVisual, contains('/Subtype /Image'));
    expect(vVisual, contains('/DCTDecode'));
    expect(vVisual, contains('/Im1 Do'));
    expect(pdfOf(vDocument), isNot(contains('/Im1')));
  });

  test('sans photo, le PDF visuel n\'a pas d\'image', () {
    final vDocument = buildCvDocument(withExtras(), sampleVersion);

    expect(pdfOf(vDocument, pStyle: CvPdfStyle.visual), isNot(contains('/Subtype /Image')));
  });

  test('les étoiles ne sont dessinées que pour un niveau noté, et seulement en visuel', () {
    const vGold = '0.96 0.65 0.14 rg';
    final vRated = buildCvDocument(withExtras(level: 3), sampleVersion);
    final vUnrated = buildCvDocument(withExtras(), sampleVersion);

    expect(pdfOf(vRated, pStyle: CvPdfStyle.visual), contains(vGold));
    expect(pdfOf(vUnrated, pStyle: CvPdfStyle.visual), isNot(contains(vGold)));
    expect(pdfOf(vRated), isNot(contains(vGold)));
  });

  test('le texte reste lisible dans l\'ordre malgré le décor', () {
    final vDocument = buildCvDocument(withExtras(level: 3, photo: jpeg), sampleVersion.copyWith(withPhoto: true));
    final vTexts = pdfTexts(pdfOf(vDocument, pStyle: CvPdfStyle.visual));

    expect(vTexts.first, 'Camille Durand');
    expect(vTexts, contains('camille.durand@example.org'));
    expect(vTexts.indexOf('Camille Durand'), lessThan(vTexts.indexOf('camille.durand@example.org')));
  });
}
