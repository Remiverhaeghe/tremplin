// Offres au-delà du profil : l'offre demande plus d'années, un niveau plus senior ou un diplôme
// plus haut que ce que le CV montre. Un signal, jamais un refus : Rémi décide d'envoyer ou non.

import 'cv_check.dart';
import 'cv_profile.dart';

enum CvStretchKind { years, seniority, degree }

class CvStretch {
  const CvStretch(this.kind, {this.required = 0, this.have = 0});

  final CvStretchKind kind;

  /// Années ou niveau bac+N demandé par l'offre.
  final int required;

  /// Ce que le CV indique, 0 si inconnu.
  final int have;
}

/// Plus grand nombre d'années d'expérience demandé dans l'offre, 0 si aucun.
int yearsAsked(String pOffer) {
  final vText = cvPlain(pOffer).replaceAll('’', "'");
  var rYears = 0;

  for (final vPattern in [
    RegExp(r"(\d{1,2})\s*(?:ans?|annees?)\s*(?:d'|de\s)?experience"),
    RegExp(r"experience[^.\n]{0,30}?(\d{1,2})\s*(?:ans?|annees?)"),
    RegExp(r"(\d{1,2})\s*(?:ans?|annees?)\s*minimum"),
  ]) {
    for (final vMatch in vPattern.allMatches(vText)) {
      final vValue = int.parse(vMatch.group(1)!);
      if (vValue > rYears && vValue < 40) {
        rYears = vValue;
      }
    }
  }

  return rYears;
}

/// Niveau d'études demandé en bac+N, 0 si l'offre n'en parle pas.
int degreeAsked(String pOffer) {
  final vText = cvPlain(pOffer);
  var rLevel = 0;

  for (final vMatch in RegExp(r'bac\s*\+\s*(\d)').allMatches(vText)) {
    final vValue = int.parse(vMatch.group(1)!);
    if (vValue > rLevel) {
      rLevel = vValue;
    }
  }
  if (RegExp(r'\b(master|ingenieur|msc)\b').hasMatch(vText) && rLevel < 5) {
    rLevel = 5;
  }

  return rLevel;
}

/// Plus haut niveau reconnu dans la formation du parcours, en bac+N ; 0 si rien de reconnu.
int degreeLevelOf(CvProfile pProfile) {
  var rLevel = 0;

  for (final vItem in pProfile.education) {
    final vTitle = cvPlain(vItem.title);
    final vLevel = RegExp(r'bac\s*\+\s*(\d)').firstMatch(vTitle)?.group(1);
    final vFound = vLevel != null
        ? int.parse(vLevel)
        : RegExp(r'\b(master|ingenieur|msc)\b').hasMatch(vTitle)
            ? 5
            : RegExp(r'\b(maitrise)\b').hasMatch(vTitle)
                ? 4
                : RegExp(r'\b(licence|but)\b').hasMatch(vTitle)
                    ? 3
                    : RegExp(r'\b(bts|dut|deust)\b').hasMatch(vTitle)
                        ? 2
                        : 0;
    if (vFound > rLevel) {
      rLevel = vFound;
    }
  }

  return rLevel;
}

/// Ce qui dépasse le profil. [pYears] est le nombre d'années de la version ; 0 si inconnu.
List<CvStretch> stretchSignals(String pOffer, CvProfile pProfile, {int pYears = 0}) {
  final vText = cvPlain(pOffer);
  final vYears = yearsAsked(pOffer);
  final vDegree = degreeAsked(pOffer);
  final vHave = degreeLevelOf(pProfile);

  return [
    if (vYears > 0 && pYears > 0 && vYears > pYears)
      CvStretch(CvStretchKind.years, required: vYears, have: pYears),
    if (RegExp(r'\b(senior|confirme|expert|lead)\b').hasMatch(vText) && pYears > 0 && pYears < 5)
      const CvStretch(CvStretchKind.seniority),
    if (vDegree > 0 && vHave > 0 && vDegree > vHave)
      CvStretch(CvStretchKind.degree, required: vDegree, have: vHave),
  ];
}
