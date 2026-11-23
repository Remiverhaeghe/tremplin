// Écrit le CV en PDF (sobre et visuel) sur un parcours fictif quand CV_RENDER_DIR est défini ;
// le workflow « Rendu du CV » les convertit en images. Sans la variable, le test ne fait rien.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';

import '../support/cv_samples.dart';

void main() {
  final vDir = Platform.environment['CV_RENDER_DIR'];
  final vPhoto = Platform.environment['CV_RENDER_PHOTO'] ?? '';

  test('écrit les PDF du parcours fictif', () {
    final vProfile = CvProfile.fromJson({
      ...sampleProfile.toJson(),
      'photo': vPhoto,
      'skills': [
        {'id': 's1', 'title': 'Développement', 'items': ['Java', 'SQL', 'API REST'], 'level': 4},
        {'id': 's2', 'title': 'Méthodes', 'items': ['Analyse', 'Amélioration continue'], 'level': 3},
        {'id': 's3', 'title': 'Outils', 'items': ['Git', 'Docker', 'Maven']},
      ],
    });
    final vVersion = sampleVersion.copyWith(
      withPhoto: vPhoto.isNotEmpty,
      skillIds: ['s1', 's2', 's3'],
    );
    final vDocument = buildCvDocument(vProfile, vVersion);

    File('$vDir/cv-sobre.pdf').writeAsBytesSync(buildCvPdf(vDocument));
    File('$vDir/cv-visuel.pdf').writeAsBytesSync(buildCvPdf(vDocument, pStyle: CvPdfStyle.visual));
  }, skip: vDir == null ? 'CV_RENDER_DIR non défini' : false);
}
