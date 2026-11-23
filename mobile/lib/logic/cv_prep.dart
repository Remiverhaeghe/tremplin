// Préparation d'entretien liée à une offre : les questions probables d'après les mots de l'offre,
// avec dans chaque cas la ligne du parcours qui peut servir de réponse. Rien n'est inventé : si
// le parcours ne montre pas un mot, l'indication dit de rester vrai.

import 'cv_check.dart';
import 'cv_profile.dart';
import 'cv_version.dart';

class CvPrepQuestion {
  const CvPrepQuestion(this.kind, this.subject, [this.hint = '']);

  /// `why-company`, `pivot`, `project`, `used`, `learn`.
  final String kind;

  /// Entreprise, projet ou mot de l'offre concerné.
  final String subject;

  /// Ligne du parcours qui peut servir de réponse ; vide si le parcours n'en a pas.
  final String hint;
}

List<CvPrepQuestion> prepQuestions(
  String pOffer,
  CvProfile pProfile,
  CvVersion pVersion, {
  String pCompany = '',
  int pMax = 10,
}) {
  final vLines = <String>[
    for (final vItem in pProfile.experiences) ...vItem.lines,
    for (final vItem in pProfile.projects) ...vItem.lines,
    for (final vGroup in pProfile.skills) ...vGroup.items,
  ];
  final rQuestions = <CvPrepQuestion>[
    if (pCompany.trim().isNotEmpty) CvPrepQuestion('why-company', pCompany.trim()),
    if (pVersion.pivot.trim().isNotEmpty) CvPrepQuestion('pivot', '', pVersion.pivot.trim()),
    if (pProfile.projects.isNotEmpty)
      CvPrepQuestion(
          'project', pProfile.projects.first.name, pProfile.projects.first.lines.join(' ')),
  ];

  for (final vWord in offerKeywords(pOffer, pLimit: 12)) {
    final vFound = vLines.where((pLine) => cvPlain(pLine).contains(vWord)).toList();

    rQuestions.add(
      vFound.isEmpty ? CvPrepQuestion('learn', vWord) : CvPrepQuestion('used', vWord, vFound.first),
    );
  }

  return rQuestions.take(pMax).toList();
}
