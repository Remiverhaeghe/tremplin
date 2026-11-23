// Plusieurs offres d'un coup : on colle ou on choisit des offres, et chacune reçoit la version
// du CV la plus proche et les mots qui lui manquent. Rémi valide une par une ensuite.

import 'cv_check.dart';
import 'cv_tailor.dart';
import 'cv_version.dart';

class CvOfferMatch {
  const CvOfferMatch({
    required this.index,
    required this.title,
    required this.text,
    required this.version,
    required this.coverage,
    required this.missing,
  });

  /// Rang de l'offre dans la liste donnée, avant le tri.
  final int index;

  /// Première ligne de l'offre.
  final String title;
  final String text;
  final CvVersion version;

  /// Part des mots-clés de l'offre déjà dans la version, de 0 à 1.
  final double coverage;

  /// Mots de l'offre que la version ne contient pas, les plus fréquents d'abord.
  final List<String> missing;
}

/// Coupe un texte collé en offres : une ligne de `---` sépare deux offres.
List<String> splitOffers(String pText) => [
      for (final vPart in pText.split(RegExp(r'^\s*-{3,}\s*$', multiLine: true)))
        if (vPart.trim().isNotEmpty) vPart.trim(),
    ];

/// Pour chaque offre, la version la plus proche. Les offres les mieux couvertes viennent d'abord.
List<CvOfferMatch> matchOffers(
  List<String> pOffers,
  List<CvVersion> pVersions,
  String Function(CvVersion) pTextOf,
) {
  final vTexts = {for (final vVersion in pVersions) vVersion.id: cvPlain(pTextOf(vVersion))};
  final rMatches = <CvOfferMatch>[];

  for (var vIndex = 0; vIndex < pOffers.length; vIndex++) {
    final vOffer = pOffers[vIndex];
    final vBest = bestVersionFor(vOffer, pVersions, pTextOf);
    if (vBest == null) {
      continue;
    }
    final vCv = vTexts[vBest.version.id]!;
    rMatches.add(
      CvOfferMatch(
        index: vIndex,
        title: vOffer.split('\n').first.trim(),
        text: vOffer,
        version: vBest.version,
        coverage: vBest.coverage,
        missing: [
          for (final vWord in offerKeywords(vOffer))
            if (!vCv.contains(vWord)) vWord,
        ],
      ),
    );
  }
  rMatches.sort((pA, pB) => pB.coverage.compareTo(pA.coverage));

  return rMatches;
}
