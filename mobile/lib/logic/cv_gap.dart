// Écart de compétences : parmi plusieurs offres, les mots demandés plus d'une fois que le
// parcours ne contient nulle part. Ce n'est pas une liste à copier dans le CV : c'est ce qu'il
// faut apprendre, ou citer seulement si c'est vrai.

import 'cv_check.dart';

typedef CvGapItem = ({String word, int offers});

/// Mots absents du texte du CV, les plus demandés d'abord. Un mot doit revenir dans au moins
/// [pMinOffers] offres pour compter.
List<CvGapItem> skillGap(
  List<String> pOffers,
  String pCvText, {
  int pMinOffers = 2,
  int pLimit = 15,
}) {
  final vCv = cvPlain(pCvText);
  final vCount = <String, int>{};

  for (final vOffer in pOffers) {
    for (final vWord in offerKeywords(vOffer, pLimit: 30).toSet()) {
      vCount[vWord] = (vCount[vWord] ?? 0) + 1;
    }
  }
  final vItems = [
    for (final vEntry in vCount.entries)
      if (vEntry.value >= pMinOffers && !vCv.contains(vEntry.key))
        (word: vEntry.key, offers: vEntry.value),
  ]..sort((pA, pB) {
      final vByCount = pB.offers.compareTo(pA.offers);
      return vByCount != 0 ? vByCount : pA.word.compareTo(pB.word);
    });

  return vItems.take(pLimit).toList();
}
