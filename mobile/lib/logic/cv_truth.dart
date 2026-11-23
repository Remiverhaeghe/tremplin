// Garde-fou : le CV doit rester vrai. On signale ce que Rémi devra pouvoir défendre en
// entretien : un projet sans lien public, un chiffre dans une phrase. Rien n'est corrigé tout
// seul ; un chiffre confirmé par Rémi n'est plus signalé.

import 'cv_profile.dart';

enum CvTruthKind { projectWithoutUrl, projectNotOnGithub, figure }

class CvTruthIssue {
  const CvTruthIssue({required this.kind, required this.itemId, required this.text});

  final CvTruthKind kind;

  /// Identifiant du projet ou du poste concerné.
  final String itemId;

  /// Le projet, ou la phrase qui contient le chiffre.
  final String text;
}

final _figure = RegExp(
  r'(\d+(?:[.,]\d+)?\s?(?:%|k€|m€|€|fois|x\b|clients?|utilisateurs?|personnes?|sites?|machines?|'
  r'équipements?|equipements?|interventions?|postes?|agents?))|(?:plus de|près de|environ)\s+\d+',
  caseSensitive: false,
);

final _github = RegExp(r'^https://github\.com/[^/\s]+/[^/\s]+/?$');

/// Phrase de chiffre confirmée : la même clé sert à la confirmer et à ne plus la signaler.
String cvClaimKey(String pText) => pText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<CvTruthIssue> checkTruth(CvProfile pProfile, {Set<String> pConfirmed = const {}}) {
  final rIssues = <CvTruthIssue>[];

  for (final vProject in pProfile.projects) {
    if (vProject.url.trim().isEmpty) {
      rIssues.add(
        CvTruthIssue(kind: CvTruthKind.projectWithoutUrl, itemId: vProject.id, text: vProject.name),
      );
    } else if (!_github.hasMatch(vProject.url.trim())) {
      rIssues.add(
        CvTruthIssue(
            kind: CvTruthKind.projectNotOnGithub, itemId: vProject.id, text: vProject.name),
      );
    }
  }

  void figures(String pId, Iterable<String> pLines) {
    for (final vLine in pLines) {
      if (_figure.hasMatch(vLine) && !pConfirmed.contains(cvClaimKey(vLine))) {
        rIssues.add(CvTruthIssue(kind: CvTruthKind.figure, itemId: pId, text: vLine));
      }
    }
  }

  for (final vExperience in pProfile.experiences) {
    figures(vExperience.id, vExperience.lines);
  }
  for (final vProject in pProfile.projects) {
    figures(vProject.id, vProject.lines);
  }

  return rIssues;
}
