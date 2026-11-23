// Tout le CV dans un seul texte lisible sans l'application : parcours, versions, candidatures,
// modèles de lettre et réponses. Aucun chiffrement : le fichier contient des coordonnées réelles.

import 'cv_answers.dart';
import 'cv_document.dart';
import 'cv_letter.dart';
import 'cv_profile.dart';
import 'cv_supports.dart';
import 'cv_version.dart';

String buildDossier({
  required CvProfile pProfile,
  required List<CvVersion> pVersions,
  required List<Map<String, dynamic>> pSent,
  required LetterKit pKit,
  required List<CvAnswer> pAnswers,
  required DateTime pNow,
}) {
  final rText = StringBuffer('Dossier CV de ${pProfile.contact.name}\n');

  rText.writeln('Exporté le ${pNow.toIso8601String().split('T').first}\n');

  for (final vVersion in pVersions) {
    rText
      ..writeln('==== Version : ${vVersion.label} ====\n')
      ..writeln(buildCvDocument(pProfile, vVersion).plainText)
      ..writeln();
  }
  if (pVersions.isNotEmpty) {
    rText
      ..writeln('==== Page du portfolio (version ${pVersions.first.label}) ====\n')
      ..writeln(portfolioPage(pProfile, pVersions.first))
      ..writeln();
  }

  rText.writeln('==== Candidatures (${pSent.length}) ====\n');
  for (final vItem in pSent) {
    final vOutcome = '${vItem['outcome'] ?? ''}';

    rText.writeln(
      '- ${'${vItem['at']}'.split('T').first} · ${vItem['company']} · ${vItem['title']} · '
      'CV ${vItem['version']}${vOutcome.isEmpty ? '' : ' · $vOutcome'}',
    );
  }

  rText
    ..writeln('\n==== Modèles de lettre ====\n')
    ..writeln('Début : ${pKit.hook}')
    ..writeln('Exemple : ${pKit.proof}')
    ..writeln('Fin : ${pKit.closing}')
    ..writeln('Message court : ${pKit.message}')
    ..writeln('\n==== Réponses aux formulaires ====\n');
  for (final vAnswer in pAnswers) {
    rText.writeln('${questionFor(vAnswer, pCompany: '', pJob: '')}\n${vAnswer.text}\n');
  }

  return rText.toString();
}
