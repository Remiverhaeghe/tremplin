// Avant l'export : ce qui bloque (un logiciel de tri lirait mal ou rejetterait le CV) et ce qui
// reste à améliorer. Plus le nom du fichier, propre et lisible par un recruteur.

import 'cv_check.dart';
import 'cv_document.dart';
import 'cv_profile.dart';
import 'cv_version.dart';

/// Contrôles qui bloquent l'export quand ils échouent.
const cvBlockingChecks = {
  CvCheckCode.name,
  CvCheckCode.email,
  CvCheckCode.phone,
  CvCheckCode.experience,
  CvCheckCode.dates,
};

class CvReadiness {
  const CvReadiness({required this.blocking, required this.warnings});

  /// Points qui empêchent l'export.
  final List<CvCheckCode> blocking;

  /// Points à améliorer, sans bloquer.
  final List<CvCheckCode> warnings;

  bool get canExport => blocking.isEmpty;
}

CvReadiness cvReadiness(CvDocument pDocument) {
  final vFailed = [
    for (final vCheck in checkCv(pDocument))
      if (!vCheck.ok) vCheck.code,
  ];

  return CvReadiness(
    blocking: [for (final vCode in vFailed) if (cvBlockingChecks.contains(vCode)) vCode],
    warnings: [for (final vCode in vFailed) if (!cvBlockingChecks.contains(vCode)) vCode],
  );
}

String _slug(String pText) {
  final vPlain = cvPlain(pText).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final rSlug = vPlain
      .split(' ')
      .where((pWord) => pWord.isNotEmpty)
      .map((pWord) => '${pWord[0].toUpperCase()}${pWord.substring(1)}')
      .join('-');

  return rSlug;
}

/// `Prenom-Nom-CV-Developpeur-Flutter.pdf` : le nom, la version, puis l'entreprise si elle est
/// connue. Sans accent ni espace, pour les sites de dépôt qui les refusent.
String cvFileName(
  CvProfile pProfile,
  CvVersion pVersion,
  String pExtension, {
  String pCompany = '',
}) {
  final vParts = [
    _slug(pProfile.contact.name),
    'CV',
    _slug(pVersion.label),
    _slug(pCompany),
  ].where((pPart) => pPart.isNotEmpty);

  return '${vParts.join('-')}.$pExtension';
}
